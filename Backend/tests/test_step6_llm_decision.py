"""Tests for pipeline/step6_llm_decision.py — mocked chat_json."""

import json
import pytest
from unittest.mock import patch, MagicMock, call
from pipeline.step6_llm_decision import _build_prompt_for_dish, _call_one, decide_nutrition


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _dish(bbox_id, dish_name="Chicken Rice", ingredients=None, empty=False):
    return {
        "bbox_id": bbox_id,
        "dish_name": dish_name,
        "empty": empty,
        "ingredients": ingredients or [
            {"name": "chicken", "grams": 150, "cooking": "stir_fried"},
            {"name": "rice", "grams": 200, "cooking": "boiled"},
        ],
    }


def _s5(bbox_id, candidates_by_ingredient=None):
    return {bbox_id: candidates_by_ingredient or {}}


FAKE_DECISION = {
    "dishes": [{
        "bbox_id": 1,
        "dish_name": "Chicken Rice",
        "ingredients": [
            {
                "name": "chicken",
                "icon": "🍗",
                "grams": 150,
                "protein_g": 27.0,
                "fat_g": 3.6,
                "carb_g": 0.0,
                "source": "database",
                "confidence": "high",
                "fdc_id": 12345,
            }
        ],
    }]
}


# ---------------------------------------------------------------------------
# _build_prompt_for_dish (pure)
# ---------------------------------------------------------------------------

class TestBuildPromptForDish:
    def test_prompt_contains_bbox_id(self):
        dish = _dish(1)
        prompt = _build_prompt_for_dish(dish, {1: {}})
        assert '"bbox_id": 1' in prompt

    def test_prompt_contains_dish_name(self):
        dish = _dish(1, dish_name="Wonton Soup")
        prompt = _build_prompt_for_dish(dish, {1: {}})
        assert "Wonton Soup" in prompt

    def test_prompt_contains_ingredient_names(self):
        dish = _dish(1)
        prompt = _build_prompt_for_dish(dish, {1: {}})
        assert "chicken" in prompt
        assert "rice" in prompt

    def test_prompt_contains_db_candidates(self):
        candidates = {"chicken": [{"name": "chicken breast raw", "score": 0.95, "protein_g": 31, "fat_g": 3.6, "carb_g": 0, "fdc_id": 1}]}
        dish = _dish(1)
        prompt = _build_prompt_for_dish(dish, {1: candidates})
        assert "chicken breast raw" in prompt

    def test_prompt_empty_candidates_when_no_match(self):
        dish = _dish(1)
        prompt = _build_prompt_for_dish(dish, {1: {}})
        # db_candidates should be empty list
        assert '"db_candidates": []' in prompt

    def test_prompt_contains_task_instructions(self):
        dish = _dish(1)
        prompt = _build_prompt_for_dish(dish, {1: {}})
        assert "Task A" in prompt
        assert "Task B" in prompt
        assert "Task C" in prompt


# ---------------------------------------------------------------------------
# _call_one
# ---------------------------------------------------------------------------

class TestCallOne:
    def test_returns_first_dish_on_success(self):
        with patch("pipeline.step6_llm_decision.chat_json", return_value=FAKE_DECISION):
            result = _call_one(_dish(1), {1: {}})
        assert result["bbox_id"] == 1
        assert result["dish_name"] == "Chicken Rice"

    def test_returns_none_when_dishes_empty(self):
        with patch("pipeline.step6_llm_decision.chat_json", return_value={"dishes": []}):
            result = _call_one(_dish(1), {1: {}})
        assert result is None

    def test_retries_on_value_error(self):
        call_count = 0

        def flaky_chat_json(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise ValueError("LLM error")
            return FAKE_DECISION

        with patch("pipeline.step6_llm_decision.chat_json", side_effect=flaky_chat_json):
            result = _call_one(_dish(1), {1: {}})
        assert call_count == 3
        assert result is not None

    def test_raises_after_three_failures(self):
        with patch("pipeline.step6_llm_decision.chat_json", side_effect=ValueError("always fails")):
            with pytest.raises(ValueError, match="always fails"):
                _call_one(_dish(1), {1: {}})

    def test_exactly_three_attempts_on_failure(self):
        attempts = []

        def failing(*args, **kwargs):
            attempts.append(1)
            raise ValueError("fail")

        with patch("pipeline.step6_llm_decision.chat_json", side_effect=failing):
            with pytest.raises(ValueError):
                _call_one(_dish(1), {1: {}})
        assert len(attempts) == 3

    def test_succeeds_on_first_try(self):
        with patch("pipeline.step6_llm_decision.chat_json", return_value=FAKE_DECISION) as mock:
            _call_one(_dish(1), {1: {}})
        assert mock.call_count == 1


# ---------------------------------------------------------------------------
# decide_nutrition
# ---------------------------------------------------------------------------

class TestDecideNutrition:
    def test_empty_step4_returns_empty(self):
        assert decide_nutrition([], {}) == []

    def test_all_empty_dishes_returns_empty(self):
        result = decide_nutrition([_dish(1, empty=True)], {})
        assert result == []

    def test_filters_empty_dishes(self):
        dishes = [
            _dish(1, empty=True),
            _dish(2, empty=False),
        ]
        with patch("pipeline.step6_llm_decision.chat_json", return_value={"dishes": [{"bbox_id": 2, "dish_name": "Rice", "ingredients": []}]}):
            results = decide_nutrition(dishes, {2: {}})
        assert len(results) == 1

    def test_parallel_execution_returns_all_results(self):
        dishes = [_dish(i + 1) for i in range(3)]
        responses = [
            {"dishes": [{"bbox_id": i + 1, "dish_name": f"Dish {i + 1}", "ingredients": []}]}
            for i in range(3)
        ]
        call_idx = [0]

        def round_robin(*args, **kwargs):
            r = responses[call_idx[0] % 3]
            call_idx[0] += 1
            return r

        with patch("pipeline.step6_llm_decision.chat_json", side_effect=round_robin):
            results = decide_nutrition(dishes, {})
        assert len(results) == 3

    def test_none_results_filtered_out(self):
        dishes = [_dish(1)]
        with patch("pipeline.step6_llm_decision.chat_json", return_value={"dishes": []}):
            result = decide_nutrition(dishes, {})
        assert result == []

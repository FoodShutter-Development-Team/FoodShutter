"""Tests for pipeline/step8_advice.py — pure BMR logic + mocked LLM call."""

import pytest
from unittest.mock import patch, call
from pipeline.step8_advice import _estimate_daily_targets, generate_advice


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _profile(**kw):
    base = {
        "weight_kg": 70,
        "height_cm": 175,
        "age": 30,
        "gender": "male",
        "activity_level": "moderate",
        "health_goal": "balanced_diet",
    }
    base.update(kw)
    return base


_FAKE_ADVICE = {
    "summary": "Good meal today.",
    "nutrition_status": "balanced",
    "pros": ["High protein"],
    "cons": ["Low fiber"],
    "suggestions": ["Add vegetables", "Drink more water", "Reduce salt"],
    "next_meal_recommendation": {
        "recommended_dish": {
            "dish_name": "Garden Salad",
            "icon": "🥗",
            "weight": 200,
            "proteinPercent": 15,
            "fatPercent": 20,
            "carbohydratePercent": 65,
        },
        "reason": "Provides fiber to balance today's intake.",
        "nutrients_focus": ["Dietary fiber", "Vitamin C"],
    },
}


# ---------------------------------------------------------------------------
# _estimate_daily_targets — Mifflin-St Jeor
# ---------------------------------------------------------------------------

class TestEstimateDailyTargets:
    def test_male_bmr_sedentary(self):
        p = _profile(gender="male", activity_level="sedentary", health_goal="balanced_diet")
        bmr = 10 * 70 + 6.25 * 175 - 5 * 30 + 5
        tdee = round(bmr * 1.2)
        assert _estimate_daily_targets(p)["calories"] == tdee

    def test_female_bmr_sedentary(self):
        p = _profile(gender="female", activity_level="sedentary", health_goal="balanced_diet")
        bmr = 10 * 70 + 6.25 * 175 - 5 * 30 - 161
        tdee = round(bmr * 1.2)
        assert _estimate_daily_targets(p)["calories"] == tdee

    def test_other_gender_bmr_sedentary(self):
        p = _profile(gender="other", activity_level="sedentary", health_goal="balanced_diet")
        bmr = 10 * 70 + 6.25 * 175 - 5 * 30 - 78
        tdee = round(bmr * 1.2)
        assert _estimate_daily_targets(p)["calories"] == tdee

    def test_unrecognized_gender_uses_other_formula(self):
        p_other = _profile(gender="other", activity_level="sedentary")
        p_unknown = _profile(gender="nonbinary", activity_level="sedentary")
        assert _estimate_daily_targets(p_other)["calories"] == _estimate_daily_targets(p_unknown)["calories"]

    def test_activity_multipliers_increase_calories(self):
        levels = ["sedentary", "light", "moderate", "active", "very_active"]
        cals = [_estimate_daily_targets(_profile(activity_level=lvl))["calories"] for lvl in levels]
        assert cals == sorted(cals)

    def test_weight_loss_goal_subtracts_500(self):
        base = _estimate_daily_targets(_profile(health_goal="balanced_diet"))["calories"]
        loss = _estimate_daily_targets(_profile(health_goal="weight_loss"))["calories"]
        assert loss == base - 500

    def test_weight_gain_goal_adds_300(self):
        base = _estimate_daily_targets(_profile(health_goal="balanced_diet"))["calories"]
        gain = _estimate_daily_targets(_profile(health_goal="muscle_gain"))["calories"]
        assert gain == base + 300

    def test_partial_goal_match_loss(self):
        # "fat_loss" contains "loss"
        loss1 = _estimate_daily_targets(_profile(health_goal="weight_loss"))["calories"]
        loss2 = _estimate_daily_targets(_profile(health_goal="fat_loss"))["calories"]
        assert loss1 == loss2

    def test_partial_goal_match_gain(self):
        gain1 = _estimate_daily_targets(_profile(health_goal="muscle_gain"))["calories"]
        gain2 = _estimate_daily_targets(_profile(health_goal="weight_gain"))["calories"]
        assert gain1 == gain2

    def test_macro_proportions(self):
        result = _estimate_daily_targets(_profile())
        cals = result["calories"]
        assert result["protein_g"] == round(cals * 0.30 / 4)
        assert result["fat_g"] == round(cals * 0.25 / 9)
        assert result["carb_g"] == round(cals * 0.45 / 4)

    def test_default_values_for_empty_profile(self):
        # weight=65, height=170, age=30, gender='other', activity='moderate', goal='balanced_diet'
        result = _estimate_daily_targets({})
        bmr = 10 * 65 + 6.25 * 170 - 5 * 30 - 78
        tdee = round(bmr * 1.55)
        assert result["calories"] == tdee

    def test_unknown_activity_level_defaults_to_moderate(self):
        p_mod = _profile(activity_level="moderate")
        p_unk = _profile(activity_level="extreme_sports")
        assert _estimate_daily_targets(p_mod)["calories"] == _estimate_daily_targets(p_unk)["calories"]


# ---------------------------------------------------------------------------
# generate_advice — mocked LLM
# ---------------------------------------------------------------------------

def _meal_result(dishes=None):
    return {"dishes": dishes or [], "image_totals": {"total_protein_g": 30, "total_fat_g": 10, "total_carb_g": 60, "total_calories": 450}}


def test_generate_advice_returns_llm_output():
    with patch("pipeline.step8_advice.chat_json", return_value=_FAKE_ADVICE):
        result = generate_advice(_profile(), {}, {}, _meal_result(), "lunch")
    assert result == _FAKE_ADVICE


def test_generate_advice_calls_chat_json_once():
    with patch("pipeline.step8_advice.chat_json", return_value=_FAKE_ADVICE) as mock:
        generate_advice(_profile(), {}, {}, _meal_result(), "dinner")
    mock.assert_called_once()


def test_generate_advice_uses_profile_nutrition_targets_not_estimated():
    custom_targets = {"calories": 1500, "protein_g": 100, "fat_g": 40, "carb_g": 180}
    p = {"nutrition_targets": custom_targets}
    captured = {}

    def fake_chat_json(prompt, schema, schema_name="response", **kw):
        captured["prompt"] = prompt
        return _FAKE_ADVICE

    with patch("pipeline.step8_advice.chat_json", side_effect=fake_chat_json):
        generate_advice(p, {}, {}, _meal_result(), "lunch")

    assert "1500" in captured["prompt"]  # custom calorie target appears in prompt


def test_generate_advice_estimates_targets_when_missing_from_profile():
    p = _profile()  # no nutrition_targets key
    captured = {}

    def fake_chat_json(prompt, schema, schema_name="response", **kw):
        captured["prompt"] = prompt
        return _FAKE_ADVICE

    with patch("pipeline.step8_advice.chat_json", side_effect=fake_chat_json):
        generate_advice(p, {}, {}, _meal_result(), "breakfast")

    # The estimated targets should appear in the prompt
    assert "calories" in captured["prompt"]


def test_generate_advice_computes_remaining_quota():
    today = {"total_calories": 600, "total_protein_g": 40, "total_fat_g": 20, "total_carb_g": 70}
    custom_targets = {"calories": 2000, "protein_g": 150, "fat_g": 55, "carb_g": 225}
    captured = {}

    def fake_chat_json(prompt, schema, schema_name="response", **kw):
        captured["prompt"] = prompt
        return _FAKE_ADVICE

    with patch("pipeline.step8_advice.chat_json", side_effect=fake_chat_json):
        generate_advice({"nutrition_targets": custom_targets}, today, {}, _meal_result(), "lunch")

    # remaining calories = 2000 - 600 = 1400
    assert "1400" in captured["prompt"]


def test_generate_advice_filters_empty_dishes():
    dishes = [
        {"empty": True, "bbox_id": 1},
        {"empty": False, "bbox_id": 2, "dish_name": "Rice", "total_calories": 300,
         "total_protein_g": 5, "total_fat_g": 1, "total_carb_g": 65},
    ]
    captured = {}

    def fake_chat_json(prompt, schema, schema_name="response", **kw):
        captured["prompt"] = prompt
        return _FAKE_ADVICE

    with patch("pipeline.step8_advice.chat_json", side_effect=fake_chat_json):
        generate_advice(_profile(), {}, {}, {"dishes": dishes, "image_totals": {}}, "lunch")

    # Only the non-empty dish should appear in the prompt
    assert "Rice" in captured["prompt"]


def test_generate_advice_passes_meal_type():
    captured = {}

    def fake_chat_json(prompt, schema, schema_name="response", **kw):
        captured["prompt"] = prompt
        return _FAKE_ADVICE

    with patch("pipeline.step8_advice.chat_json", side_effect=fake_chat_json):
        generate_advice(_profile(), {}, {}, _meal_result(), "breakfast")

    assert "breakfast" in captured["prompt"]

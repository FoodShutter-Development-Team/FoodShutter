"""Tests for pipeline/step4_vlm_analysis.py — mocked VLM, PIL, and filesystem."""

import pytest
from unittest.mock import patch, MagicMock, call
from pipeline.step4_vlm_analysis import _scene_list, _call_one, analyze_dishes


# ---------------------------------------------------------------------------
# _scene_list (pure function)
# ---------------------------------------------------------------------------

class TestSceneList:
    def test_single_detection(self):
        dets = [{"label": "Rice", "container": "bowl", "portion": "medium"}]
        result = _scene_list(dets)
        assert "1." in result
        assert "Rice" in result
        assert "bowl" in result
        assert "medium" in result

    def test_multiple_detections_numbered(self):
        dets = [
            {"label": "Rice", "container": "bowl", "portion": "medium"},
            {"label": "Chicken", "container": "plate", "portion": "large"},
        ]
        result = _scene_list(dets)
        assert "1." in result
        assert "2." in result
        assert "Rice" in result
        assert "Chicken" in result

    def test_empty_list(self):
        assert _scene_list([]) == ""

    def test_missing_keys_defaults(self):
        dets = [{}]
        result = _scene_list(dets)
        assert "unknown" in result
        assert "?" in result


# ---------------------------------------------------------------------------
# _call_one — per-dish VLM call
# ---------------------------------------------------------------------------

FAKE_DET = {
    "bbox": [0.1, 0.1, 0.5, 0.5],
    "label": "Kung Pao Chicken",
    "container": "plate",
    "portion": "medium",
}

FAKE_IMG_BYTES = b"\xff\xd8\xff" + b"\x00" * 20

VALID_PARSED = {
    "empty": False,
    "dish_name": "Kung Pao Chicken",
    "icon": "🍗",
    "container": "plate",
    "portion_size": "medium",
    "estimated_total_grams": 300,
    "confidence": "high",
    "ingredients": [
        {"name": "chicken", "grams": 150, "cooking": "stir_fried"},
        {"name": "peanuts", "grams": 30, "cooking": "fried"},
    ],
}


class TestCallOne:
    def _run(self, parsed, save_dir=None):
        with patch("pipeline.step4_vlm_analysis._annotate_bbox", return_value=FAKE_IMG_BYTES), \
             patch("pipeline.step4_vlm_analysis.vision_json", return_value=parsed):
            return _call_one(0, FAKE_DET, "fake.jpg", "1. Rice (bowl, medium)", 2, save_dir)

    def test_returns_index_and_result(self):
        idx, result = self._run(VALID_PARSED)
        assert idx == 0

    def test_bbox_id_is_one_indexed(self):
        _, result = self._run(VALID_PARSED)
        assert result["bbox_id"] == 1  # idx=0 → bbox_id=1

    def test_bbox_copied_to_result(self):
        _, result = self._run(VALID_PARSED)
        assert result["bbox"] == FAKE_DET["bbox"]

    def test_empty_defaults_to_false_when_not_set(self):
        parsed = {**VALID_PARSED}
        parsed.pop("empty", None)
        _, result = self._run(parsed)
        assert result.get("empty") is False

    def test_retry_when_no_ingredients_and_not_empty(self):
        no_ing_parsed = {**VALID_PARSED, "ingredients": [], "empty": False}
        retry_result = {"ingredients": [{"name": "chicken", "grams": 100, "cooking": "other"}]}
        with patch("pipeline.step4_vlm_analysis._annotate_bbox", return_value=FAKE_IMG_BYTES), \
             patch("pipeline.step4_vlm_analysis.vision_json", return_value=no_ing_parsed), \
             patch("pipeline.step4_vlm_analysis.chat_json", return_value=retry_result) as mock_chat:
            _, result = _call_one(0, FAKE_DET, "fake.jpg", "scene", 1, None)
        mock_chat.assert_called_once()
        assert result["confidence"] == "low"
        assert result["ingredient_source"] == "name_inferred"
        assert len(result["ingredients"]) == 1

    def test_no_retry_when_empty_true(self):
        empty_parsed = {**VALID_PARSED, "empty": True, "ingredients": []}
        with patch("pipeline.step4_vlm_analysis._annotate_bbox", return_value=FAKE_IMG_BYTES), \
             patch("pipeline.step4_vlm_analysis.vision_json", return_value=empty_parsed), \
             patch("pipeline.step4_vlm_analysis.chat_json") as mock_chat:
            _call_one(0, FAKE_DET, "fake.jpg", "scene", 1, None)
        mock_chat.assert_not_called()

    def test_no_retry_when_ingredients_present(self):
        with patch("pipeline.step4_vlm_analysis._annotate_bbox", return_value=FAKE_IMG_BYTES), \
             patch("pipeline.step4_vlm_analysis.vision_json", return_value=VALID_PARSED), \
             patch("pipeline.step4_vlm_analysis.chat_json") as mock_chat:
            _call_one(0, FAKE_DET, "fake.jpg", "scene", 1, None)
        mock_chat.assert_not_called()

    def test_save_dir_writes_annotated_image(self, tmp_path):
        with patch("pipeline.step4_vlm_analysis._annotate_bbox", return_value=FAKE_IMG_BYTES), \
             patch("pipeline.step4_vlm_analysis.vision_json", return_value=VALID_PARSED):
            _call_one(0, FAKE_DET, "fake.jpg", "scene", 1, str(tmp_path))
        saved = list(tmp_path.glob("*.jpg"))
        assert len(saved) == 1
        assert saved[0].name == "dish_01_annotated.jpg"

    def test_no_save_when_save_dir_none(self, tmp_path):
        with patch("pipeline.step4_vlm_analysis._annotate_bbox", return_value=FAKE_IMG_BYTES), \
             patch("pipeline.step4_vlm_analysis.vision_json", return_value=VALID_PARSED):
            _call_one(0, FAKE_DET, "fake.jpg", "scene", 1, None)
        # No files written
        assert list(tmp_path.glob("*")) == []


# ---------------------------------------------------------------------------
# analyze_dishes
# ---------------------------------------------------------------------------

class TestAnalyzeDishes:
    def _make_det(self, i):
        return {
            "bbox": [0.1 * i, 0.1 * i, 0.5 * i, 0.5 * i],
            "label": f"Dish {i}",
            "container": "bowl",
            "portion": "medium",
        }

    def _fake_call_one(self, idx, det, image_path, scene_ctx, total, save_dir):
        return idx, {
            "bbox_id": idx + 1,
            "bbox": det["bbox"],
            "dish_name": det["label"],
            "empty": False,
        }

    def test_empty_detections_returns_empty_list(self):
        assert analyze_dishes("fake.jpg", []) == []

    def test_parallel_execution_preserves_order(self):
        dets = [self._make_det(i + 1) for i in range(3)]
        with patch("pipeline.step4_vlm_analysis._call_one", side_effect=self._fake_call_one):
            results = analyze_dishes("fake.jpg", dets)
        assert len(results) == 3
        # Results should be in original detection order (idx 0, 1, 2)
        for i, r in enumerate(results):
            assert r["bbox_id"] == i + 1

    def test_creates_save_dir_when_provided(self, tmp_path):
        save_dir = str(tmp_path / "output")
        dets = [self._make_det(1)]
        with patch("pipeline.step4_vlm_analysis._call_one", side_effect=self._fake_call_one):
            analyze_dishes("fake.jpg", dets, save_dir=save_dir)
        import os
        assert os.path.isdir(save_dir)

    def test_single_dish_uses_one_worker(self):
        dets = [self._make_det(1)]
        with patch("pipeline.step4_vlm_analysis._call_one", side_effect=self._fake_call_one) as mock_call:
            analyze_dishes("fake.jpg", dets, max_workers=4)
        mock_call.assert_called_once()

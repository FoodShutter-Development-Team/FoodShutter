"""Tests for pipeline/step1_detection.py — mocked VLM and file I/O."""

import pytest
from unittest.mock import patch, MagicMock
from pipeline.step1_detection import detect_dishes


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _vlm_response(items):
    """Build a vision_json return value with the given list of raw items."""
    return {"detections": items}


def _item(label, box_2d, container="bowl", portion="medium"):
    return {"label": label, "box_2d": box_2d, "container": container, "portion": portion}


FAKE_IMAGE_BYTES = b"\xff\xd8\xff" + b"\x00" * 100  # fake JPEG


# ---------------------------------------------------------------------------
# Coordinate conversion: Gemini [y_min, x_min, y_max, x_max] on 0-1000
# ---------------------------------------------------------------------------

class TestCoordinateConversion:
    def _detect(self, box_2d):
        response = _vlm_response([_item("food", box_2d)])
        with patch("pipeline.step1_detection.vision_json", return_value=response), \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES):
            return detect_dishes("fake.jpg")

    def test_basic_conversion(self):
        # box_2d = [y_min=100, x_min=200, y_max=300, x_max=400]
        # → y0=0.1, x0=0.2, y1=0.3, x1=0.4
        # bbox = [x0, y0, x1, y1] = [0.2, 0.1, 0.4, 0.3]
        dets = self._detect([100, 200, 300, 400])
        assert len(dets) == 1
        assert dets[0]["bbox"] == pytest.approx([0.2, 0.1, 0.4, 0.3])

    def test_zero_corner(self):
        dets = self._detect([0, 0, 500, 500])
        assert dets[0]["bbox"] == pytest.approx([0.0, 0.0, 0.5, 0.5])

    def test_full_image_box(self):
        dets = self._detect([0, 0, 1000, 1000])
        assert dets[0]["bbox"] == pytest.approx([0.0, 0.0, 1.0, 1.0])

    def test_division_by_1000(self):
        dets = self._detect([250, 750, 500, 1000])
        # y0=0.25, x0=0.75, y1=0.5, x1=1.0
        assert dets[0]["bbox"] == pytest.approx([0.75, 0.25, 1.0, 0.5])


# ---------------------------------------------------------------------------
# Field mapping
# ---------------------------------------------------------------------------

class TestFieldMapping:
    def _detect(self, item):
        response = _vlm_response([item])
        with patch("pipeline.step1_detection.vision_json", return_value=response), \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES):
            return detect_dishes("fake.jpg")

    def test_label_preserved(self):
        det = self._detect(_item("Kung Pao Chicken", [100, 100, 400, 400]))
        assert det[0]["label"] == "Kung Pao Chicken"

    def test_container_preserved(self):
        det = self._detect(_item("food", [100, 100, 400, 400], container="plate"))
        assert det[0]["container"] == "plate"

    def test_portion_preserved(self):
        det = self._detect(_item("food", [100, 100, 400, 400], portion="large"))
        assert det[0]["portion"] == "large"

    def test_confidence_hardcoded_to_090(self):
        det = self._detect(_item("food", [100, 100, 400, 400]))
        assert det[0]["confidence"] == pytest.approx(0.90)

    def test_missing_label_defaults_to_food(self):
        item = {"box_2d": [100, 100, 400, 400], "container": "bowl", "portion": "medium"}
        response = _vlm_response([item])
        with patch("pipeline.step1_detection.vision_json", return_value=response), \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES):
            dets = detect_dishes("fake.jpg")
        assert dets[0]["label"] == "food"

    def test_missing_container_defaults_to_other(self):
        item = {"label": "food", "box_2d": [100, 100, 400, 400], "portion": "medium"}
        response = _vlm_response([item])
        with patch("pipeline.step1_detection.vision_json", return_value=response), \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES):
            dets = detect_dishes("fake.jpg")
        assert dets[0]["container"] == "other"


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

class TestEdgeCases:
    def test_empty_detections_returns_empty_list(self):
        with patch("pipeline.step1_detection.vision_json", return_value={"detections": []}), \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES):
            result = detect_dishes("fake.jpg")
        assert result == []

    def test_malformed_box_2d_skipped(self):
        # box_2d with wrong number of elements → skip
        item = {"label": "food", "box_2d": [100, 200], "container": "bowl", "portion": "medium"}
        with patch("pipeline.step1_detection.vision_json", return_value=_vlm_response([item])), \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES):
            result = detect_dishes("fake.jpg")
        assert result == []

    def test_multiple_detections(self):
        items = [
            _item("Rice", [0, 0, 300, 300]),
            _item("Chicken", [400, 400, 700, 700]),
        ]
        with patch("pipeline.step1_detection.vision_json", return_value=_vlm_response(items)), \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES):
            result = detect_dishes("fake.jpg")
        assert len(result) == 2

    def test_reads_file_bytes(self):
        with patch("pipeline.step1_detection.vision_json", return_value={"detections": []}) as mock_vlm, \
             patch("pathlib.Path.read_bytes", return_value=FAKE_IMAGE_BYTES) as mock_read:
            detect_dishes("/some/path/image.jpg")
        mock_read.assert_called_once()
        # vision_json receives the bytes
        assert mock_vlm.call_args[0][0] == FAKE_IMAGE_BYTES

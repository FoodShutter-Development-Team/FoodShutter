"""Tests for pipeline/step2_postprocess.py — pure logic, no mocking needed."""

import pytest
from pipeline.step2_postprocess import (
    _area,
    _clamp_bbox,
    _containment,
    _containment_suppression,
    _iou,
    _nms,
    postprocess,
)


# ---------------------------------------------------------------------------
# _iou
# ---------------------------------------------------------------------------

class TestIou:
    def test_no_overlap(self):
        assert _iou([0.0, 0.0, 0.4, 0.4], [0.6, 0.6, 1.0, 1.0]) == 0.0

    def test_perfect_overlap(self):
        b = [0.1, 0.1, 0.9, 0.9]
        assert _iou(b, b) == pytest.approx(1.0)

    def test_touching_edges_no_overlap(self):
        assert _iou([0.0, 0.0, 0.5, 0.5], [0.5, 0.0, 1.0, 0.5]) == 0.0

    def test_partial_overlap(self):
        a = [0.0, 0.0, 0.6, 0.6]
        b = [0.4, 0.4, 1.0, 1.0]
        inter = 0.2 * 0.2
        area_a = 0.6 * 0.6
        area_b = 0.6 * 0.6
        expected = inter / (area_a + area_b - inter)
        assert _iou(a, b) == pytest.approx(expected)

    def test_one_inside_other(self):
        outer = [0.0, 0.0, 1.0, 1.0]
        inner = [0.2, 0.2, 0.8, 0.8]
        inter = 0.6 * 0.6
        union = 1.0 + 0.36 - inter
        assert _iou(outer, inner) == pytest.approx(inter / union)

    def test_zero_area_box(self):
        assert _iou([0.5, 0.5, 0.5, 0.5], [0.0, 0.0, 1.0, 1.0]) == 0.0

    def test_symmetric(self):
        a = [0.1, 0.1, 0.6, 0.7]
        b = [0.3, 0.2, 0.8, 0.9]
        assert _iou(a, b) == pytest.approx(_iou(b, a))


# ---------------------------------------------------------------------------
# _containment
# ---------------------------------------------------------------------------

class TestContainment:
    def test_fully_inside(self):
        small = [0.2, 0.2, 0.4, 0.4]
        large = [0.0, 0.0, 1.0, 1.0]
        assert _containment(small, large) == pytest.approx(1.0)

    def test_no_overlap(self):
        assert _containment([0.0, 0.0, 0.2, 0.2], [0.5, 0.5, 1.0, 1.0]) == 0.0

    def test_half_inside(self):
        # small: x=[0.0,0.4], y=[0.0,1.0], area=0.4
        # large: x=[0.2,0.8], y=[0.0,1.0]
        # intersection x: [0.2,0.4]=0.2, y: [0.0,1.0]=1.0, inter=0.2
        small = [0.0, 0.0, 0.4, 1.0]
        large = [0.2, 0.0, 0.8, 1.0]
        assert _containment(small, large) == pytest.approx(0.5)

    def test_zero_area_small(self):
        assert _containment([0.3, 0.3, 0.3, 0.3], [0.0, 0.0, 1.0, 1.0]) == 0.0

    def test_not_symmetric(self):
        small = [0.1, 0.1, 0.3, 0.3]
        large = [0.0, 0.0, 1.0, 1.0]
        assert _containment(small, large) == pytest.approx(1.0)
        assert _containment(large, small) < 0.1  # large is mostly outside small


# ---------------------------------------------------------------------------
# _area
# ---------------------------------------------------------------------------

class TestArea:
    def test_unit_square(self):
        assert _area([0.0, 0.0, 1.0, 1.0]) == pytest.approx(1.0)

    def test_quarter_square(self):
        assert _area([0.0, 0.0, 0.5, 0.5]) == pytest.approx(0.25)

    def test_rectangle(self):
        assert _area([0.0, 0.0, 0.4, 0.2]) == pytest.approx(0.08)

    def test_zero_size(self):
        assert _area([0.5, 0.5, 0.5, 0.5]) == 0.0


# ---------------------------------------------------------------------------
# _nms
# ---------------------------------------------------------------------------

class TestNms:
    def test_empty(self):
        assert _nms([]) == []

    def test_single(self):
        d = [{"bbox": [0.0, 0.0, 0.5, 0.5], "confidence": 0.9}]
        assert _nms(d) == d

    def test_no_overlap_keeps_all(self):
        a = {"bbox": [0.0, 0.0, 0.3, 0.3], "confidence": 0.9}
        b = {"bbox": [0.7, 0.7, 1.0, 1.0], "confidence": 0.8}
        assert len(_nms([a, b])) == 2

    def test_high_overlap_keeps_highest_confidence(self):
        high = {"bbox": [0.0, 0.0, 0.5, 0.5], "confidence": 0.95}
        low = {"bbox": [0.02, 0.02, 0.48, 0.48], "confidence": 0.6}
        result = _nms([high, low], iou_threshold=0.5)
        assert len(result) == 1
        assert result[0]["confidence"] == 0.95

    def test_lower_conf_wins_if_processed_first_but_loses_to_higher(self):
        # When passed in low-first order, NMS should still keep the high-conf one
        high = {"bbox": [0.0, 0.0, 0.5, 0.5], "confidence": 0.9}
        low = {"bbox": [0.02, 0.02, 0.48, 0.48], "confidence": 0.5}
        result = _nms([low, high], iou_threshold=0.5)
        assert len(result) == 1
        assert result[0]["confidence"] == 0.9

    def test_threshold_boundary(self):
        # IoU exactly at threshold should be suppressed (< threshold keeps, >= suppresses)
        a = {"bbox": [0.0, 0.0, 0.6, 0.6], "confidence": 0.9}
        b = {"bbox": [0.0, 0.0, 0.6, 0.6], "confidence": 0.8}  # identical = IoU 1.0
        result = _nms([a, b], iou_threshold=0.5)
        assert len(result) == 1

    def test_no_confidence_key_defaults_to_1(self):
        a = {"bbox": [0.0, 0.0, 0.5, 0.5]}
        b = {"bbox": [0.6, 0.6, 1.0, 1.0]}
        assert len(_nms([a, b])) == 2

    def test_three_boxes_chain_suppression(self):
        high = {"bbox": [0.0, 0.0, 0.5, 0.5], "confidence": 0.9}
        mid = {"bbox": [0.05, 0.05, 0.45, 0.45], "confidence": 0.7}
        sep = {"bbox": [0.7, 0.7, 1.0, 1.0], "confidence": 0.8}
        result = _nms([high, mid, sep], iou_threshold=0.5)
        assert len(result) == 2


# ---------------------------------------------------------------------------
# _containment_suppression
# ---------------------------------------------------------------------------

class TestContainmentSuppression:
    def test_empty(self):
        assert _containment_suppression([]) == []

    def test_single(self):
        d = [{"bbox": [0.1, 0.1, 0.9, 0.9]}]
        assert _containment_suppression(d) == d

    def test_small_fully_inside_large_removed(self):
        large = {"bbox": [0.0, 0.0, 0.9, 0.9]}   # area 0.81
        small = {"bbox": [0.1, 0.1, 0.5, 0.5]}   # area 0.16, fully inside large
        result = _containment_suppression([large, small], containment_threshold=0.72)
        assert large in result
        assert small not in result

    def test_non_overlapping_both_kept(self):
        a = {"bbox": [0.0, 0.0, 0.3, 0.3]}
        b = {"bbox": [0.7, 0.7, 1.0, 1.0]}
        result = _containment_suppression([a, b])
        assert len(result) == 2

    def test_large_not_removed_by_small(self):
        large = {"bbox": [0.0, 0.0, 0.9, 0.9]}
        small = {"bbox": [0.1, 0.1, 0.3, 0.3]}
        result = _containment_suppression([large, small])
        assert large in result

    def test_threshold_respected_low_containment_kept(self):
        # small: [0.5, 0.0, 0.7, 0.2], large: [0.6, 0.0, 1.0, 1.0]
        # intersection: x=[0.6,0.7]=0.1, y=[0.0,0.2]=0.2 → inter=0.02
        # area_small = 0.2*0.2 = 0.04, containment = 0.02/0.04 = 0.5 < 0.72 → kept
        large = {"bbox": [0.6, 0.0, 1.0, 1.0]}
        small = {"bbox": [0.5, 0.0, 0.7, 0.2]}
        result = _containment_suppression([large, small], containment_threshold=0.72)
        assert len(result) == 2

    def test_threshold_respected_high_containment_removed(self):
        # small fully inside large → containment=1.0 > 0.72 → removed
        large = {"bbox": [0.0, 0.0, 1.0, 1.0]}
        small = {"bbox": [0.1, 0.1, 0.4, 0.4]}
        result = _containment_suppression([large, small], containment_threshold=0.72)
        assert len(result) == 1
        assert result[0] is large


# ---------------------------------------------------------------------------
# _clamp_bbox
# ---------------------------------------------------------------------------

class TestClampBbox:
    def test_no_clamp_needed(self):
        bbox = [0.1, 0.2, 0.8, 0.9]
        assert _clamp_bbox(bbox) == bbox

    def test_clamp_below_zero(self):
        result = _clamp_bbox([-0.5, -0.1, 0.5, 0.5])
        assert result[0] == 0.0
        assert result[1] == 0.0

    def test_clamp_above_one(self):
        result = _clamp_bbox([0.1, 0.1, 1.5, 1.3])
        assert result[2] == 1.0
        assert result[3] == 1.0

    def test_swap_inverted_x(self):
        result = _clamp_bbox([0.8, 0.1, 0.2, 0.9])
        assert result[0] <= result[2]

    def test_swap_inverted_y(self):
        result = _clamp_bbox([0.1, 0.9, 0.8, 0.2])
        assert result[1] <= result[3]

    def test_fully_out_of_range(self):
        assert _clamp_bbox([-2.0, -2.0, 3.0, 3.0]) == [0.0, 0.0, 1.0, 1.0]

    def test_all_coordinates_in_bounds(self):
        result = _clamp_bbox([0.0, 0.0, 1.0, 1.0])
        assert result == [0.0, 0.0, 1.0, 1.0]


# ---------------------------------------------------------------------------
# postprocess (integration)
# ---------------------------------------------------------------------------

def _det(bbox, conf=0.9, label="food"):
    return {"bbox": bbox, "confidence": conf, "label": label}


class TestPostprocess:
    def test_empty_input(self):
        result = postprocess([])
        assert result["detections"] == []
        assert result["filtered_out"] == []
        assert result["counts"] == {
            "raw": 0, "after_nms": 0, "after_containment": 0, "after_area_filter": 0
        }

    def test_single_valid_detection(self):
        result = postprocess([_det([0.1, 0.1, 0.6, 0.6])])
        assert len(result["detections"]) == 1
        assert result["filtered_out"] == []
        assert result["counts"]["raw"] == 1

    def test_too_small_filtered_out(self):
        # area = 0.05 * 0.05 = 0.0025 < min_area_ratio 0.02
        result = postprocess([_det([0.1, 0.1, 0.15, 0.15])])
        assert len(result["detections"]) == 0
        assert len(result["filtered_out"]) == 1
        assert result["filtered_out"][0]["filter_reason"] == "too_small"

    def test_too_large_filtered_out(self):
        # area = 0.9 * 0.9 = 0.81 > max_area_ratio 0.65
        result = postprocess([_det([0.05, 0.05, 0.95, 0.95])])
        assert len(result["detections"]) == 0
        assert len(result["filtered_out"]) == 1
        assert result["filtered_out"][0]["filter_reason"] == "too_large"

    def test_edge_warning_left_edge(self):
        result = postprocess([_det([0.01, 0.1, 0.5, 0.6])])
        assert result["detections"][0].get("edge_warning") is True

    def test_edge_warning_right_edge(self):
        result = postprocess([_det([0.1, 0.1, 0.99, 0.6])])
        assert result["detections"][0].get("edge_warning") is True

    def test_edge_warning_top_edge(self):
        result = postprocess([_det([0.1, 0.01, 0.6, 0.5])])
        assert result["detections"][0].get("edge_warning") is True

    def test_edge_warning_bottom_edge(self):
        result = postprocess([_det([0.1, 0.1, 0.6, 0.99])])
        assert result["detections"][0].get("edge_warning") is True

    def test_no_edge_warning_interior_box(self):
        result = postprocess([_det([0.1, 0.1, 0.6, 0.6])])
        assert "edge_warning" not in result["detections"][0]

    def test_area_in_output(self):
        result = postprocess([_det([0.1, 0.1, 0.5, 0.6])])
        assert "area" in result["detections"][0]

    def test_nms_removes_duplicate(self):
        a = _det([0.1, 0.1, 0.6, 0.6], conf=0.9)
        b = _det([0.12, 0.12, 0.58, 0.58], conf=0.7)
        result = postprocess([a, b])
        assert result["counts"]["raw"] == 2
        assert result["counts"]["after_nms"] == 1

    def test_counts_track_pipeline_stages(self):
        # Two non-overlapping boxes: one too large (fails area filter), one valid.
        # y ranges don't overlap so NMS/containment keep both, then area filter removes one.
        too_large = _det([0.05, 0.05, 0.95, 0.78], conf=0.9)  # area=0.90*0.73=0.657 > 0.65
        valid = _det([0.1, 0.80, 0.6, 0.97], conf=0.8)         # area=0.50*0.17=0.085, valid; y ranges don't overlap
        result = postprocess([too_large, valid])
        assert result["counts"]["raw"] == 2
        assert result["counts"]["after_nms"] == 2
        assert result["counts"]["after_area_filter"] == 1

    def test_coordinates_clamped_before_processing(self):
        result = postprocess([_det([-0.1, -0.1, 0.5, 0.5])])
        bbox = result["detections"][0]["bbox"]
        assert bbox[0] >= 0.0 and bbox[1] >= 0.0

    def test_custom_thresholds(self):
        # Use tiny min_area so a small box passes
        small = _det([0.1, 0.1, 0.15, 0.15])  # area=0.0025
        result = postprocess([small], min_area_ratio=0.001)
        assert len(result["detections"]) == 1

    def test_containment_suppression_in_pipeline(self):
        # large box at outer edge of image (valid area), small box inside it
        large = _det([0.05, 0.05, 0.75, 0.75], conf=0.9)  # area=0.49, valid
        small = _det([0.1, 0.1, 0.4, 0.4], conf=0.7)       # area=0.09, fully inside large
        result = postprocess([large, small])
        # Small should be suppressed by containment
        assert result["counts"]["after_containment"] == 1

"""Tests for pipeline/step3_vlm_verify.py — pure logic, no mocking needed."""

import pytest
from pipeline.step3_vlm_verify import verify_and_correct


def _dets(n):
    return [{"bbox": [0.0, 0.0, 0.5, 0.5], "label": f"dish_{i}"} for i in range(n)]


# ---------------------------------------------------------------------------
# Edge cases: empty input
# ---------------------------------------------------------------------------

def test_empty_step1_returns_consistent_no_fallback():
    result = verify_and_correct([], [])
    assert result["raw_count"] == 0
    assert result["filtered_count"] == 0
    assert result["consistent"] is True
    assert result["used_fallback"] is False
    assert result["detections"] == []


def test_empty_step1_no_retain_ratio_key():
    result = verify_and_correct([], [])
    # retain_ratio is not included when raw_count is 0
    assert "retain_ratio" not in result


# ---------------------------------------------------------------------------
# Full retention
# ---------------------------------------------------------------------------

def test_all_retained_no_fallback():
    s1 = _dets(5)
    s2 = _dets(5)
    result = verify_and_correct(s1, s2)
    assert result["retain_ratio"] == pytest.approx(1.0)
    assert result["consistent"] is True
    assert result["used_fallback"] is False
    assert result["detections"] is s2


def test_single_detection_retained():
    s1 = _dets(1)
    s2 = _dets(1)
    result = verify_and_correct(s1, s2)
    assert result["consistent"] is True
    assert result["used_fallback"] is False


# ---------------------------------------------------------------------------
# Fallback triggered
# ---------------------------------------------------------------------------

def test_zero_retained_triggers_fallback():
    s1 = _dets(10)
    result = verify_and_correct(s1, [])
    assert result["retain_ratio"] == 0.0
    assert result["consistent"] is False
    assert result["used_fallback"] is True
    assert result["detections"] is s1


def test_below_threshold_triggers_fallback():
    # 1/11 ≈ 0.0909 < 0.10 → inconsistent
    s1 = _dets(11)
    s2 = _dets(1)
    result = verify_and_correct(s1, s2)
    assert result["consistent"] is False
    assert result["used_fallback"] is True
    assert result["detections"] is s1


# ---------------------------------------------------------------------------
# Boundary at exactly 10% retention
# ---------------------------------------------------------------------------

def test_exactly_at_threshold_is_consistent():
    # 1/10 = 0.10, consistent threshold = 1.0 - 0.90 = 0.10
    # 0.10 >= 0.10 → consistent
    s1 = _dets(10)
    s2 = _dets(1)
    result = verify_and_correct(s1, s2)
    assert result["consistent"] is True
    assert result["used_fallback"] is False


# ---------------------------------------------------------------------------
# Partial retention
# ---------------------------------------------------------------------------

def test_half_retained_consistent():
    s1 = _dets(10)
    s2 = _dets(5)
    result = verify_and_correct(s1, s2)
    assert result["retain_ratio"] == pytest.approx(0.5)
    assert result["consistent"] is True
    assert result["used_fallback"] is False
    assert result["detections"] is s2


def test_retain_ratio_is_rounded_to_3_decimals():
    s1 = _dets(3)
    s2 = _dets(1)
    result = verify_and_correct(s1, s2)
    assert result["retain_ratio"] == round(1 / 3, 3)


# ---------------------------------------------------------------------------
# Custom tolerance
# ---------------------------------------------------------------------------

def test_custom_tolerance_stricter():
    # drop_tolerance=0.5 → need retain_ratio >= 0.5
    s1 = _dets(10)
    s2 = _dets(4)  # 40% retained → inconsistent
    result = verify_and_correct(s1, s2, drop_tolerance=0.5)
    assert result["consistent"] is False
    assert result["used_fallback"] is True


def test_custom_tolerance_more_lenient():
    # drop_tolerance=0.99 → need retain_ratio >= 0.01; even 5% retained is OK
    s1 = _dets(100)
    s2 = _dets(5)   # 5% retained ≥ 0.01 → consistent
    result = verify_and_correct(s1, s2, drop_tolerance=0.99)
    assert result["consistent"] is True
    assert result["used_fallback"] is False


# ---------------------------------------------------------------------------
# Output shape
# ---------------------------------------------------------------------------

def test_result_contains_expected_keys():
    s1 = _dets(4)
    s2 = _dets(2)
    result = verify_and_correct(s1, s2)
    assert set(result.keys()) == {"raw_count", "filtered_count", "retain_ratio", "consistent", "used_fallback", "detections"}


def test_raw_and_filtered_counts_correct():
    s1 = _dets(7)
    s2 = _dets(3)
    result = verify_and_correct(s1, s2)
    assert result["raw_count"] == 7
    assert result["filtered_count"] == 3

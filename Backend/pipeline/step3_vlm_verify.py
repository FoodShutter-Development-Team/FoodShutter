"""
Step 3: Count consistency check (VLM-free).

Compares the NMS-only count vs the fully-filtered Step-2 count.
Fallback only triggers when the area filter removed >90% of boxes,
which indicates a genuine edge case (e.g. all dishes near the border),
not the normal heavy-filtering that happens in crowded scenes.
"""


def verify_and_correct(
    step1_detections: list[dict],
    step2_detections: list[dict],
    drop_tolerance: float = 0.90,
) -> dict:
    """
    Safety-net check: if area+containment filtering threw away more than
    `drop_tolerance` fraction of boxes, revert to the pre-filter list so
    at least some detections reach the next step.

    The threshold is intentionally conservative (90%) so that the fallback
    only fires on true degenerate cases, not on crowded scenes where heavy
    filtering is correct behaviour.
    """
    raw_count = len(step1_detections)
    filtered_count = len(step2_detections)

    if raw_count == 0:
        return {
            "raw_count": 0,
            "filtered_count": 0,
            "consistent": True,
            "used_fallback": False,
            "detections": [],
        }

    retain_ratio = filtered_count / raw_count
    consistent = retain_ratio >= (1.0 - drop_tolerance)

    if consistent:
        detections = step2_detections
        used_fallback = False
    else:
        detections = step1_detections
        used_fallback = True

    return {
        "raw_count": raw_count,
        "filtered_count": filtered_count,
        "retain_ratio": round(retain_ratio, 3),
        "consistent": consistent,
        "used_fallback": used_fallback,
        "detections": detections,
    }

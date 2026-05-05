"""Step 2: Bbox post-processing — NMS, containment suppression, area filter, edge warning."""


def _iou(a: list[float], b: list[float]) -> float:
    ix1, iy1 = max(a[0], b[0]), max(a[1], b[1])
    ix2, iy2 = min(a[2], b[2]), min(a[3], b[3])
    inter = max(0.0, ix2 - ix1) * max(0.0, iy2 - iy1)
    area_a = (a[2] - a[0]) * (a[3] - a[1])
    area_b = (b[2] - b[0]) * (b[3] - b[1])
    union = area_a + area_b - inter
    return inter / union if union > 0 else 0.0


def _containment(small: list[float], large: list[float]) -> float:
    """Fraction of `small` box's area that lies inside `large` box."""
    ix1, iy1 = max(small[0], large[0]), max(small[1], large[1])
    ix2, iy2 = min(small[2], large[2]), min(small[3], large[3])
    inter = max(0.0, ix2 - ix1) * max(0.0, iy2 - iy1)
    area_small = (small[2] - small[0]) * (small[3] - small[1])
    return inter / area_small if area_small > 0 else 0.0


def _area(bbox: list[float]) -> float:
    return (bbox[2] - bbox[0]) * (bbox[3] - bbox[1])


def _nms(detections: list[dict], iou_threshold: float = 0.5) -> list[dict]:
    if not detections:
        return []
    ordered = sorted(detections, key=lambda d: d.get("confidence", 1.0), reverse=True)
    kept: list[dict] = []
    while ordered:
        best = ordered.pop(0)
        kept.append(best)
        ordered = [d for d in ordered if _iou(best["bbox"], d["bbox"]) < iou_threshold]
    return kept


def _containment_suppression(detections: list[dict], containment_threshold: float = 0.72) -> list[dict]:
    """
    Remove boxes that are mostly inside a larger box.

    Iterates largest-first; any box whose area overlaps the keeper by
    more than `containment_threshold` is dropped.  This catches the
    common "bowl outer frame + food inner frame" double-detection that
    regular IoU NMS misses (IoU is low because the large box adds a lot
    of extra area to the union).
    """
    if len(detections) <= 1:
        return detections

    by_area = sorted(detections, key=lambda d: _area(d["bbox"]), reverse=True)
    kept: list[dict] = []

    for det in by_area:
        dominated = any(
            _area(det["bbox"]) < _area(k["bbox"])  # det is smaller
            and _containment(det["bbox"], k["bbox"]) > containment_threshold
            for k in kept
        )
        if not dominated:
            kept.append(det)

    return kept


def _clamp_bbox(bbox: list[float]) -> list[float]:
    x1, y1, x2, y2 = bbox
    x1, y1 = max(0.0, min(x1, 1.0)), max(0.0, min(y1, 1.0))
    x2, y2 = max(0.0, min(x2, 1.0)), max(0.0, min(y2, 1.0))
    if x1 > x2:
        x1, x2 = x2, x1
    if y1 > y2:
        y1, y2 = y2, y1
    return [x1, y1, x2, y2]


def postprocess(
    detections: list[dict],
    iou_threshold: float = 0.5,
    containment_threshold: float = 0.72,
    min_area_ratio: float = 0.02,
    max_area_ratio: float = 0.65,
    edge_margin: float = 0.02,
) -> dict:
    """NMS → containment suppression → area bounds filter → edge warning."""
    for d in detections:
        d["bbox"] = _clamp_bbox(d["bbox"])

    after_nms = _nms(detections, iou_threshold)
    after_containment = _containment_suppression(after_nms, containment_threshold)

    kept: list[dict] = []
    filtered: list[dict] = []
    for d in after_containment:
        b = d["bbox"]
        area = _area(b)
        if area < min_area_ratio:
            filtered.append({**d, "filter_reason": "too_small", "area": round(area, 4)})
        elif area > max_area_ratio:
            filtered.append({**d, "filter_reason": "too_large", "area": round(area, 4)})
        else:
            touches_edge = (
                b[0] <= edge_margin or b[1] <= edge_margin
                or b[2] >= 1.0 - edge_margin or b[3] >= 1.0 - edge_margin
            )
            entry = {**d, "area": round(area, 4)}
            if touches_edge:
                entry["edge_warning"] = True
            kept.append(entry)

    return {
        "detections": kept,
        "filtered_out": filtered,
        "counts": {
            "raw": len(detections),
            "after_nms": len(after_nms),
            "after_containment": len(after_containment),
            "after_area_filter": len(kept),
        },
    }

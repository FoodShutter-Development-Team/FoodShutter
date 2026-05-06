"""Step 1: Dish detection via VLM."""

import pathlib

from pipeline.llm_client import vision_json

_PROMPT = """\
Detect every distinct food dish or food container visible in this image.

Rules:
- box_2d coordinates are normalized to 0–1000. Origin (0,0) is top-left. Order is [y_min, x_min, y_max, x_max].
- Bounding boxes must be tight but complete: cover the entire container and all its visible contents.
- One entry per distinct container or food item. Do not merge separate dishes into one box.
- label: specific English dish name (e.g. "Kung Pao Chicken", "Steamed White Rice", "Wonton Soup").
- container: bowl | plate | small_dish | cup | other.
- portion: small | medium | large, relative to a typical restaurant serving."""

_SCHEMA = {
    "type": "object",
    "properties": {
        "detections": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "label":     {"type": "string"},
                    "box_2d":   {"type": "array", "items": {"type": "number"}, "minItems": 4, "maxItems": 4},
                    "container": {"type": "string", "enum": ["bowl", "plate", "small_dish", "cup", "other"]},
                    "portion":   {"type": "string", "enum": ["small", "medium", "large"]},
                },
                "required": ["label", "box_2d", "container", "portion"],
                "additionalProperties": False,
            },
        }
    },
    "required": ["detections"],
    "additionalProperties": False,
}


def detect_dishes(image_path: str) -> list[dict]:
    """
    Detect dishes in one image via VLM.

    Returns list of {label, bbox: [x1,y1,x2,y2] normalised to [0,1], confidence}.
    Gemini outputs box_2d as [y_min, x_min, y_max, x_max] on 0-1000 scale.
    """
    img_bytes = pathlib.Path(image_path).read_bytes()
    result = vision_json(img_bytes, _PROMPT, _SCHEMA, schema_name="detections")

    detections: list[dict] = []
    for item in result.get("detections", []):
        b = item.get("box_2d", [])
        if len(b) != 4:
            continue
        # Gemini native order: [y_min, x_min, y_max, x_max]
        y0, x0, y1, x1 = [c / 1000.0 for c in b]
        detections.append({
            "label":     item.get("label", "food"),
            "bbox":      [x0, y0, x1, y1],
            "confidence": 0.90,
            "container": item.get("container", "other"),
            "portion":   item.get("portion", "medium"),
        })

    return detections

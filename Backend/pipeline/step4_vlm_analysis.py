"""Step 4: Per-dish VLM analysis.

Each bbox gets its own VLM call (parallel via ThreadPoolExecutor).
The full detection list is injected as global context so the model
knows the entire scene and can stay consistent with names/portions.
"""

import io
from concurrent.futures import ThreadPoolExecutor, as_completed

from PIL import Image, ImageDraw

from pipeline.llm_client import chat_json, vision_json

# ---------------------------------------------------------------------------
# JSON Schema
# ---------------------------------------------------------------------------

_INGREDIENT_SCHEMA = {
    "type": "object",
    "properties": {
        "name":    {"type": "string"},
        "grams":   {"type": "number"},
        "cooking": {"type": "string", "enum": ["stir_fried", "steamed", "boiled", "fried", "raw", "pickled", "other"]},
    },
    "required": ["name", "grams", "cooking"],
    "additionalProperties": False,
}

_DISH_SCHEMA = {
    "type": "object",
    "properties": {
        "empty":                  {"type": "boolean"},
        "dish_name":              {"type": ["string", "null"]},
        "icon":                   {"type": ["string", "null"]},
        "container":              {"type": ["string", "null"], "enum": ["bowl", "plate", "small_dish", "cup", "other", None]},
        "portion_size":           {"type": ["string", "null"], "enum": ["small", "medium", "large", None]},
        "estimated_total_grams":  {"type": ["number", "null"]},
        "confidence":             {"type": ["string", "null"], "enum": ["high", "medium", "low", None]},
        "ingredients":            {"type": "array", "items": _INGREDIENT_SCHEMA},
    },
    "required": ["empty", "dish_name", "icon", "container", "portion_size", "estimated_total_grams", "confidence", "ingredients"],
    "additionalProperties": False,
}

_INGREDIENT_LIST_SCHEMA = {
    "type": "object",
    "properties": {
        "ingredients": {"type": "array", "items": _INGREDIENT_SCHEMA}
    },
    "required": ["ingredients"],
    "additionalProperties": False,
}

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------

_PROMPT_TEMPLATE = """\
The red bounding box marks the dish you must analyse (the box is approximate; the dish may extend slightly beyond it).

[Full meal context — {total} dish(es) detected in this image]
{scene_list}

You are analysing dish {current_idx} (highlighted by the red box).
Canonical dish name: "{hint_label}" (container: {hint_container}, portion: {hint_portion}).

Rules:
- dish_name: use "{hint_label}" exactly, unless the visual evidence clearly shows a different dish — in that case correct it minimally.
- empty: true only if the boxed area contains no food (empty bowl/plate).
- icon: a single emoji that best represents the dish, e.g. 🍚 🍜 🍲 🥩 🐟 🥗 🥟 🍳 🥣 (null if empty=true).
- ingredients: list at least 2 if empty=false; empty array if empty=true.
- If image is blurry or partially obscured, infer typical ingredients from dish_name, set confidence="low"."""

_RETRY_TEMPLATE = """\
The dish is "{dish_name}", approximately {grams}g.
List its typical ingredients with estimated gram weights.
Use realistic English ingredient names (e.g. "cooked white rice", "ground pork", "garlic")."""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _scene_list(detections: list[dict]) -> str:
    lines = []
    for i, d in enumerate(detections, 1):
        lines.append(f"  {i}. {d.get('label', 'unknown')} ({d.get('container', '?')}, {d.get('portion', '?')} portion)")
    return "\n".join(lines)


def _annotate_bbox(image_path: str, bbox: list[float]) -> bytes:
    """Draw a thick red rectangle on a copy of the image, return JPEG bytes."""
    img = Image.open(image_path).convert("RGB")
    draw = ImageDraw.Draw(img)
    w, h = img.size
    x1, y1, x2, y2 = bbox
    px1, py1, px2, py2 = int(x1 * w), int(y1 * h), int(x2 * w), int(y2 * h)
    line_width = max(5, int(min(w, h) * 0.008))
    draw.rectangle([px1, py1, px2, py2], outline="red", width=line_width)
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=92)
    return buf.getvalue()


# ---------------------------------------------------------------------------
# Per-dish VLM call
# ---------------------------------------------------------------------------

def _call_one(
    idx: int,
    det: dict,
    image_path: str,
    scene_ctx: str,
    total: int,
    save_dir,
) -> tuple[int, dict]:
    """Single-dish VLM call; returns (original_idx, result_dict)."""
    from pathlib import Path as _Path

    bbox = det["bbox"]
    img_bytes = _annotate_bbox(image_path, bbox)

    if save_dir:
        (_Path(save_dir) / f"dish_{idx+1:02d}_annotated.jpg").write_bytes(img_bytes)

    prompt = _PROMPT_TEMPLATE.format(
        total=total,
        scene_list=scene_ctx,
        current_idx=idx + 1,
        hint_label=det.get("label", "unknown"),
        hint_container=det.get("container", "other"),
        hint_portion=det.get("portion", "medium"),
    )

    parsed = vision_json(img_bytes, prompt, _DISH_SCHEMA, schema_name="dish_analysis")

    # Retry: non-empty dish returned no ingredients — infer from name.
    if not parsed.get("empty") and not parsed.get("ingredients"):
        dish_name = parsed.get("dish_name") or det.get("label", "unknown dish")
        retry_prompt = _RETRY_TEMPLATE.format(
            dish_name=dish_name,
            grams=parsed.get("estimated_total_grams") or 200,
        )
        retry = chat_json(retry_prompt, _INGREDIENT_LIST_SCHEMA, schema_name="ingredients")
        parsed["ingredients"] = retry.get("ingredients", [])
        parsed["confidence"] = "low"
        parsed["ingredient_source"] = "name_inferred"

    parsed["bbox_id"] = idx + 1
    parsed["bbox"] = bbox
    parsed.setdefault("empty", False)
    return idx, parsed


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def analyze_dishes(
    image_path: str,
    final_detections: list[dict],
    save_dir: str | None = None,
    max_workers: int = 4,
) -> list[dict]:
    """Call VLM once per detected dish in parallel (ThreadPoolExecutor)."""
    from pathlib import Path as _Path
    if save_dir:
        _Path(save_dir).mkdir(parents=True, exist_ok=True)

    scene_ctx = _scene_list(final_detections)
    total = len(final_detections)
    if total == 0:
        return []
    results: list[dict | None] = [None] * total

    with ThreadPoolExecutor(max_workers=min(max_workers, total)) as pool:
        futures = {
            pool.submit(_call_one, idx, det, image_path, scene_ctx, total, save_dir): idx
            for idx, det in enumerate(final_detections)
        }
        for future in as_completed(futures):
            idx, result = future.result()
            results[idx] = result

    return results

"""Step 6: LLM decision layer — select DB entries, fill gaps, validate ingredients."""

from concurrent.futures import ThreadPoolExecutor, as_completed

from pipeline.llm_client import chat_json

# ---------------------------------------------------------------------------
# JSON Schema
# ---------------------------------------------------------------------------

_INGREDIENT_SCHEMA = {
    "type": "object",
    "properties": {
        "name":      {"type": "string"},
        "icon":      {"type": "string"},
        "grams":     {"type": "number"},
        "protein_g": {"type": "number"},
        "fat_g":     {"type": "number"},
        "carb_g":    {"type": "number"},
        "source":    {"type": "string", "enum": ["database", "llm_estimated"]},
        "confidence":{"type": "string", "enum": ["high", "medium", "low"]},
        "fdc_id":    {"type": ["integer", "null"]},
    },
    "required": ["name", "icon", "grams", "protein_g", "fat_g", "carb_g", "source", "confidence", "fdc_id"],
    "additionalProperties": False,
}

_SCHEMA = {
    "type": "object",
    "properties": {
        "dishes": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "bbox_id":     {"type": "integer"},
                    "dish_name":   {"type": "string"},
                    "ingredients": {"type": "array", "items": _INGREDIENT_SCHEMA},
                },
                "required": ["bbox_id", "dish_name", "ingredients"],
                "additionalProperties": False,
            },
        }
    },
    "required": ["dishes"],
    "additionalProperties": False,
}

# ---------------------------------------------------------------------------
# Prompt (structure described once, schema enforced by API)
# ---------------------------------------------------------------------------

_PROMPT_HEADER = """\
You are a nutrition analysis assistant. Below is a list of dishes with their ingredients \
and candidate entries retrieved from a nutrition database (values per 100 g).

Dish data:
"""

_PROMPT_FOOTER = """

Complete three tasks for every ingredient:

Task A (DB hit): where db_candidates is non-empty, select the best-matching entry \
(by name and cooking method), copy its protein_g/fat_g/carb_g/fdc_id, \
set source="database", confidence="high".

Task B (DB miss): where db_candidates is empty, estimate protein_g/fat_g/carb_g \
per 100 g from your knowledge, set source="llm_estimated", confidence="low", fdc_id=null.

Task C (plausibility): if an ingredient is clearly implausible for the dish, set confidence="low".

icon: a single emoji that best represents each ingredient (e.g. 🥩 🐟 🥚 🧅 🥕 🍅 🌾 🥛 🫘 🌶️).
All ingredient names must be in English."""


# ---------------------------------------------------------------------------
# Prompt builder
# ---------------------------------------------------------------------------

def _build_prompt_for_dish(dish: dict, step5_results: dict) -> str:
    import json
    bbox_id = dish["bbox_id"]
    ings = []
    for ing in dish.get("ingredients", []):
        name = ing["name"]
        candidates = step5_results.get(bbox_id, {}).get(name, [])
        ings.append({
            "name": name,
            "grams": ing.get("grams", 100),
            "cooking": ing.get("cooking", "other"),
            "db_candidates": candidates,
        })
    payload = [{"bbox_id": bbox_id, "dish_name": dish.get("dish_name", ""), "ingredients": ings}]
    return _PROMPT_HEADER + json.dumps(payload, ensure_ascii=False, indent=2) + _PROMPT_FOOTER


def _call_one(dish: dict, step5_results: dict) -> dict | None:
    prompt = _build_prompt_for_dish(dish, step5_results)
    last_err = None
    for attempt in range(3):
        try:
            result = chat_json(prompt, _SCHEMA, schema_name="nutrition_decision")
            dishes = result.get("dishes", [])
            return dishes[0] if dishes else None
        except ValueError as e:
            last_err = e
    raise last_err


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def decide_nutrition(
    step4_results: list[dict],
    step5_results: dict,
    max_workers: int = 4,
) -> list[dict]:
    """One LLM call per dish in parallel (ThreadPoolExecutor)."""
    non_empty = [d for d in step4_results if not d.get("empty")]
    if not non_empty:
        return []

    results: list[dict | None] = [None] * len(non_empty)
    with ThreadPoolExecutor(max_workers=min(max_workers, len(non_empty))) as pool:
        futures = {
            pool.submit(_call_one, dish, step5_results): idx
            for idx, dish in enumerate(non_empty)
        }
        for future in as_completed(futures):
            idx = futures[future]
            results[idx] = future.result()

    return [r for r in results if r is not None]

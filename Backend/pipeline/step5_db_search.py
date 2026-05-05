"""Step 5: Search nutrition vector DB for each ingredient from Step 4."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

_DEFAULT_DB_PATH = str(Path(__file__).parent.parent / "nutrition_db" / "chroma_db")

# Shared singleton — injected at startup to avoid cold-start on every request.
_shared_db = None


def set_shared_db(db) -> None:
    global _shared_db
    _shared_db = db


def _search_dish(dish: dict, db) -> tuple[int, dict[str, list]]:
    bbox_id = dish["bbox_id"]
    result: dict[str, list] = {}
    for ing in dish.get("ingredients", []):
        name = ing["name"]
        result[name] = db.search(name, top_k=3) if (db and db.available) else []
    return bbox_id, result


def search_ingredients(
    step4_results: list[dict],
    db_path: str | None = None,
    max_workers: int = 4,
) -> dict:
    """
    For each non-empty dish, search the nutrition DB for each ingredient.
    Dishes are searched in parallel. Uses shared singleton DB when available.

    Returns {bbox_id: {ingredient_name: [candidates]}}.
    """
    db = _shared_db
    if db is None:
        db_path = db_path or _DEFAULT_DB_PATH
        try:
            from nutrition_db.nutrition_db import NutritionVectorDB
            db = NutritionVectorDB(db_path)
        except Exception:
            pass

    dishes = [d for d in step4_results if not d.get("empty")]
    if not dishes:
        return {}

    output: dict[int, dict[str, list]] = {}
    with ThreadPoolExecutor(max_workers=min(max_workers, len(dishes))) as pool:
        futures = {pool.submit(_search_dish, dish, db): dish["bbox_id"] for dish in dishes}
        for future in as_completed(futures):
            bbox_id, candidates = future.result()
            output[bbox_id] = candidates

    return output

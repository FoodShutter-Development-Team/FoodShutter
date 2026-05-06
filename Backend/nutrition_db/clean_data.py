"""Clean USDA FoodData Central Foundation Foods JSON → foundation_foods_cleaned.json.

Usage:
    python nutrition_db/clean_data.py

Download source data from:
    https://fdc.nal.usda.gov/download-datasets
    Select: Foundation Foods → JSON format
    Place the zip/json under: nutrition_db/data/raw/
"""

import json
import sys
from pathlib import Path

NUTRIENT_IDS = {1003: "protein_g", 1004: "fat_g", 1005: "carb_g"}

RAW_DIR = Path(__file__).parent / "data" / "raw"
OUT_FILE = Path(__file__).parent / "data" / "foundation_foods_cleaned.json"


def clean(raw_path: Path) -> tuple[list[dict], dict]:
    with open(raw_path, encoding="utf-8") as f:
        data = json.load(f)

    records = data.get("FoundationFoods", data) if isinstance(data, dict) else data

    cleaned: list[dict] = []
    skipped = {"missing_description": 0, "missing_nutrients": 0, "duplicate": 0}
    seen: set[str] = set()

    for item in records:
        if item is None:
            continue
        desc = (item.get("description") or "").strip()
        if not desc:
            skipped["missing_description"] += 1
            continue

        key = desc.lower()
        if key in seen:
            skipped["duplicate"] += 1
            continue

        nutrient_map = {
            n["nutrient"]["id"]: n["amount"]
            for n in item.get("foodNutrients", [])
            if "id" in n.get("nutrient", {}) and "amount" in n
        }

        row: dict = {"fdc_id": item.get("fdcId"), "name": key}
        ok = True
        for nid, field in NUTRIENT_IDS.items():
            if nid not in nutrient_map:
                ok = False
                break
            row[field] = round(float(nutrient_map[nid]), 2)

        if not ok:
            skipped["missing_nutrients"] += 1
            continue

        seen.add(key)
        cleaned.append(row)

    return cleaned, skipped


def main() -> None:
    raw_files = sorted(RAW_DIR.glob("FoodData_Central_foundation_food_json_*.json"))
    if not raw_files:
        print(f"No USDA Foundation Foods JSON found in {RAW_DIR}")
        print("Download from: https://fdc.nal.usda.gov/download-datasets")
        sys.exit(1)

    raw_path = raw_files[-1]
    print(f"Processing: {raw_path.name}")

    cleaned, skipped = clean(raw_path)

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_FILE, "w", encoding="utf-8") as f:
        json.dump(cleaned, f, ensure_ascii=False, indent=2)

    total_raw = len(cleaned) + sum(skipped.values())
    print(f"Raw entries  : {total_raw}")
    print(f"Kept         : {len(cleaned)}")
    print(f"Skipped      : {skipped}")
    print(f"Output       : {OUT_FILE}")


if __name__ == "__main__":
    main()

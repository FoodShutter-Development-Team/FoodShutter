"""Step 7: Pure Python result assembly — compute macros, calories, confidence grades."""

_KCAL = {"protein": 4.0, "fat": 9.0, "carb": 4.0}
_CONF_RANK = {"high": 2, "medium": 1, "low": 0}


def _overall_confidence(ingredients: list[dict]) -> str:
    if not ingredients:
        return "low"
    min_rank = min(_CONF_RANK.get(i.get("confidence", "low"), 0) for i in ingredients)
    return ["low", "medium", "high"][min_rank]


def assemble_result(step4_results: list[dict], step6_results: list[dict]) -> dict:
    """Merge step4 dish info with step6 nutrition decisions; compute totals."""
    step6_by_id = {d["bbox_id"]: d for d in step6_results if "bbox_id" in d}

    dishes_out = []
    img_protein = img_fat = img_carb = img_cal = 0.0

    for dish in step4_results:
        if dish.get("empty"):
            dishes_out.append({"bbox_id": dish["bbox_id"], "empty": True})
            continue

        bbox_id = dish["bbox_id"]
        s6 = step6_by_id.get(bbox_id, {})
        ingredients = s6.get("ingredients", [])

        total_protein = total_fat = total_carb = 0.0
        for ing in ingredients:
            g = ing.get("grams") or 0
            total_protein += g / 100.0 * (ing.get("protein_g") or 0)
            total_fat += g / 100.0 * (ing.get("fat_g") or 0)
            total_carb += g / 100.0 * (ing.get("carb_g") or 0)

        total_cal = (
            total_protein * _KCAL["protein"]
            + total_fat * _KCAL["fat"]
            + total_carb * _KCAL["carb"]
        )

        img_protein += total_protein
        img_fat += total_fat
        img_carb += total_carb
        img_cal += total_cal

        dishes_out.append({
            "bbox_id": bbox_id,
            "bbox": dish.get("bbox"),
            "dish_name": s6.get("dish_name") or dish.get("dish_name", ""),
            "icon": dish.get("icon"),
            "container": dish.get("container", "other"),
            "portion_size": dish.get("portion_size", "medium"),
            "estimated_total_grams": dish.get("estimated_total_grams", 0),
            "ingredients": ingredients,
            "total_protein_g": round(total_protein, 1),
            "total_fat_g": round(total_fat, 1),
            "total_carb_g": round(total_carb, 1),
            "total_calories": round(total_cal, 1),
            "overall_confidence": _overall_confidence(ingredients),
            "step4_confidence": dish.get("confidence", "low"),
            "empty": False,
        })

    return {
        "dishes": dishes_out,
        "image_totals": {
            "total_protein_g": round(img_protein, 1),
            "total_fat_g": round(img_fat, 1),
            "total_carb_g": round(img_carb, 1),
            "total_calories": round(img_cal, 1),
            "dish_count": sum(1 for d in dishes_out if not d.get("empty")),
        },
    }

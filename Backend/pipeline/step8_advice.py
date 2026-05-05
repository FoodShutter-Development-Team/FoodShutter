"""Step 8: Generate personalized meal advice from profile + dietary history."""

import json

from pipeline.llm_client import chat_json

_RECOMMENDED_DISH_SCHEMA = {
    "type": "object",
    "properties": {
        "dish_name":           {"type": "string"},
        "icon":                {"type": "string"},
        "weight":              {"type": "number"},
        "proteinPercent":      {"type": "number"},
        "fatPercent":          {"type": "number"},
        "carbohydratePercent": {"type": "number"},
    },
    "required": ["dish_name", "icon", "weight", "proteinPercent", "fatPercent", "carbohydratePercent"],
    "additionalProperties": False,
}

_NEXT_MEAL_SCHEMA = {
    "type": "object",
    "properties": {
        "recommended_dish": _RECOMMENDED_DISH_SCHEMA,
        "reason":           {"type": "string"},
        "nutrients_focus":  {"type": "array", "items": {"type": "string"}},
    },
    "required": ["recommended_dish", "reason", "nutrients_focus"],
    "additionalProperties": False,
}

_SCHEMA = {
    "type": "object",
    "properties": {
        "summary":                  {"type": "string"},
        "nutrition_status":         {"type": "string", "enum": ["balanced", "high_carb", "low_protein", "high_fat", "low_calorie", "high_calorie"]},
        "pros":                     {"type": "array", "items": {"type": "string"}},
        "cons":                     {"type": "array", "items": {"type": "string"}},
        "suggestions":              {"type": "array", "items": {"type": "string"}},
        "next_meal_recommendation": _NEXT_MEAL_SCHEMA,
    },
    "required": ["summary", "nutrition_status", "pros", "cons", "suggestions", "next_meal_recommendation"],
    "additionalProperties": False,
}

_ACTIVITY_MULTIPLIERS = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
}


def _estimate_daily_targets(profile: dict) -> dict:
    """Mifflin-St Jeor BMR → TDEE adjusted for goal."""
    weight = profile.get("weight_kg") or 65
    height = profile.get("height_cm") or 170
    age = profile.get("age") or 30
    gender = profile.get("gender", "other")
    activity = profile.get("activity_level", "moderate")
    goal = profile.get("health_goal", "balanced_diet") or "balanced_diet"

    if gender == "male":
        bmr = 10 * weight + 6.25 * height - 5 * age + 5
    elif gender == "female":
        bmr = 10 * weight + 6.25 * height - 5 * age - 161
    else:
        bmr = 10 * weight + 6.25 * height - 5 * age - 78

    tdee = bmr * _ACTIVITY_MULTIPLIERS.get(activity, 1.55)

    if "loss" in goal:
        tdee -= 500
    elif "gain" in goal:
        tdee += 300

    return {
        "calories": round(tdee),
        "protein_g": round(tdee * 0.30 / 4),
        "fat_g": round(tdee * 0.25 / 9),
        "carb_g": round(tdee * 0.45 / 4),
    }


def generate_advice(
    profile: dict,
    today_totals: dict,
    week_avg: dict,
    current_meal_result: dict,
    meal_type: str,
) -> dict:
    """Single Gemini call → structured advice JSON."""
    targets = profile.get("nutrition_targets") or _estimate_daily_targets(profile)

    remaining = {
        "calories": round(targets.get("calories", 2000) - today_totals.get("total_calories", 0), 1),
        "protein_g": round(targets.get("protein_g", 150) - today_totals.get("total_protein_g", 0), 1),
        "fat_g": round(targets.get("fat_g", 55) - today_totals.get("total_fat_g", 0), 1),
        "carb_g": round(targets.get("carb_g", 225) - today_totals.get("total_carb_g", 0), 1),
    }

    context = {
        "user_profile": {
            "age": profile.get("age"),
            "gender": profile.get("gender"),
            "weight_kg": profile.get("weight_kg"),
            "height_cm": profile.get("height_cm"),
            "activity_level": profile.get("activity_level"),
            "health_goal": profile.get("health_goal"),
            "dietary_preferences": profile.get("dietary_preferences") or [],
            "special_notes": profile.get("special_notes"),
        },
        "daily_targets": targets,
        "today_intake_so_far": today_totals,
        "remaining_quota_today": remaining,
        "current_meal": {
            "meal_type": meal_type,
            "dishes": [
                {
                    "name": d.get("dish_name", ""),
                    "calories": d.get("total_calories", 0),
                    "protein_g": d.get("total_protein_g", 0),
                    "fat_g": d.get("total_fat_g", 0),
                    "carb_g": d.get("total_carb_g", 0),
                }
                for d in current_meal_result.get("dishes", [])
                if not d.get("empty")
            ],
            "totals": current_meal_result.get("image_totals", {}),
        },
        "last_7_days_daily_average": week_avg,
    }

    prompt = f"""You are a professional nutritionist. Generate personalised meal advice based on the user's dietary data below.

Data:
{json.dumps(context, ensure_ascii=False, indent=2)}

Rules:
- summary: 2–3 sentences covering all meals today, not just the current one.
- suggestions: specific and actionable — avoid vague advice. Provide at least 3.
- next_meal_recommendation: structured object with recommended_dish (dish_name, icon emoji, weight in grams, macronutrient percentages of total calories), reason (one sentence explaining why this dish fits today's gaps), and nutrients_focus (2–3 short strings like "Increase dietary fiber").
- All text must be in English."""

    return chat_json(prompt, _SCHEMA, schema_name="meal_advice")

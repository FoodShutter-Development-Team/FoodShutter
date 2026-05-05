import asyncio
import json
import os
import shutil
import tempfile
import time
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

from supabase import Client, create_client

from pipeline.step1_detection import detect_dishes
from pipeline.step2_postprocess import postprocess
from pipeline.step3_vlm_verify import verify_and_correct
from pipeline.step4_vlm_analysis import analyze_dishes
from pipeline.step5_db_search import search_ingredients
from pipeline.step6_llm_decision import decide_nutrition
from pipeline.step7_assembly import assemble_result
from pipeline.step8_advice import generate_advice


def _debug_dir(meal_id: str) -> Path | None:
    """Return a per-meal debug output directory if DEBUG_OUTPUT_DIR is set, else None."""
    base = os.environ.get("DEBUG_OUTPUT_DIR")
    if not base:
        return None
    d = Path(base) / meal_id
    d.mkdir(parents=True, exist_ok=True)
    return d


def _save_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def _get_supabase() -> Client:
    return create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])


def _upload_image(sb: Client, user_id: str, meal_id: str, image_bytes: bytes, content_type: str) -> str:
    ext = content_type.split("/")[-1].replace("jpeg", "jpg")
    path = f"{user_id}/{meal_id}.{ext}"
    sb.storage.from_("meal-photos").upload(
        path=path,
        file=image_bytes,
        file_options={"content-type": content_type, "upsert": "true"},
    )
    return path


def _write_phase1(sb: Client, meal_id: str, final_detections: list) -> None:
    """Write dish names + bboxes, set status → dishes_ready."""
    # step3 detections use "label"; bbox_id is assigned 1-indexed in step4.
    # Use i+1 here so sort_order matches step4's bbox_id exactly.
    rows = [
        {
            "meal_id": meal_id,
            "name": det.get("label") or f"dish_{i + 1}",
            "icon": det.get("icon"),
            "sort_order": i + 1,
            "bbox": det.get("bbox"),
            "empty": False,
        }
        for i, det in enumerate(final_detections)
    ]
    if rows:
        sb.table("dishes").insert(rows).execute()
    sb.table("meals").update({"status": "dishes_ready"}).eq("id", meal_id).execute()


def _write_phase2(sb: Client, meal_id: str, nutrition_result: dict) -> None:
    """Write ingredients + macro totals to dishes. Does NOT set status=complete (caller does that after phase3)."""
    for dish in nutrition_result["result"]["dishes"]:
        if dish.get("empty"):
            continue

        row = (
            sb.table("dishes")
            .select("id")
            .eq("meal_id", meal_id)
            .eq("sort_order", dish["bbox_id"])
            .maybe_single()
            .execute()
        )
        if not row.data:
            continue
        dish_id = row.data["id"]

        sb.table("dishes").update({
            "name": dish.get("dish_name") or dish.get("name", ""),
            "icon": dish.get("icon"),
            "container": dish.get("container"),
            "portion_size": dish.get("portion_size"),
            "estimated_total_grams": dish.get("estimated_total_grams", 0),
            "total_protein_g": dish.get("total_protein_g", 0),
            "total_fat_g": dish.get("total_fat_g", 0),
            "total_carb_g": dish.get("total_carb_g", 0),
            "total_calories": dish.get("total_calories", 0),
            "confidence": dish.get("overall_confidence"),
        }).eq("id", dish_id).execute()

        ing_rows = []
        for j, ing in enumerate(dish.get("ingredients", [])):
            grams = ing.get("grams", 0) or 0
            protein_g = ing.get("protein_g", 0)
            fat_g = ing.get("fat_g", 0)
            carb_g = ing.get("carb_g", 0)
            ing_rows.append({
                "dish_id": dish_id,
                "name": ing["name"],
                "icon": ing.get("icon"),
                "weight_grams": grams,
                "protein_pct": round(protein_g / grams, 4) if grams > 0 else 0,
                "fat_pct": round(fat_g / grams, 4) if grams > 0 else 0,
                "carbohydrate_pct": round(carb_g / grams, 4) if grams > 0 else 0,
                "protein_g": protein_g,
                "fat_g": fat_g,
                "carb_g": carb_g,
                "calories": round(protein_g * 4 + fat_g * 9 + carb_g * 4, 1),
                "confidence": ing.get("confidence"),
                "source": ing.get("source"),
                "fdc_id": ing.get("fdc_id"),
                "sort_order": j,
            })
        if ing_rows:
            sb.table("ingredients").insert(ing_rows).execute()


def _fetch_today_totals(sb: Client, user_id: str) -> dict:
    """Sum macros across all of today's complete meals for the user."""
    today_start = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0
    ).isoformat()

    meals = (
        sb.table("meals")
        .select("id")
        .eq("user_id", user_id)
        .eq("status", "complete")
        .gte("timestamp", today_start)
        .execute()
    )

    totals = {"total_calories": 0.0, "total_protein_g": 0.0, "total_fat_g": 0.0, "total_carb_g": 0.0}
    for meal in meals.data:
        dishes = (
            sb.table("dishes")
            .select("total_calories,total_protein_g,total_fat_g,total_carb_g")
            .eq("meal_id", meal["id"])
            .eq("empty", False)
            .execute()
        )
        for d in dishes.data:
            for k in totals:
                totals[k] = round(totals[k] + (d.get(k) or 0), 1)

    return totals


def _fetch_week_avg(sb: Client, user_id: str) -> dict:
    """Compute daily average macros over the last 7 days (excluding today)."""
    now = datetime.now(timezone.utc)
    week_start = (now - timedelta(days=7)).isoformat()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()

    meals = (
        sb.table("meals")
        .select("id,timestamp")
        .eq("user_id", user_id)
        .eq("status", "complete")
        .gte("timestamp", week_start)
        .lt("timestamp", today_start)
        .execute()
    )

    daily: dict[str, dict] = defaultdict(
        lambda: {"total_calories": 0.0, "total_protein_g": 0.0, "total_fat_g": 0.0, "total_carb_g": 0.0}
    )

    for meal in meals.data:
        date_key = meal["timestamp"][:10]
        dishes = (
            sb.table("dishes")
            .select("total_calories,total_protein_g,total_fat_g,total_carb_g")
            .eq("meal_id", meal["id"])
            .eq("empty", False)
            .execute()
        )
        for d in dishes.data:
            for k in daily[date_key]:
                daily[date_key][k] = round(daily[date_key][k] + (d.get(k) or 0), 1)

    if not daily:
        return {"total_calories": 0, "total_protein_g": 0, "total_fat_g": 0, "total_carb_g": 0, "days_tracked": 0}

    n = len(daily)
    avg = {k: round(sum(day[k] for day in daily.values()) / n, 1) for k in next(iter(daily.values()))}
    avg["days_tracked"] = n
    return avg


def _write_phase3(sb: Client, meal_id: str, user_id: str, nutrition_result: dict, meal_type: str) -> None:
    """Fetch history, call step8, write meal_advices."""
    profile_row = sb.table("profiles").select("*").eq("id", user_id).maybe_single().execute()
    profile = profile_row.data or {}

    today_totals = _fetch_today_totals(sb, user_id)
    week_avg = _fetch_week_avg(sb, user_id)

    advice = generate_advice(
        profile=profile,
        today_totals=today_totals,
        week_avg=week_avg,
        current_meal_result=nutrition_result["result"],
        meal_type=meal_type,
    )

    sb.table("meal_advices").insert({
        "meal_id": meal_id,
        "user_id": user_id,
        "summary": advice.get("summary", ""),
        "nutrition_status": advice.get("nutrition_status", ""),
        "pros": advice.get("pros", []),
        "cons": advice.get("cons", []),
        "suggestions": advice.get("suggestions", []),
        "next_meal_recommendation": advice.get("next_meal_recommendation"),
    }).execute()


def _run_job(meal_id: str, image_bytes: bytes, content_type: str, user_id: str, meal_type: str) -> None:
    sb = _get_supabase()
    tmp_path = None
    dbg = _debug_dir(meal_id)
    try:
        storage_path = _upload_image(sb, user_id, meal_id, image_bytes, content_type)
        sb.table("meals").update({"photo_url": storage_path}).eq("id", meal_id).execute()

        ext = content_type.split("/")[-1].replace("jpeg", "jpg")
        with tempfile.NamedTemporaryFile(suffix=f".{ext}", delete=False) as f:
            f.write(image_bytes)
            tmp_path = f.name

        if dbg:
            shutil.copy(tmp_path, dbg / f"image.{ext}")

        # Phase 1: detection → dishes_ready
        step1 = detect_dishes(tmp_path)
        step2 = postprocess(step1)
        step3 = verify_and_correct(step1, step2["detections"])
        final_detections = step3["detections"]
        _write_phase1(sb, meal_id, final_detections)

        if dbg:
            _save_json(dbg / "step1_detection.json", step1)
            _save_json(dbg / "step2_postprocess.json", step2)
            _save_json(dbg / "step3_verify.json", step3)

        # Phase 2: nutrition → complete (retry on Gemini 429)
        nutrition_result = None
        annotated_dir = str(dbg / "annotated") if dbg else None
        for attempt in range(3):
            try:
                step4 = analyze_dishes(tmp_path, final_detections, save_dir=annotated_dir)
                step5 = search_ingredients(step4)
                step6 = decide_nutrition(step4, step5)
                result = assemble_result(step4, step6)
                nutrition_result = {"step4": step4, "step5": step5, "step6": step6, "result": result}
                _write_phase2(sb, meal_id, nutrition_result)
                break
            except Exception as e:
                if ("429" in str(e) or "RESOURCE_EXHAUSTED" in str(e)) and attempt < 2:
                    time.sleep(30 * (attempt + 1))
                    continue
                raise

        if dbg and nutrition_result is not None:
            _save_json(dbg / "step4_vlm_analysis.json", nutrition_result["step4"])
            _save_json(dbg / "step5_db_search.json", nutrition_result["step5"])
            _save_json(dbg / "step6_decision.json", nutrition_result["step6"])
            _save_json(dbg / "step7_report.json", nutrition_result["result"])

        # Phase 3: advice → meal_advices, then status=complete
        # Must write advice BEFORE setting complete so iOS fetch doesn't race.
        if nutrition_result is not None:
            try:
                _write_phase3(sb, meal_id, user_id, nutrition_result, meal_type)
            except Exception as e:
                print(f"[phase3] advice generation failed for {meal_id}: {e}")
        sb.table("meals").update({"status": "complete"}).eq("id", meal_id).execute()

    except Exception as e:
        sb.table("meals").update({
            "status": "failed",
            "pipeline_error": str(e),
        }).eq("id", meal_id).execute()
        raise
    finally:
        if tmp_path:
            Path(tmp_path).unlink(missing_ok=True)


async def run_job(meal_id: str, image_bytes: bytes, content_type: str, user_id: str, meal_type: str) -> None:
    """Async wrapper — runs blocking pipeline in a thread so the event loop stays free."""
    await asyncio.to_thread(_run_job, meal_id, image_bytes, content_type, user_id, meal_type)

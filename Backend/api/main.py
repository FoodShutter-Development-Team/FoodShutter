import os
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from typing import Annotated

from dotenv import load_dotenv

load_dotenv()

from fastapi import BackgroundTasks, Depends, FastAPI, File, Form, HTTPException, UploadFile
from supabase import create_client

from .auth import verify_token
from .jobs import run_job


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Pre-warm the embedding model so the first request doesn't pay cold-start cost.
    try:
        from nutrition_db.nutrition_db import NutritionVectorDB
        from pipeline.step5_db_search import set_shared_db
        db = NutritionVectorDB()
        set_shared_db(db)
    except Exception:
        pass
    yield


app = FastAPI(title="FoodShutter Pipeline API", lifespan=lifespan)

_ALLOWED_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/heic", "image/heif", "image/webp"}
_MAX_BYTES = 20 * 1024 * 1024  # 20 MB


def _supabase():
    return create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_SERVICE_ROLE_KEY"])


@app.post("/analyze", status_code=202)
async def analyze(
    background_tasks: BackgroundTasks,
    image: UploadFile = File(...),
    meal_type: str = Form(default="other"),
    user_id: Annotated[str, Depends(verify_token)] = ...,
):
    content_type = (image.content_type or "").lower()
    if content_type not in _ALLOWED_TYPES:
        raise HTTPException(415, f"Unsupported image type: {content_type}")

    image_bytes = await image.read()
    if len(image_bytes) > _MAX_BYTES:
        raise HTTPException(413, "Image too large (max 20 MB)")

    sb = _supabase()

    profile = sb.table("profiles").select("id").eq("id", user_id).maybe_single().execute()
    if not profile.data:
        raise HTTPException(403, "User profile not found")

    meal_id = str(uuid.uuid4())
    sb.table("meals").insert({
        "id": meal_id,
        "user_id": user_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "meal_type": meal_type,
        "status": "processing",
    }).execute()

    background_tasks.add_task(run_job, meal_id, image_bytes, content_type, user_id, meal_type)

    return {"job_id": meal_id}


@app.get("/health")
def health():
    return {"status": "ok"}

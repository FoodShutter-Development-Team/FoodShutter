# FoodShutter analysis service

Python 3.12+ FastAPI service for asynchronous meal analysis, with eight processing steps, a configurable model endpoint, optional ChromaDB retrieval and Supabase persistence.

[Setup](../docs/getting-started.md) · [API](../docs/api.md) · [Pipeline](../docs/ai-pipeline.md) · [Tests](../docs/testing.md) · [Data contract](../docs/data-model.md)

## Run locally

```bash
cp .env.example .env
# Configure your own Supabase and model-service credentials.
uv sync
uv run uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Run from `Backend/`. In PowerShell use `Copy-Item .env.example .env`. Keep service-role and model keys on the server.

`GET /health` checks process liveness. Authenticated `POST /analyze` returns HTTP `202` with a meal UUID. Results are written to Supabase through `processing`, `dishes_ready` and `complete`/`failed`. No separate job-query or nutrition-search HTTP route exists in this application.

Provision the Supabase tables, policies, Storage bucket and Auth configuration first. No SQL migrations are included. The [setup guide](../docs/getting-started.md#1-provision-supabase) explains required contracts and client differences.

The model endpoint must accept vision and the current strict JSON-schema request format. Qwen LoRA training under `Finetune/finetune` is an optional experiment.

## Nutrition index

Place extracted USDA Foundation Foods JSON under `nutrition_db/data/raw/`, then run:

```bash
uv run python nutrition_db/clean_data.py
uv run python nutrition_db/build_db.py
```

This replaces the `nutrition` collection. Runtime lookup requires the cached BGE model. Missing lookup can continue with explicitly labeled estimates.

## Tests

```bash
uv sync --group dev
uv run pytest
uv run pytest --cov=pipeline --cov=api --cov=nutrition_db --cov-report=term-missing
```

The suite mocks external services. See [recorded results](../docs/testing.md) and [release requirements](../docs/deployment.md), including the ingredient-unit persistence mismatch.

[`docs`](docs) preserves earlier design notes. Some describe an older detection-only stage and SDK examples; the repository-level references above describe current source.

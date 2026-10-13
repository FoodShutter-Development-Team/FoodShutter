# API reference

[Documentation index](README.md) · [Data model](data-model.md)

The checked-in FastAPI application exposes `/health` and `/analyze`, plus FastAPI's default documentation and OpenAPI routes. Meal results are read from Supabase. There is no separate `GET /jobs/{id}` or `POST /search` route in the current application.

Source: [`api/main.py`](../Backend/api/main.py), [`api/auth.py`](../Backend/api/auth.py), [`api/jobs.py`](../Backend/api/jobs.py).

## GET /health

No authentication required. Returns HTTP `200`:

```json
{"status": "ok"}
```

This checks that the API process responds. Startup catches nutrition-index initialization errors, so this endpoint cannot establish dependency readiness.

## POST /analyze

Accepts `multipart/form-data` with a Supabase bearer token:

```http
Authorization: Bearer <supabase-access-token>
```

The backend resolves a signing key using the project's JWKS endpoint, validates the token with audience `authenticated`, and uses its `sub` value as the user ID. A corresponding `profiles` row is required.

| Form field | Required | Behavior |
| --- | --- | --- |
| `image` | Yes | Upload field containing the meal image |
| `meal_type` | No | String stored with the meal; defaults to `other` |

Accepted declared MIME types are `image/jpeg`, `image/jpg`, `image/png`, `image/heic`, `image/heif` and `image/webp`. The application checks the uploaded byte length against `20 × 1024 × 1024` bytes, or 20 MiB. The current route reads the entire upload before enforcing the limit.

HEIC/HEIF acceptance at the HTTP layer does not guarantee downstream decoding support: the per-dish stage uses Pillow, and no dedicated HEIF codec is included. The iOS client submits JPEG.

The client uses known meal categories, but the backend form field is a plain string and does not enforce an enum. See the current mobile `MealType` definition before depending on a particular category vocabulary.

Example, against your configured development service:

```bash
curl -X POST http://localhost:8000/analyze \
  -H "Authorization: Bearer <your-access-token>" \
  -F "image=@meal.jpg;type=image/jpeg" \
  -F "meal_type=lunch"
```

### Accepted response

HTTP `202`:

```json
{"job_id": "550e8400-e29b-41d4-a716-446655440000"}
```

`job_id` is the inserted `meals.id`. This response means analysis was scheduled in the current process, rather than completed.

### Error responses

FastAPI returns an error object with a `detail` field, or its validation error list.

| Status | Current trigger |
| --- | --- |
| `401` | Missing/invalid bearer header, expired token or rejected JWT |
| `403` | Authenticated user has no profile row |
| `413` | Uploaded image exceeds 20 MiB |
| `415` | Declared image MIME type is not accepted |
| `422` | Missing image field or invalid form input structure |
| `500` | Unhandled infrastructure errors, such as missing configuration or a failed database call |

Post-acceptance failures are recorded as `meals.status = failed` with `pipeline_error`; they do not change a response already returned as `202`.

## Reading results

| Status | Available data |
| --- | --- |
| `processing` | Meal ID, user, timestamp and category; image path is added after upload |
| `dishes_ready` | Initial dish names, normalized boxes and order |
| `complete` | Final dish totals and ingredients; advice when its generation succeeded |
| `failed` | Failure information; earlier rows may exist because writes are not transactional |

Read the meal status through authorized Supabase queries or a Realtime subscription filtered to `meals.id`. Fetch the dishes ordered by `sort_order`, and fetch ingredients through their parent dish. Advice lives in `meal_advices`.

The current iOS observer combines Realtime with polling every three seconds and stops after 60 seconds. A client timeout is a local observation limit; a backend job may still finish afterward.

## Contract boundaries

There is no exposed job cancellation, durable-queue guarantee or idempotency key. Retrying an upload creates a new meal. The model JSON schemas are specified inside the pipeline source rather than shipped as a separately versioned schema pack.

Treat the ingredient-unit persistence mismatch described in [the data model](data-model.md#nutrition-units-and-current-mismatch) as a blocker before using the records for verified nutrient accounting.

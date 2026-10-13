# Getting started

[Documentation index](README.md) · [Backend](../Backend/README.md) · [Web](../web/README.md)

The backend and web client can be developed on Windows, Linux or macOS. Building and testing the iOS application requires macOS and Xcode. A fresh clone contains source code and tests; it does not contain a ready-to-use Supabase project or trained weights.

## Prerequisites

| Component | Requirement |
| --- | --- |
| Backend | Python 3.12 or later and `uv`, or an equivalent virtual environment |
| Model service | Vision input and the structured JSON request format used by `pipeline/llm_client.py` |
| Nutrition lookup | USDA Foundation Foods JSON and the BGE embedding model cache, if database retrieval is required |
| Web | Node.js compatible with the locked Next.js package and npm |
| Mobile | Xcode 26, iOS 26 SDK, physical iPhone for capture, an Apple development signing configuration |

Examples below use a POSIX shell. In PowerShell, replace `cp .env.example .env` with `Copy-Item .env.example .env`, and use `Copy-Item .env.example .env.local` for the web client.

## 1. Provision Supabase

Use a project you control. The public project identifiers checked into the course prototype are not a reusable service deployment.

1. Configure Supabase Auth, and obtain the project URL and public anon key for clients. Keep the service-role key restricted to the backend.
2. Provision the tables expected by the code: `profiles`, `meals`, `dishes`, `ingredients`, `meal_advices` and `trophies`.
3. Provision or reconcile the additional `user_profiles` and `nutrition_goals` contracts currently used by the web settings pages.
4. Create the `meal-photos` Storage bucket, establish ownership policies, and enable Realtime publication for `meals` updates.
5. Configure authentication redirect URLs. The mobile scheme is `foodshutter://auth-callback`; the local web callback is `http://localhost:3000/auth/callback`.
6. If using Sign in with Apple or magic links, configure the corresponding provider and email settings for your own project.

No SQL migrations or RLS policy definitions are included. The [data-model reference](data-model.md) describes expectations inferred from the code, rather than supplying a database installation script. Until the schema and policies are provisioned, full authenticated application operation is blocked. Mocked tests can still run.

The mobile client uses signed photo URLs, while the web history adapter constructs public URLs. A private bucket is the preferred deployment policy, but the web adapter must then be updated to obtain authorized signed URLs. Do not make meal photographs public merely to conceal this integration difference.

## 2. Start the backend

From the repository root:

```bash
cd Backend
cp .env.example .env
uv sync
```

Configure `Backend/.env`:

| Variable | Purpose |
| --- | --- |
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-only database and Storage credential |
| `OPENAI_BASE_URL` | OpenAI-compatible endpoint including its API prefix, commonly `/v1` |
| `OPENAI_API_KEY` | Model-service credential |
| `LLM_MODEL` | A model identifier recognized by that endpoint |
| `DEBUG_OUTPUT_DIR` | Optional local artifact directory; leave empty for normal operation |

`OPENAI_BASE_URL` selects an API protocol adapter; it does not restrict the application to an OpenAI-hosted model. Verify that the chosen endpoint accepts image content, `response_format` with strict JSON schema, and the additional reasoning option sent by the current client. Unsupported providers need an adapter change.

```bash
uv run uvicorn api.main:app --host 0.0.0.0 --port 8000
```

Check process liveness at `http://localhost:8000/health` and inspect the generated API documentation at `http://localhost:8000/docs`. Liveness does not verify Supabase, model credentials or the nutrition index.

## 3. Build the optional nutrition index

Download the Foundation Foods JSON dataset using the source URL identified by [`clean_data.py`](../Backend/nutrition_db/clean_data.py). Extract the JSON into `Backend/nutrition_db/data/raw/` with the expected filename pattern `FoodData_Central_foundation_food_json_*.json`.

From `Backend/`:

```bash
uv run python nutrition_db/clean_data.py
uv run python nutrition_db/build_db.py
```

The build generates `nutrition_db/chroma_db` with collection name `nutrition`, and downloads `BAAI/bge-small-en-v1.5` if necessary. Query-time loading uses `local_files_only=True`, so preserve the embedding-model cache in a deployed environment.

The build command replaces the existing `nutrition` collection. Back up a deployed index before rebuilding it. Without a working index the service can continue with model-estimated values, but it is no longer providing database-supported nutrition matches.

## 4. Start the web companion

In another terminal, from the repository root:

```bash
cd web
cp .env.example .env.local
npm ci
npm run dev
```

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` to your project's public configuration. Open `http://localhost:3000`. Values with the `NEXT_PUBLIC_` prefix are sent to the browser; never put a service-role key there.

Meal browsing and charts use Supabase directly. Nutrition search additionally invokes an Edge Function and needs an endpoint absent from this backend. It is not required for ordinary meal-history browsing. See [web configuration](../web/README.md).

## 5. Configure and run iOS

1. Open `iOSApp/FoodShutter.xcodeproj` on macOS with Xcode 26 and resolve Swift Package dependencies.
2. Replace the project URL and public anon key in [`SupabaseClient.swift`](../iOSApp/FoodShutter/Core/Services/Supabase/SupabaseClient.swift) with your own project's public configuration.
3. Set `BackendAPIClient.baseURL` in [`BackendAPIClient.swift`](../iOSApp/FoodShutter/Core/Services/Backend/BackendAPIClient.swift). The checked-in value is a local development address. Use your computer's reachable LAN address for a phone, or an HTTPS URL for a deployed API.
4. Select your development team and a suitable bundle identifier in Signing & Capabilities. Configure Apple Sign-in if that login method is used.
5. Select the `FoodShutter` scheme and run on an iOS 26 device. Grant camera and, for LAN development, local-network access.

The current `Info.plist` permits arbitrary transport loads for development. Tighten this configuration when deploying over HTTPS; see [SECURITY.md](../SECURITY.md).

The repository also includes an XcodeGen definition. Regeneration is optional:

```bash
cd iOSApp
xcodegen generate
```

The checked-in project and `project.yml` both target iOS 26. Lowering the target requires a compatibility review; editing a README does not establish support for earlier iOS versions.

## First integrated check

Sign in, save a profile, capture a meal and verify the progression from `processing` to `dishes_ready` to `complete` in Supabase. Confirm dish and ingredient rows, inspect advice when available, then open web history with the same account. Run this only against your own development project with sample data.

| Symptom | Check |
| --- | --- |
| `401` on upload | Session token, token expiry and project JWKS configuration |
| `403 User profile not found` | Matching `profiles.id` row for the authenticated user |
| Meal remains `processing` | Background-worker logs, model endpoint and Supabase permissions |
| No database candidates | Built index, `nutrition` collection and local BGE cache |
| iPhone cannot reach API | Backend binding, reachable LAN address and local-network permission |
| Web photograph is missing | Private/public Storage URL mismatch |
| Web settings use defaults | Separate web profile/goals tables and their policies |
| iOS reports timeout | The observer deadline is 60 seconds; inspect the actual server status |

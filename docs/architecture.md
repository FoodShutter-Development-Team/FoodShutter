# Architecture

[Documentation index](README.md) · [Data model](data-model.md) · [API reference](api.md)

FoodShutter uses a native mobile client for capture, a Python analysis service, Supabase for shared records, and a browser client for reviewing meals. Analysis is asynchronous from the client's perspective: accepting an upload and completing model inference are separate operations.

![System architecture](assets/system-architecture.drawio.svg)

[Editable draw.io source](assets/system-architecture.drawio)

## Component responsibilities

| Component | Responsibility | Primary source |
| --- | --- | --- |
| iOS application state | Resolve authentication, route onboarding, manage analysis state and trophies | [`FoodShutterApp.swift`](../iOSApp/FoodShutter/App/FoodShutterApp.swift) |
| Mobile presentation | Render camera, dish detail, nutrition rings, history and profile screens | [`Features`](../iOSApp/FoodShutter/Features) |
| Mobile repositories | Read and write Supabase records, obtain signed image URLs, observe meal status | [`Core/Services/Supabase`](../iOSApp/FoodShutter/Core/Services/Supabase) |
| Analysis API | Validate bearer token, inspect upload type and size, create a meal, accept background work | [`api/main.py`](../Backend/api/main.py), [`api/auth.py`](../Backend/api/auth.py) |
| Job coordinator | Store the image, execute analysis phases, persist results and report failure | [`api/jobs.py`](../Backend/api/jobs.py) |
| Analysis modules | Detect dishes, estimate ingredients, retrieve nutrients, assemble totals and generate advice | [`pipeline`](../Backend/pipeline) |
| Nutrition index | Clean USDA records, encode names and retrieve per-100-gram macronutrients | [`nutrition_db`](../Backend/nutrition_db) |
| Web data access | Read meals and dishes, aggregate statistics, read or save web nutrition goals | [`web/lib/api`](../web/lib/api) |

The iOS implementation follows MVVM with repository adapters. SwiftUI views use `FoodAnalysisViewModel` and domain models rather than owning model inference. The web application uses the Next.js App Router, Supabase browser/server adapters and SWR data fetching.

## A meal's lifecycle

1. Supabase Auth supplies a user session. The iOS client converts the captured image to JPEG.
2. `POST /analyze` verifies the token and checks that a `profiles` row exists for that user. It inserts a meal with status `processing` and returns its UUID as `job_id`.
3. A FastAPI `BackgroundTasks` job runs the blocking pipeline in a thread using `asyncio.to_thread`. The photograph is stored in the `meal-photos` bucket.
4. Detection and filtering create initial dish rows. The job updates the meal to `dishes_ready`, allowing early display of names and boxes.
5. Ingredient analysis, retrieval and nutrient selection update dish totals and insert ingredient rows.
6. The service attempts to generate and store `meal_advices`, then sets the meal to `complete`. Advice failure is caught separately so nutrition can remain available.
7. Other failures set `failed` and write `pipeline_error`. Temporary image files are removed in `finally`.

```text
processing  ->  dishes_ready  ->  complete
     |               |
     +---------------+-------->  failed
```

There is no persisted `nutrition_ready` state. The backend has three internal phases, while the client exposes dish availability and final completion.

## Synchronization and state

`MealStatusObserver` starts a Realtime subscription and REST polling concurrently. Polling runs every three seconds with a 60-second deadline. The 30-second upload timeout is separate from this analysis deadline. Backend rate-limit retries can exceed the observer deadline, so a client timeout does not prove that the server job failed.

The web companion currently reads Supabase tables through request-based data access. It does not subscribe to meal updates through a web Realtime listener. The final presentation's shared-data design should therefore be read as a system design goal, with push updates currently implemented on iOS.

Supabase is the current source of meal history. Earlier local-persistence plans and legacy test filenames do not mean the current app uses SwiftData for its meal store.

## Capability status

| Area | Current status | Boundary |
| --- | --- | --- |
| iOS camera, authentication and profile | Implemented | Requires camera hardware, signing and a configured Supabase project |
| Eight-step nutrition analysis | Implemented | Requires a compatible model endpoint; generated values remain estimates |
| ChromaDB nutrition lookup | Implemented | Raw USDA data and the built index are excluded from Git |
| iOS meal status, nutrition and advice | Implemented | Realtime plus polling; ingredient-unit issue described in the data contract |
| iOS achievements | Implemented with demo seeding | Startup seeds historical trophies when a user has none |
| Web meal history and statistics | Implemented | Uses shared meal/dish tables; calendar aggregation still needs validation |
| Web profile and target settings | Separate data contract | Uses `user_profiles` and `nutrition_goals`, whereas iOS uses `profiles` |
| Web personalized suggestions | Sample content | `fetchSuggestions()` returns fixed messages |
| Web nutrition search | Integration scaffold | Edge Function calls `/search`; the checked-in FastAPI service lacks that route |
| Web account deletion | Placeholder | The button currently displays a request alert |
| Excel/PDF export, offline conflict resolution | Planned in course scope | No corresponding completed implementation in this tree |
| Public release and service operations | Further work required | No migrations, durable queue or automated deployment included |

## Design choices and tradeoffs

Staged results reduce the time before users can see which dishes were detected. Per-dish workers preserve the original image's context while separating ingredient analysis. A shared model client keeps endpoint configuration and structured-output requests consistent across stages. The nutrition index gives each lookup a source record rather than relying only on model recall.

The current in-process background worker suits a demonstration deployment. Process restarts can interrupt jobs, and multi-table writes do not constitute a transaction. A production service needs durable work execution, idempotent persistence and reconciliation for interrupted meals. Those requirements are listed in the [deployment plan](deployment.md), without implying that they are already implemented.

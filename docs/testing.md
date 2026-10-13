# Testing and validation

[Documentation index](README.md) · [Evaluation](evaluation.md)

Software tests check contracts and deterministic behavior. They are separate from evaluating food recognition, portion estimates or nutrient accuracy against labeled meals.

## Backend tests

From `Backend/`, using the project's configured development environment:

```bash
uv sync --group dev
uv run pytest
uv run pytest --cov=pipeline --cov=api --cov=nutrition_db --cov-report=term-missing
```

The project sets `pythonpath = ["."]`, test discovery under `tests`, and automatic asyncio mode in [`pyproject.toml`](../Backend/pyproject.toml). [`tests/conftest.py`](../Backend/tests/conftest.py) supplies test-only environment values and resets the shared model/JWKS clients.

The suite covers upload validation, authentication, model-client request construction, box filtering, consistency checks, per-dish analysis, retrieval interfaces, nutrition decisions, assembly and advice. Cloud calls and model responses are mocked. It does not require real API keys or a running Supabase instance.

## Recorded backend run

The existing suite was executed on 14 October 2026 against runtime source baseline `3a7bf20`:

| Item | Result |
| --- | --- |
| Platform / Python | Windows / CPython 3.12.14 |
| Test outcome | 237 passed |
| Overall statement coverage | 467 / 702 statements, 66.52% |
| `pipeline` | 315 / 325 statements, 96.92% |
| `api` | 95 / 217 statements, 43.78% |
| `nutrition_db` | 57 / 160 statements, 35.62% |

This run used isolated test dependencies installed for the documentation review. ChromaDB and the embedding model were not installed or executed as live services. Key test packages were pytest 9.1.1, pytest-asyncio 1.4.0, pytest-cov 7.1.0, FastAPI 0.143.0, httpx 0.28.1, Supabase 2.32.0 and OpenAI SDK 3.29.0. The repository uses dependency lower bounds rather than a committed backend lockfile, so another dependency resolution may differ.

The coverage command includes `api/jobs.py`, `nutrition_db/clean_data.py` and `nutrition_db/build_db.py`. The job coordinator has limited coverage, and the two offline build scripts have no coverage in this suite. A pipeline-only result must not be described as whole-backend coverage.

The initial review attempt encountered sandbox access errors in pytest's default temporary directory. The successful run used an explicit writable `--basetemp`; those setup errors were environmental and did not require test changes.

## iOS tests

Seven XCTest files contain 96 source-declared `test...` methods:

| Suite | Focus |
| --- | --- |
| `DishTests` | Ingredient aggregation, percentages and identity |
| `MealEntityTests` | Meal/status values and domain transformations |
| `MealPersistenceManagerTests` | Supabase row mappings and meal totals |
| `FoodEmojiMapperTests` | Dish and ingredient emoji mapping |
| `NutritionTargetsTests` | Target ranges and round trips |
| `ProfileRowTests` | Profile decoding and defaults |
| `TrophyTests` | Trophy decoding, metadata and date handling |

The test target is `FoodShutterTesting`, and the repository includes [`FoodShutter.xctestplan`](../iOSApp/FoodShutter.xctestplan). Despite older filenames, persistence tests currently examine Supabase/domain mappings rather than a SwiftData persistence manager.

On macOS, resolve packages, select the `FoodShutter` scheme and run Product → Test in Xcode 26. For command-line testing, first inspect the available schemes and destinations:

```bash
xcodebuild -list -project iOSApp/FoodShutter.xcodeproj
xcodebuild -showdestinations -project iOSApp/FoodShutter.xcodeproj -scheme FoodShutter
```

Use a valid iOS 26 destination from that output. The documentation review ran on Windows, so it did not execute XCTest or produce an iOS coverage measurement. Source method counts are not executed test counts.

## Web checks

From `web/`:

```bash
npm ci
npm run lint
npm run build
```

Supply a dedicated development Supabase configuration. The web package does not currently define a test script or include a browser regression suite. This documentation update does not claim a new passing web build or live integration test.

## Integrated acceptance requirements

Before a release, run an authenticated photo-to-result check against a controlled database and model service, verify user isolation, and compare the same meal on both clients. Include non-100-gram ingredients to catch the current persistence-unit mismatch.

Also test empty detections, invalid model output, retrieval misses, failed advice, network interruption, jobs exceeding 60 seconds, duplicate uploads, worker restart and missing Storage objects. Use fixtures with known reference labels and weighed portions when evaluating nutrition accuracy. Record the exact source, model and database versions with the results.

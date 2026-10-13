# Deployment and release readiness

[Documentation index](README.md) · [Security scope](../SECURITY.md)

The source tree contains a course prototype. The final presentation describes cloud deployment and a GPU model service, but the repository does not contain the complete infrastructure state needed to recreate those deployments.

## Deployment components

| Component | Source | External requirements |
| --- | --- | --- |
| Analysis API | `Backend/api` and `Backend/pipeline` | Python 3.12+, Supabase server credential, compatible model endpoint |
| Web companion | `web` | Node environment, public Supabase configuration, auth redirects |
| iOS app | `iOSApp/FoodShutter.xcodeproj` | Xcode 26, signing, public Supabase configuration, reachable API |
| Nutrition index | `Backend/nutrition_db` | USDA JSON, ChromaDB index, cached BGE model |
| Optional private model | Training scripts and presentation design | Base weights, adapter, GPU, verified serving environment |

The reviewed baseline has no Dockerfiles, database migration scripts, durable job broker, automated release workflows or committed trained weights. The presentation's Vercel and GPU deployments are historical evidence; their current availability was not verified.

## Release requirements identified in the source

| Requirement | Acceptance evidence |
| --- | --- |
| Correct ingredient persistence units | A non-100-gram portion produces identical dish, ingredient and client totals |
| Version the database schema and policies | A fresh project can be provisioned and tested with two isolated users |
| Reconcile private photograph delivery | Authorized signed access works on both clients; anonymous and cross-user access fails |
| Configure HTTPS and restrictive ATS | Release builds send sensitive traffic only over HTTPS |
| Make jobs durable and writes idempotent | Worker restart and retry do not lose or duplicate records |
| Unify profile and goal contracts | A goal changed on either client has the same value on the other |
| Complete web suggestions, search and deletion | The user-visible actions invoke actual services |
| Validate calendar aggregation | Daily, weekly and monthly totals work across timezones |
| Remove automatic demo trophy seeding from release behavior | New accounts contain only actually earned achievements |
| Establish representative accuracy evidence | Versioned labels, weighed portions, raw outputs and model identity are archived |

The ingredient-unit issue is described in [the data contract](data-model.md#nutrition-units-and-current-mismatch). The web dashboard assumes the first history group represents today, and its statistics adapter groups by weekday labels, including in monthly mode. Backend daily advice uses UTC boundaries while clients display local dates. These are specific behaviors requiring validation before public release.

## Operations

Start with [local setup](getting-started.md) and controlled sample data. The checked-in iOS URL is a LAN HTTP address. The current `/health` endpoint checks process liveness and does not verify model, database or index readiness.

A service deployment needs durable work execution, explicit inference limits, ingress upload limits and a retry policy compatible with the client's 60-second observation window. FastAPI `BackgroundTasks` currently runs within the application process. Multi-table job writes are not transactional, and partial writes can remain after failure.

Record the source commit, dependency resolution, model revision, adapter checksum, prompt/schema version and nutrition-index version for each deployment. Monitor accepted/completed/failed jobs, database misses, advice failures and latency percentiles. Restrict debug artifact access and define retention and deletion for photographs and dietary records.

## Release verification

1. Provision a controlled Supabase project from versioned schema and policies.
2. Run unit tests and authenticated integration checks with synthetic users.
3. Exercise token expiry, image access, repeated uploads and interrupted jobs.
4. Compare one meal's values across backend, iOS and web with explicit units.
5. Verify the exact model endpoint's vision and strict JSON request support.
6. Build the web application and execute XCTest on a valid iOS 26 destination.
7. Archive the release identifiers and recovery procedure before promotion.

These are future release acceptance requirements, rather than completed certification or operational guarantees.

## Documentation recovery

The remote baseline before documentation work is `3a7bf208413c093998f93190600ee0d7c7b0615d`. Local branch `codex/backup-before-docs-20261014` records it. Branch `codex/backup-local-20261014` preserves the original local checkout at `a75e6f2` before synchronization.

To withdraw this documentation later, revert its pull-request merge or specific commits through a new commit. This preserves the application updates synchronized from GitHub and any later work.

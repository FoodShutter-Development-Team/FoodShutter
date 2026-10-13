# Contributing to FoodShutter

Start with the [documentation index](docs/README.md) and [capability status](docs/architecture.md#capability-status).

## Workflow

1. Describe the problem and expected behavior in an issue or pull-request body.
2. Create a focused branch from the current default branch.
3. Keep application changes, model experiments and documentation scoped to that problem.
4. Run checks relevant to the affected component.
5. Open a pull request describing behavior, validation and configuration implications.

Use meaningful commit messages and actual authorship and timestamps. Credit collaborators for work they contributed, with relevant issue/review evidence.

## Validation

| Change | Expected evidence |
| --- | --- |
| Pipeline calculations | Fixtures for normal and boundary inputs, with explicit units |
| API and persistence | Authorization, failure paths and persistence-to-client contracts |
| iOS | XCTest and device screenshots/walkthrough for UI changes |
| Web | Lint/build and a configured browser check using controlled accounts |
| Prompt/model | Versioned dataset, raw outputs, model identity, latency and error measurements |
| Documentation | Valid links, commands, source references and clear implementation status |

Prefer tests that can reveal behavioral defects over tests that repeat the implementation. See [testing](docs/testing.md).

Do not commit credentials, personal meal histories, private images, weights or raw training datasets. Use placeholder configuration and permitted sample data. Preserve explicit nutrient units, provenance and normalized box coordinates. Update adapters and regression evidence when changing shared fields.

Within `web/`, follow [`AGENTS.md`](web/AGENTS.md), including reading installed Next.js documentation before changing framework code.

## Review descriptions

State the concrete problem and resulting behavior, relevant checks and any schema/dependency changes. Identify limitations directly. Do not treat simulated course metrics as measured results or claim checks that were not executed.

For credential disclosures or vulnerabilities, follow [SECURITY.md](SECURITY.md).

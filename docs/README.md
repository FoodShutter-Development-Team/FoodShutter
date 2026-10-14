# FoodShutter documentation

[Repository overview](../README.md) · [简体中文](../README.zh-CN.md)

These documents describe the source tree at baseline `3a7bf20`, the final course presentation and its recorded demonstrations. Where those sources differ, current code determines runtime behavior and the course material supplies project history.

| Document | What it answers |
| --- | --- |
| [Getting started](getting-started.md) | What must be configured before running the backend, web and iOS clients? |
| [Architecture](architecture.md) | Which component owns each responsibility, and which features are complete? |
| [API reference](api.md) | How does a client submit an image and receive staged results? |
| [Data model](data-model.md) | Which tables and fields do the clients expect, and what units do they use? |
| [AI pipeline](ai-pipeline.md) | How do detection, ingredient analysis, retrieval and advice interact? |
| [Model training](model-training.md) | How do the Qwen experiments differ from the configurable runtime model? |
| [Testing](testing.md) | How are tests run, and what do the measured coverage numbers include? |
| [Evaluation](evaluation.md) | What does the final presentation's five-angle comparison demonstrate? |
| [Deployment](deployment.md) | What remains before an independently reproducible, public release? |
| [Demo](demo.md) | Which recording produced the screenshots and compressed video excerpts? |
| [Visual design](design/README.md) | Which application colors, typography and motion define the README assets? |
| [Project context](project-context.md) | How did course scope, team roles and management exercises inform the project? |

## Source precedence

1. Executable code, build configuration and tests define the current implementation.
2. The final presentation documents the demonstrated build and reported experiments.
3. Earlier course plans describe intended scope, assumptions and management exercises.

The original backend notes remain available in [`Backend/docs`](../Backend/docs). In particular, `progress.md` describes an earlier detection-only stage, and `ios-integration.md` contains earlier SDK examples and timing estimates. For current behavior, use the reference documents above and the linked source files.

## Diagram and media files

[`assets`](assets) contains original demonstration frames, complete recordings with audio, compressed silent excerpts, native draw.io source files and SVG assets with embedded diagram XML. [The asset generator](design/build_assets.py) reproduces the application styling and animated overlays. The diagrams represent this repository's implementation. They do not imply the presence of a durable job queue, automatic deployment or a provisioned database.

No student IDs, service credentials, raw training datasets or trained model weights are included in this documentation package.

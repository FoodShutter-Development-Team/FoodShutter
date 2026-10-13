# AI analysis pipeline

[Documentation index](README.md) · [Data model](data-model.md) · [Model experiments](model-training.md)

The pipeline separates visual interpretation, nutrition retrieval, model decisions and deterministic aggregation. [`api/jobs.py`](../Backend/api/jobs.py) coordinates the eight stages and writes their results to Supabase.

![Eight analysis steps](assets/analysis-pipeline.drawio.svg)

[Editable draw.io source](assets/analysis-pipeline.drawio)

## Stages

| Step | Input and processing | Output | Source |
| --- | --- | --- | --- |
| 1. Detection | Full photograph, vision prompt, JSON schema | Labels, boxes, container type and portion category | [`step1_detection.py`](../Backend/pipeline/step1_detection.py) |
| 2. Post-processing | Normalize boxes, NMS, containment suppression and area filtering | Kept boxes, filtered records and edge warnings | [`step2_postprocess.py`](../Backend/pipeline/step2_postprocess.py) |
| 3. Count check | Compare raw count with retained count | Retained boxes or recovery to the original list | [`step3_vlm_verify.py`](../Backend/pipeline/step3_vlm_verify.py) |
| 4. Dish analysis | Full photograph with one marked box and the meal's dish list | Per-dish ingredients, estimated weights and confidence | [`step4_vlm_analysis.py`](../Backend/pipeline/step4_vlm_analysis.py) |
| 5. Retrieval | Ingredient names, nutrition index, top-3 search | Nutrition candidates grouped by dish and ingredient | [`step5_db_search.py`](../Backend/pipeline/step5_db_search.py) |
| 6. Nutrition decision | Candidate list, ingredient weight and cooking context | Selected or estimated per-100-gram values and source labels | [`step6_llm_decision.py`](../Backend/pipeline/step6_llm_decision.py) |
| 7. Assembly | Dish identities and nutrition decisions | Deterministic totals, calorie estimates and confidence grades | [`step7_assembly.py`](../Backend/pipeline/step7_assembly.py) |
| 8. Advice | Profile, current meal, today's totals and recent history | Summary, strengths, concerns and next-meal recommendation | [`step8_advice.py`](../Backend/pipeline/step8_advice.py) |

Step 3 is currently a rule-based check despite the legacy `vlm_verify` filename. It does not perform another model inference.

## Detection controls

Current default thresholds:

| Control | Value | Meaning |
| --- | --- | --- |
| NMS IoU | `0.50` | Suppress overlapping detections |
| Containment | `0.72` | Remove a smaller box mostly inside a larger retained box |
| Minimum area | `0.02` | Remove boxes occupying less than 2% of the image |
| Maximum area | `0.65` | Remove boxes occupying more than 65% of the image |
| Edge margin | `0.02` | Flag boxes touching the outer 2% |
| Count-drop tolerance | `0.90` | Recover when fewer than 10% of raw detections remain |

These heuristics address duplicate containers and large background detections. They can also remove small dishes or unusually close photographs, so their quality needs validation across a representative meal dataset.

## Structured model calls

[`llm_client.py`](../Backend/pipeline/llm_client.py) centralizes the endpoint, API key and model identifier. Vision requests embed image bytes in a data URL. Model stages request `response_format.type = json_schema` with `strict = true`, then parse the returned JSON.

An endpoint must support the client's exact request dialect. `json.loads()` checks JSON syntax; it is not an independent complete schema validator. Schema-constrained generation also does not establish semantic correctness, ingredient truth or accurate portion weights.

When a non-empty dish returns no ingredients, Step 4 attempts a name-based ingredient estimate and marks it as low confidence. Step 6 retries a parsing `ValueError` up to three attempts. These paths address specific failures rather than providing a universal repair guarantee.

## Nutrition retrieval

The offline build cleans USDA Foundation Foods, removes entries with missing core macronutrients, deduplicates names, and encodes names with `BAAI/bge-small-en-v1.5`. ChromaDB stores text, food IDs and macronutrient metadata in the `nutrition` collection.

`NutritionVectorDB.search()` supports semantic, exact and hybrid modes. Here, exact mode is a lexical substring search with a ranking preference for equal names and prefixes. The active pipeline uses the default semantic mode with three candidates per ingredient; it does not automatically use hybrid search.

Database misses return empty candidate lists. Step 6's prompt directs the model to estimate values and attach `source = llm_estimated`, `confidence = low`, and a null `fdc_id`. A database match is a retrieval decision, rather than proof that the chosen food or cooking state is correct.

## Concurrency and failure handling

Steps 4, 5 and 6 each use `ThreadPoolExecutor` with a default limit of four workers. Results preserve dish identifiers and are assembled in input order. Processing stages remain sequential relative to one another; they do not form an unlimited parallel graph. Meal size, API limits and queue contention still affect latency.

The job retries the nutrition phase after an error containing `429` or `RESOURCE_EXHAUSTED`, waiting 30 then 60 seconds before the remaining attempts. The phase includes database writes, so a failure during persistence can leave partial records and needs an idempotency review before production use.

Advice generation is attempted after nutrient persistence. Its exception is logged, while the meal can still become `complete`. Other exceptions mark the meal `failed`. Temporary images are deleted, but uploaded photographs and optional debug artifacts remain subject to a deployment retention policy.

## Limits that affect interpretation

- Portion weight is inferred from photographs and dish context. There is no calibrated depth, scale or camera-metadata measurement implemented here.
- Confidence grades and fixed detection scores are not calibrated accuracy probabilities.
- Nutrient provenance can distinguish database retrieval from estimation, but model-selected database entries still need validation.
- The persistence boundary currently mixes per-100-gram and absolute ingredient values; see [the data contract](data-model.md#nutrition-units-and-current-mismatch).
- The five-angle course comparison measures consistency on a small example. It does not establish nutrition accuracy for arbitrary meals.

These constraints are part of the [release validation plan](deployment.md), alongside source-level tests and representative data evaluation.

# Evaluation evidence

[Documentation index](README.md) · [Software tests](testing.md)

This page separates the final presentation's reported experiment from the tests rerun during documentation work and from simulated course metrics.

## Five-angle meal comparison

Source: `FoodShutter_finalversion.pptx`, slide 59, “Evaluation.” The slide compares the FoodShutter pipeline with a baseline on five views of a meal whose reference dish count is seven.

### Reported macronutrient variation

The slide labels these values as coefficient of variation across five angles. Lower values indicate more consistent outputs across the photographs.

| Quantity | Pipeline CV | Baseline CV |
| --- | ---: | ---: |
| Calories | 6.4% | 22.1% |
| Protein | 8.9% | 9.9% |
| Fat | 17.1% | 37.5% |
| Carbohydrates | 11.8% | 25.2% |

### Reported dish counts

| View | Pipeline | Baseline | Reference |
| --- | ---: | ---: | ---: |
| Top | 7 | 5 | 7 |
| Front | 7 | 5 | 7 |
| Side A | 7 | 5 | 7 |
| Side B | 7 | 5 | 7 |
| Side C | 6 | 5 | 7 |
| Mean | 6.8 | 5.0 | 7 |

These counts imply mean absolute count errors of 0.2 and 2.0 respectively on these five views. Those are arithmetic summaries of the reported table, rather than a new rerun.

### Interpretation limits

The presentation supports a small demonstration of improved consistency and dish counting. It does not provide a representative validation set, weighed nutrient ground truth, a reproducible definition of the baseline, raw per-angle nutrient outputs, repeated stochastic trials or confidence intervals. Those artifacts are not included in the repository.

Low variation can coexist with a consistently incorrect nutrient estimate. The figures therefore cannot establish general food-recognition accuracy, portion accuracy, medical suitability or performance under arbitrary camera conditions. The current runtime model is environment-configured and may differ from the one used for the recorded comparison.

## Fine-tuning evidence

Slides 61–63 contain training and comparison visuals for the Qwen experiment. Slides 75–77 describe the model-serving setup. The repository provides training and comparison scripts, but does not include a complete checkpoint and result archive suitable for independently reproducing the slide figures. The [model guide](model-training.md) records source settings without inventing additional measured improvements.

## Reexecuted software tests

The backend test suite passed 237 tests on 14 October 2026. Overall coverage across `pipeline`, `api` and `nutrition_db` was 66.52%. These tests use mocks and verify software behavior, rather than recognition quality or service uptime. See [test scope and environment](testing.md#recorded-backend-run).

The presentation's iOS and backend test screenshots are historical presentation evidence. The new backend run is independently recorded; no new iOS result is claimed.

## Course reliability exercise

Slide 44 reports 96.00% reliability and 96.97% availability using a 48-hour window, 100 runs, four failures and 1.5 hours of repair time. The supporting course material explicitly labels the inputs as simulated. These numbers are teaching calculations, not measured production uptime or a service-level agreement.

Other scope and estimation figures, including LOC estimates, labor costs and process-maturity self-assessment, are documented in [project context](project-context.md). They are not product performance claims.

## Next validation work

Use a versioned meal corpus with varied cuisines, dish counts, lighting, viewpoints and independently measured portion weights. Report dish precision/recall, count error, ingredient matching, gram error and nutrient error separately. Include database-hit rate, low-confidence frequency, latency percentiles and failure rate with dataset size and model identity.

First resolve the persistence-unit mismatch and add an integrated regression. Then rerun both clients against the same source baseline. Archive image permissions, labels, raw outputs and evaluation code before publishing broader quality claims.

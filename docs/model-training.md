# Model training and serving

[Documentation index](README.md) · [Runtime pipeline](ai-pipeline.md)

The runtime pipeline is configured through `OPENAI_BASE_URL`, `OPENAI_API_KEY` and `LLM_MODEL`. The repository's Qwen training directory is a separate experiment. A trained Qwen adapter is not loaded automatically by the FastAPI service.

## Repository experiments

[`Backend/Finetune/finetune`](../Backend/Finetune/finetune) includes:

| Script | Purpose |
| --- | --- |
| `download_model.py` | Download `Qwen/Qwen3.5-9B` to a local model directory |
| `download_dataset.py` | Retrieve MM-Food-100K metadata and meal images |
| `fineTune.py` | Build structured targets, evaluate before/after, and train a LoRA adapter |
| `compare.py` / `compare_gemini.py` | Model comparison experiments |
| `visualize.py` / `plot_inference_speed.py` | Visualize experiment outputs |

Source-configured training values:

| Parameter | Current value |
| --- | --- |
| Dataset identifier | `Codatta/MM-Food-100K` |
| Configured sample limit | `10,000` |
| Epochs | `1` |
| Per-device batch size | `4` |
| Gradient accumulation | `2`, giving an effective batch of 8 on one device |
| Learning rate | `2e-4` |
| Maximum sequence length | `1,024` |
| LoRA rank / alpha / dropout | `16` / `32` / `0.1` |
| LoRA modules | `q_proj`, `v_proj` |
| CUDA quantization | 4-bit NF4, double quantization, bfloat16 compute |
| Evaluation sample cap | `20` |

The source defines these settings; it does not provide a complete archived training run. The comparison routines include structured text metrics such as exact match and normalized edit distance, which should not be presented as clinical nutrition accuracy.

## Running experiments

Use a separate environment satisfying [`requirements.txt`](../Backend/Finetune/finetune/requirements.txt). GPU training and model downloads are optional and can require substantial storage and GPU memory. Review dataset and model terms before downloading or redistributing artifacts.

The scripts assume their working directory contains `models/`, `mm_food_100k/` and `output/`. Adjust local paths and review downloader behavior before executing. The metadata downloader currently reuses an image-compression helper for CSV downloads; treat this as experimental tooling and inspect it before relying on unattended dataset preparation.

Training data, base weights, LoRA checkpoints, optimizer state and experiment results are not included in this repository. No specific fine-tuned checkpoint can be reproduced solely from this clone without the corresponding inputs and run records.

## Serving described in the final presentation

The final presentation describes Qwen3.5-9B plus a `checkpoint-1125` LoRA adapter, served using vLLM on a single GPU through an OpenAI-compatible API. It specifies rank 16, adapter name `nutrition-lora`, and schema-constrained output using xgrammar.

This is recorded presentation evidence. The checkpoint and a pinned vLLM deployment environment are absent from the source tree, and serving-library command-line options vary by release. The presentation's launch command is therefore not supplied as a verified installation procedure here.

To use a self-hosted model with the pipeline:

1. Install and verify a serving environment suitable for the model and your GPU.
2. Supply the exact base-model revision and full adapter directory, with matching rank.
3. Validate text, image and strict JSON-schema requests against the service's API.
4. Configure the backend to use that endpoint and its advertised model or adapter name.
5. Evaluate ingredient correctness and latency before changing the default runtime deployment.

Record the model revision, adapter checksum, serving version, generation settings and evaluation dataset for every comparison. Changing the model behind an unchanged API name should still be treated as an analysis behavior change.

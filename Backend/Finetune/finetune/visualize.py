"""
Visualize fine-tuning results by comparing base model vs fine-tuned model.
Generates 4 plots saved to visualize_results/

Usage:
    python visualize.py          # infer 200 test samples
    python visualize.py 50       # infer 50 test samples (faster)
"""

import sys
import json
import csv
import random
import re
import time
import torch
import warnings
warnings.filterwarnings("ignore", message=".*fast path is not available.*")
warnings.filterwarnings("ignore", message=".*flash-linear-attention.*")

from pathlib import Path
from PIL import Image
from tqdm import tqdm
from difflib import SequenceMatcher
import shutil
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use("Agg")  # non-interactive backend

from transformers import AutoModelForImageTextToText, AutoProcessor, BitsAndBytesConfig
from peft import PeftModel

# ── Config ──────────────────────────────────────────────────────────────────
MODEL_ID     = "models/Qwen3.5-9B"
IMAGES_DIR   = Path("mm_food_100k/images")
CSV_PATH     = Path("mm_food_100k/MM-Food-100K.csv")
OUT_DIR      = Path("visualize_results")
MAX_NEW_TOKENS = 512
DEVICE       = "cuda" if torch.cuda.is_available() else "cpu"
N_SAMPLES    = int(sys.argv[1]) if len(sys.argv) > 1 else 200
BASE_ONLY    = "--base-only" in sys.argv

SYSTEM_MESSAGE = (
    "You are a professional food analysis assistant. "
    "When given a photo of food, analyze it and return a JSON object with the following fields: "
    "dish_name, food_type, cooking_method, ingredients (list), "
    "portion_size (list of 'item:weight'), and nutritional_profile "
    "(calories_kcal, protein_g, fat_g, carbohydrate_g). "
    "Output only valid JSON, no extra text."
)

FOOD_TYPES = ["Homemade food", "Restaurant food", "Raw vegetables and fruits", "Packaged food", "Others"]


def find_latest_checkpoint() -> str:
    res = Path("output/res")
    if res.exists():
        return str(res)
    checkpoints = sorted(
        Path("output").glob("checkpoint-*"),
        key=lambda p: int(p.name.split("-")[1])
    )
    if checkpoints:
        return str(checkpoints[-1])
    raise FileNotFoundError("No checkpoint found in output/.")


# ── Data loading ─────────────────────────────────────────────────────────────
def load_test_samples(n: int):
    samples = []
    with open(CSV_PATH, encoding="utf-8") as f:
        for i, row in enumerate(csv.DictReader(f)):
            if i >= 10000:
                break
            url = row["image_url"].strip()
            img_path = IMAGES_DIR / Path(url.split("/")[-1]).with_suffix(".jpg")
            if img_path.exists():
                samples.append((img_path, row))

    random.seed(42)
    random.shuffle(samples)
    cut = int(len(samples) * 0.9)
    test_samples = samples[cut:]
    return test_samples[:n]


# ── Inference ─────────────────────────────────────────────────────────────────
def run_inference(model, processor, samples) -> list[dict]:
    results = []
    for img_path, row in tqdm(samples, desc="Inferring"):
        image = Image.open(img_path).convert("RGB")
        messages = [
            {"role": "system", "content": [{"type": "text", "text": SYSTEM_MESSAGE}]},
            {"role": "user", "content": [
                {"type": "image", "image": image},
                {"type": "text", "text": "Analyze this food image and return the structured JSON."},
            ]},
        ]
        prompt = processor.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True, enable_thinking=False
        )
        inputs = processor(text=prompt, images=image, return_tensors="pt").to(DEVICE)

        t0 = time.time()
        with torch.no_grad():
            output_ids = model.generate(**inputs, max_new_tokens=MAX_NEW_TOKENS, do_sample=False)
        inference_ms = (time.time() - t0) * 1000

        prompt_len = inputs["input_ids"].shape[1]
        text = processor.tokenizer.decode(output_ids[0][prompt_len:], skip_special_tokens=True).strip()

        try:
            pred = json.loads(text)
        except Exception:
            # Base model may wrap JSON in markdown fences or add extra text
            m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
            if m:
                raw = m.group(1)
            else:
                m = re.search(r"\{.*\}", text, re.DOTALL)
                raw = m.group(0) if m else ""
            try:
                pred = json.loads(raw)
            except Exception:
                pred = {}

        results.append({"pred": pred, "gt": row, "inference_ms": round(inference_ms, 1)})
    return results


# ── Metrics ───────────────────────────────────────────────────────────────────
def str_sim(a, b) -> float:
    a = a if isinstance(a, str) else json.dumps(a, ensure_ascii=False)
    b = b if isinstance(b, str) else json.dumps(b, ensure_ascii=False)
    return SequenceMatcher(None, a.lower().strip(), b.lower().strip()).ratio()


def ingredients_jaccard(pred_list, gt_str: str) -> float:
    try:
        gt_list = json.loads(gt_str) if isinstance(gt_str, str) else gt_str
    except Exception:
        return 0.0
    pred_set = {x.lower().strip() for x in pred_list} if isinstance(pred_list, list) else set()
    gt_set   = {x.lower().strip() for x in gt_list}   if isinstance(gt_list, list)  else set()
    if not pred_set and not gt_set:
        return 1.0
    if not pred_set or not gt_set:
        return 0.0
    return len(pred_set & gt_set) / len(pred_set | gt_set)


def compute_metrics(results: list[dict]) -> dict:
    dish_scores, ft_scores, cook_scores, ingr_scores = [], [], [], []
    cal_preds, cal_gts = [], []

    for r in results:
        pred, gt = r["pred"], r["gt"]

        # dish_name
        dish_scores.append(str_sim(pred.get("dish_name", ""), gt.get("dish_name", "")))

        # food_type exact match
        ft_scores.append(1.0 if pred.get("food_type", "").strip() == gt.get("food_type", "").strip() else 0.0)

        # cooking_method
        cook_scores.append(str_sim(pred.get("cooking_method", ""), gt.get("cooking_method", "")))

        # ingredients jaccard
        ingr_scores.append(ingredients_jaccard(
            pred.get("ingredients", []),
            gt.get("ingredients", "[]")
        ))

        # calories
        try:
            nutr = gt.get("nutritional_profile", "{}")
            if isinstance(nutr, str):
                nutr = json.loads(nutr)
            gt_cal = float(nutr.get("calories_kcal", 0))
            pred_cal = float(pred.get("nutritional_profile", {}).get("calories_kcal", 0))
            if gt_cal > 0 and pred_cal > 0:
                cal_gts.append(gt_cal)
                cal_preds.append(pred_cal)
        except Exception:
            pass

    return {
        "dish_name":      sum(dish_scores) / len(dish_scores),
        "food_type":      sum(ft_scores)   / len(ft_scores),
        "cooking_method": sum(cook_scores) / len(cook_scores),
        "ingredients":    sum(ingr_scores) / len(ingr_scores),
        "cal_preds":  cal_preds,
        "cal_gts":    cal_gts,
        "food_type_details": [
            (r["pred"].get("food_type", "").strip(), r["gt"].get("food_type", "").strip())
            for r in results
        ],
    }


# ── Plotting ──────────────────────────────────────────────────────────────────
def plot_field_accuracy(base_metrics: dict, ft_metrics: dict):
    fields = ["dish_name", "food_type", "cooking_method", "ingredients"]
    labels = ["Dish Name\n(similarity)", "Food Type\n(exact)", "Cooking Method\n(similarity)", "Ingredients\n(Jaccard)"]
    base_vals = [base_metrics[f] * 100 for f in fields]
    ft_vals   = [ft_metrics[f]   * 100 for f in fields]

    x = range(len(fields))
    fig, ax = plt.subplots(figsize=(10, 6))
    bars1 = ax.bar([i - 0.2 for i in x], base_vals, width=0.4, label="Base Model", color="#5B9BD5")
    bars2 = ax.bar([i + 0.2 for i in x], ft_vals,   width=0.4, label="Fine-tuned", color="#ED7D31")

    ax.set_xticks(list(x))
    ax.set_xticklabels(labels, fontsize=11)
    ax.set_ylabel("Score (%)", fontsize=12)
    ax.set_ylim(0, 110)
    ax.set_title("Field-level Prediction Accuracy: Base vs Fine-tuned", fontsize=14)
    ax.legend(fontsize=11)
    ax.bar_label(bars1, fmt="%.1f%%", padding=3, fontsize=9)
    ax.bar_label(bars2, fmt="%.1f%%", padding=3, fontsize=9)
    ax.grid(axis="y", alpha=0.3)

    path = OUT_DIR / "field_accuracy.png"
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {path}")


def plot_calorie_scatter(base_metrics: dict, ft_metrics: dict):
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))

    for ax, metrics, title in zip(
        axes,
        [base_metrics, ft_metrics],
        ["Base Model", "Fine-tuned Model"]
    ):
        gts   = metrics["cal_gts"]
        preds = metrics["cal_preds"]
        if not gts:
            ax.set_title(f"{title} — no data")
            continue

        max_val = max(max(gts), max(preds)) * 1.1
        ax.scatter(gts, preds, alpha=0.5, color="#5B9BD5" if "Base" in title else "#ED7D31", s=30)
        ax.plot([0, max_val], [0, max_val], "k--", linewidth=1, label="Perfect prediction")
        ax.plot([0, max_val], [0, max_val * 1.2], "r:", linewidth=1, alpha=0.5, label="+20%")
        ax.plot([0, max_val], [0, max_val * 0.8], "r:", linewidth=1, alpha=0.5, label="-20%")
        ax.set_xlabel("Ground Truth (kcal)", fontsize=11)
        ax.set_ylabel("Predicted (kcal)", fontsize=11)
        ax.set_title(title, fontsize=13)
        ax.legend(fontsize=9)
        ax.grid(alpha=0.3)

        errors = [abs(p - g) / g * 100 for p, g in zip(preds, gts) if g > 0]
        within_20 = sum(1 for e in errors if e <= 20) / len(errors) * 100
        ax.text(0.05, 0.92, f"Within ±20%: {within_20:.1f}%", transform=ax.transAxes,
                fontsize=10, bbox=dict(boxstyle="round", facecolor="wheat", alpha=0.5))

    fig.suptitle("Calorie Prediction: Predicted vs Ground Truth", fontsize=14)
    path = OUT_DIR / "calorie_scatter.png"
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {path}")


def plot_food_type_pie(base_metrics: dict, ft_metrics: dict):
    fig, axes = plt.subplots(1, 2, figsize=(14, 7))

    for ax, metrics, title in zip(
        axes,
        [base_metrics, ft_metrics],
        ["Base Model", "Fine-tuned Model"]
    ):
        details = metrics["food_type_details"]
        correct = sum(1 for p, g in details if p == g)
        wrong   = len(details) - correct
        ax.pie(
            [correct, wrong],
            labels=[f"Correct ({correct})", f"Wrong ({wrong})"],
            colors=["#70AD47", "#FF6B6B"],
            autopct="%1.1f%%",
            startangle=90,
            textprops={"fontsize": 12},
        )
        ax.set_title(f"{title}\nFood Type Accuracy", fontsize=13)

    path = OUT_DIR / "food_type_pie.png"
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {path}")


def plot_before_after_bar(base_metrics: dict, ft_metrics: dict):
    metrics_map = {
        "Dish Name\nSimilarity":    ("dish_name",      base_metrics, ft_metrics),
        "Food Type\nAccuracy":      ("food_type",      base_metrics, ft_metrics),
        "Cooking Method\nSimilarity":("cooking_method", base_metrics, ft_metrics),
        "Ingredients\nJaccard":     ("ingredients",    base_metrics, ft_metrics),
    }
    labels     = list(metrics_map.keys())
    base_vals  = [base_metrics[v[0]] * 100 for v in metrics_map.values()]
    ft_vals    = [ft_metrics[v[0]]   * 100 for v in metrics_map.values()]

    x = range(len(labels))
    fig, ax = plt.subplots(figsize=(10, 6))
    bars1 = ax.bar([i - 0.2 for i in x], base_vals, width=0.4, label="Base Model",  color="#5B9BD5")
    bars2 = ax.bar([i + 0.2 for i in x], ft_vals,   width=0.4, label="Fine-tuned",  color="#ED7D31")

    ax.set_xticks(list(x))
    ax.set_xticklabels(labels, fontsize=11)
    ax.set_ylabel("Score (%)", fontsize=12)
    ax.set_ylim(0, 115)
    ax.set_title("Before vs After Fine-tuning", fontsize=14)
    ax.legend(fontsize=11)
    ax.bar_label(bars1, fmt="%.1f%%", padding=3, fontsize=9)
    ax.bar_label(bars2, fmt="%.1f%%", padding=3, fontsize=9)
    ax.grid(axis="y", alpha=0.3)

    path = OUT_DIR / "before_after.png"
    fig.savefig(path, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {path}")


# ── Main ─────────────────────────────────────────────────────────────────────
def load_model(adapter_path: str | None = None):
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_use_double_quant=True,
        bnb_4bit_compute_dtype=torch.bfloat16,
    )
    model = AutoModelForImageTextToText.from_pretrained(
        MODEL_ID, device_map="auto", quantization_config=bnb_config
    )
    if adapter_path:
        model = PeftModel.from_pretrained(model, adapter_path)
    model.eval()
    return model


def main():
    OUT_DIR.mkdir(exist_ok=True)
    adapter_path = find_latest_checkpoint()
    print(f"Adapter: {adapter_path}")
    print(f"Inferring {N_SAMPLES} test samples per model\n")

    samples = load_test_samples(N_SAMPLES)
    print(f"Loaded {len(samples)} test samples\n")

    processor = AutoProcessor.from_pretrained(MODEL_ID)
    processor.tokenizer.padding_side = "left"

    # --- Base model ---
    print("=" * 40)
    print("Running BASE MODEL inference ...")
    base_model = load_model(adapter_path=None)
    base_results = run_inference(base_model, processor, samples)
    (OUT_DIR / "base_results_raw.json").write_text(json.dumps(
        [{"pred": r["pred"], "gt": r["gt"], "inference_ms": r["inference_ms"]} for r in base_results],
        indent=2, ensure_ascii=False))
    base_metrics = compute_metrics(base_results)
    del base_model
    torch.cuda.empty_cache()

    # --- Fine-tuned model ---
    if BASE_ONLY:
        print("\n[--base-only] Reusing existing fine-tuned results from inference_results.json ...")
        existing = json.loads((OUT_DIR / "inference_results.json").read_text())
        ft_results = [
            {"pred": e["finetuned_pred"], "inference_ms": e.get("finetuned_inference_ms", 0)}
            for e in existing
        ]
        ft_metrics = compute_metrics([
            {"pred": e["finetuned_pred"], "gt": e["ground_truth"]} for e in existing
        ])
    else:
        print("\n" + "=" * 40)
        print("Running FINE-TUNED MODEL inference ...")
        ft_model = load_model(adapter_path=adapter_path)
        ft_results = run_inference(ft_model, processor, samples)
        (OUT_DIR / "ft_results_raw.json").write_text(json.dumps(
            [{"pred": r["pred"], "gt": r["gt"], "inference_ms": r["inference_ms"]} for r in ft_results],
            indent=2, ensure_ascii=False))
        ft_metrics = compute_metrics(ft_results)
        del ft_model
        torch.cuda.empty_cache()

    # --- Copy sample images ---
    imgs_dir = OUT_DIR / "images"
    imgs_dir.mkdir(exist_ok=True)
    for img_path, _ in samples:
        shutil.copy2(img_path, imgs_dir / img_path.name)
    print(f"Copied {len(samples)} images to {imgs_dir}/")

    # --- Save raw inference results ---
    raw_out = []
    for (img_path, row), base_r, ft_r in zip(samples, base_results, ft_results):
        raw_out.append({
            "image": img_path.name,
            "ground_truth": {
                "dish_name":          row.get("dish_name", ""),
                "food_type":          row.get("food_type", ""),
                "cooking_method":     row.get("cooking_method", ""),
                "ingredients":        row.get("ingredients", ""),
                "portion_size":       row.get("portion_size", ""),
                "nutritional_profile":row.get("nutritional_profile", ""),
            },
            "base_pred":              base_r["pred"],
            "base_inference_ms":      base_r["inference_ms"],
            "finetuned_pred":         ft_r["pred"],
            "finetuned_inference_ms": ft_r["inference_ms"],
        })
    (OUT_DIR / "inference_results.json").write_text(
        json.dumps(raw_out, indent=2, ensure_ascii=False)
    )
    print(f"Inference results saved to {OUT_DIR}/inference_results.json")

    # --- Save summary metrics ---
    metrics_out = {
        "n_samples": len(samples),
        "adapter": adapter_path,
        "base": {k: v for k, v in base_metrics.items() if not isinstance(v, list)},
        "finetuned": {k: v for k, v in ft_metrics.items() if not isinstance(v, list)},
    }
    (OUT_DIR / "metrics.json").write_text(json.dumps(metrics_out, indent=2))
    print(f"Metrics saved to {OUT_DIR}/metrics.json")

    # --- Plot ---
    print("\nGenerating plots ...")
    plot_before_after_bar(base_metrics, ft_metrics)
    plot_field_accuracy(base_metrics, ft_metrics)
    plot_calorie_scatter(base_metrics, ft_metrics)
    plot_food_type_pie(base_metrics, ft_metrics)

    print(f"\nAll plots saved to {OUT_DIR}/")


if __name__ == "__main__":
    main()

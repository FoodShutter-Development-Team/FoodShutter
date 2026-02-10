"""
Compare base model vs fine-tuned model (with LoRA adapter) on a food image.
Usage:
    python compare.py                          # random sample from test set
    python compare.py path/to/image.jpg        # specific image
Results are auto-saved to compare_results/YYYY-MM-DD_HH-MM-SS.md
"""

import sys
import json
import random
import csv
import torch
import shutil
from datetime import datetime
from pathlib import Path
from PIL import Image
import warnings
warnings.filterwarnings("ignore", message=".*fast path is not available.*")
warnings.filterwarnings("ignore", message=".*flash-linear-attention.*")
from transformers import AutoModelForImageTextToText, AutoProcessor, BitsAndBytesConfig
from peft import PeftModel

MODEL_ID     = "models/Qwen3.5-9B"
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
    raise FileNotFoundError("No checkpoint found in output/. Train the model first.")

ADAPTER_PATH = find_latest_checkpoint()
IMAGES_DIR   = Path("mm_food_100k/images")
CSV_PATH     = Path("mm_food_100k/MM-Food-100K.csv")
MAX_NEW_TOKENS = 512
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

SYSTEM_MESSAGE = (
    "You are a professional food analysis assistant. "
    "When given a photo of food, analyze it and return a JSON object with the following fields: "
    "dish_name, food_type, cooking_method, ingredients (list), "
    "portion_size (list of 'item:weight'), and nutritional_profile "
    "(calories_kcal, protein_g, fat_g, carbohydrate_g). "
    "Output only valid JSON, no extra text."
)


def build_inputs(processor, image: Image.Image):
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
    return processor(text=prompt, images=image, return_tensors="pt").to(DEVICE)


def generate(model, inputs, processor):
    with torch.no_grad():
        output_ids = model.generate(
            **inputs,
            max_new_tokens=MAX_NEW_TOKENS,
            do_sample=False,
        )
    prompt_len = inputs["input_ids"].shape[1]
    return processor.tokenizer.decode(
        output_ids[0][prompt_len:], skip_special_tokens=True
    ).strip()


def pretty_json(text: str) -> str:
    try:
        return json.dumps(json.loads(text), indent=2, ensure_ascii=False)
    except Exception:
        return text


def save_markdown(img_path: Path, base_out: str, ft_out: str, gt: dict | None):
    out_dir = Path("compare_results")
    out_dir.mkdir(exist_ok=True)

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    md_path = out_dir / f"{timestamp}.md"
    img_dest = out_dir / f"{timestamp}_{img_path.name}"
    shutil.copy2(img_path, img_dest)

    lines = [
        f"# Comparison Report — {timestamp}",
        f"\n**Adapter:** `{ADAPTER_PATH}`",
        f"\n## Image\n",
        f"![food]({img_dest.name})\n",
        f"\n## Base Model Output\n```json\n{pretty_json(base_out)}\n```",
        f"\n## Fine-tuned Model Output\n```json\n{pretty_json(ft_out)}\n```",
    ]
    if gt:
        lines.append(f"\n## Ground Truth\n```json\n{json.dumps(gt, indent=2, ensure_ascii=False)}\n```")

    md_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"\nReport saved to: {md_path}")


def load_random_sample(split="test"):
    """Load a random sample from train or test split (same seed as fineTune.py)."""
    samples = []
    with open(CSV_PATH, encoding="utf-8") as f:
        for i, row in enumerate(csv.DictReader(f)):
            if i >= 10000:
                break
            url = row["image_url"].strip()
            filename = Path(url.split("/")[-1]).with_suffix(".jpg")
            img_path = IMAGES_DIR / filename
            if img_path.exists():
                samples.append((img_path, row))

    random.seed(42)
    random.shuffle(samples)
    cut = int(len(samples) * 0.9)
    split_samples = samples[cut:] if split == "test" else samples[:cut]
    img_path, row = random.choice(split_samples)
    return img_path, row


def main():
    # --- Load image ---
    if len(sys.argv) > 1:
        img_path = Path(sys.argv[1])
        ground_truth = None
    else:
        img_path, row = load_random_sample(split="test")
        ground_truth = row
        print(f"Sample image: {img_path.name}\n")

    image = Image.open(img_path).convert("RGB")

    print(f"Using adapter: {ADAPTER_PATH}\n")

    # --- Load processor (shared) ---
    print("Loading processor ...")
    processor = AutoProcessor.from_pretrained(MODEL_ID)
    processor.tokenizer.padding_side = "left"

    inputs = build_inputs(processor, image)

    # --- Base model ---
    print("Loading base model ...")
    bnb_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_use_double_quant=True,
        bnb_4bit_compute_dtype=torch.bfloat16,
    )
    base_model = AutoModelForImageTextToText.from_pretrained(
        MODEL_ID, device_map="auto", quantization_config=bnb_config
    )
    base_model.eval()
    print("Running base model inference ...")
    base_output = generate(base_model, inputs, processor)

    # --- Fine-tuned model ---
    print("Loading LoRA adapter ...")
    ft_model = PeftModel.from_pretrained(base_model, ADAPTER_PATH)
    ft_model.eval()
    print("Running fine-tuned model inference ...")
    ft_output = generate(ft_model, inputs, processor)

    gt = None
    if ground_truth:
        gt = {
            "dish_name": ground_truth.get("dish_name", ""),
            "food_type": ground_truth.get("food_type", ""),
            "cooking_method": ground_truth.get("cooking_method", ""),
            "ingredients": ground_truth.get("ingredients", ""),
            "portion_size": ground_truth.get("portion_size", ""),
            "nutritional_profile": ground_truth.get("nutritional_profile", ""),
        }

    # --- Print comparison ---
    print("\n" + "="*60)
    print("BASE MODEL OUTPUT:")
    print("="*60)
    print(pretty_json(base_output))

    print("\n" + "="*60)
    print("FINE-TUNED MODEL OUTPUT:")
    print("="*60)
    print(pretty_json(ft_output))

    if gt:
        print("\n" + "="*60)
        print("GROUND TRUTH:")
        print("="*60)
        print(json.dumps(gt, indent=2, ensure_ascii=False))
    print("="*60)

    # --- Save markdown ---
    save_markdown(img_path, base_output, ft_output, gt)


if __name__ == "__main__":
    main()

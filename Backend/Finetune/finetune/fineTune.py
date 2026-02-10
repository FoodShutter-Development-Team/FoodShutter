from datasets import load_dataset
from transformers import AutoModelForImageTextToText, AutoProcessor, BitsAndBytesConfig, logging as hf_logging
import torch
hf_logging.set_verbosity_warning()
import warnings
warnings.filterwarnings("ignore", message=".*fast path is not available.*")
warnings.filterwarnings("ignore", message=".*flash-linear-attention.*")
import os
os.environ["PYTORCH_ALLOC_CONF"] = "expandable_segments:True"
import json
from PIL import Image
from pathlib import Path
from peft import LoraConfig, get_peft_model
from trl import SFTConfig, SFTTrainer
from tqdm import tqdm

MODEL_ID = "models/Qwen3.5-9B"
DATASET_ID = "Codatta/MM-Food-100K"
# Local path to downloaded images (from download_dataset.py)
IMAGES_DIR = Path("mm_food_100k/images")

EPOCHS = 1
BATCH_SIZE = 4
GRAD_ACCUM_STEPS = 2  # effective batch size = 4 * 2 = 8
GRADIENT_CHECKPOINTING = True
USE_REENTRANT = False
OPTIM = "paged_adamw_32bit"
LEARNING_RATE = 2e-4
LOGGING_STEPS = 25
EVAL_STEPS = 100
SAVE_STEPS = 100
EVAL_STRATEGY = "steps"
SAVE_STRATEGY = "steps"
METRIC_FOR_BEST_MODEL="eval_loss"
LOAD_BEST_MODEL_AT_END=True
MAX_GRAD_NORM = 1
WARMUP_STEPS = 0
DATASET_KWARGS={"skip_prepare_dataset": True}
REMOVE_UNUSED_COLUMNS = False
MAX_SEQ_LEN = 1024
# Number of test samples used for before/after precision evaluation
EVAL_SAMPLES = 20
# Max new tokens to generate during evaluation inference
EVAL_MAX_NEW_TOKENS = 512
# Limit dataset size for training, set None to use all
MAX_SAMPLES = 10000


def build_answer(sample: dict) -> str:
    """Compose a structured JSON answer from dataset fields."""
    nutrition = sample.get("nutritional_profile", "{}")
    if isinstance(nutrition, str):
        try:
            nutrition = json.loads(nutrition)
        except Exception:
            nutrition = {}

    ingredients = sample.get("ingredients", "[]")
    if isinstance(ingredients, str):
        try:
            ingredients = json.loads(ingredients)
        except Exception:
            ingredients = []

    portion_size = sample.get("portion_size", "[]")
    if isinstance(portion_size, str):
        try:
            portion_size = json.loads(portion_size)
        except Exception:
            portion_size = []

    answer = {
        "dish_name": sample.get("dish_name", ""),
        "food_type": sample.get("food_type", ""),
        "cooking_method": sample.get("cooking_method", ""),
        "ingredients": ingredients,
        "portion_size": portion_size,
        "nutritional_profile": {
            "calories_kcal": nutrition.get("calories_kcal", 0),
            "protein_g": nutrition.get("protein_g", 0),
            "fat_g": nutrition.get("fat_g", 0),
            "carbohydrate_g": nutrition.get("carbohydrate_g", 0),
        },
    }
    return json.dumps(answer, ensure_ascii=False)


def load_image(sample: dict):
    """Load PIL image from local disk using the filename in image_url."""
    url = sample.get("image_url", "")
    filename = url.split("/")[-1]
    img_path = IMAGES_DIR / filename
    # Fallback to .jpg (download script normalizes all images to .jpg)
    if not img_path.exists():
        img_path = img_path.with_suffix(".jpg")
    return Image.open(img_path).convert("RGB")


def format_data(sample):
    system_message = (
        "You are a professional food analysis assistant. "
        "When given a photo of food, analyze it and return a JSON object with the following fields: "
        "dish_name, food_type, cooking_method, ingredients (list), "
        "portion_size (list of 'item:weight'), and nutritional_profile "
        "(calories_kcal, protein_g, fat_g, carbohydrate_g). "
        "Output only valid JSON, no extra text."
    )
    return [
        {
            "role": "system",
            "content": [{"type": "text", "text": system_message}],
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "image": load_image(sample),
                },
                {
                    "type": "text",
                    "text": "Analyze this food image and return the structured JSON.",
                },
            ],
        },
        {
            "role": "assistant",
            "content": [{"type": "text", "text": build_answer(sample)}],
        },
    ]


def load_ds(ds_id=DATASET_ID):
    import csv as _csv
    import random

    csv_path = IMAGES_DIR.parent / "MM-Food-100K.csv"

    def safe_format(s):
        url = s.get("image_url", "")
        filename = url.split("/")[-1]
        img_path = IMAGES_DIR / Path(filename).with_suffix(".jpg")
        if not img_path.exists():
            img_path = IMAGES_DIR / filename
        if not img_path.exists():
            return None
        try:
            return format_data(s)
        except Exception:
            return None

    # Load directly from local CSV to guarantee order matches downloaded images
    samples = []
    with open(csv_path, encoding="utf-8") as f:
        reader = _csv.DictReader(f)
        for row in reader:
            samples.append(row)
            if MAX_SAMPLES and len(samples) >= MAX_SAMPLES:
                break

    random.seed(42)
    random.shuffle(samples)
    split = int(len(samples) * 0.9)
    raw_train, raw_test = samples[:split], samples[split:]

    train_dataset = [r for r in (safe_format(s) for s in raw_train) if r is not None]
    test_dataset  = [r for r in (safe_format(s) for s in raw_test)  if r is not None]
    print("="*5 + f" Loaded {len(train_dataset)} training samples and {len(test_dataset)} test samples. " + "="*5)
    return train_dataset, test_dataset

def gen_process_branch(processor):
    def process_branch(branch):
        texts = [processor.apply_chat_template(sample, tokenize=False, enable_thinking=False) for sample in branch]
        images = [sample[1]["content"][0]["image"] for sample in branch]

        tokens = processor(
            text=texts,
            images=images,
            return_tensors="pt",
            padding=True,
        )

        input_ids = tokens["input_ids"]
        labels = input_ids.clone()

        # Mask pad tokens
        pad_id = processor.tokenizer.pad_token_id
        labels[labels == pad_id] = -100

        # Mask system + user turns: only train on assistant responses
        for i, sample in enumerate(branch):
            prompt_only = sample[:-1]  # exclude assistant turn
            prompt_text = processor.apply_chat_template(
                prompt_only, tokenize=False, add_generation_prompt=True, enable_thinking=False
            )
            prompt_ids = processor.tokenizer(
                prompt_text, return_tensors="pt", add_special_tokens=False
            )["input_ids"]
            prompt_len = prompt_ids.shape[1]
            labels[i, :prompt_len] = -100

        tokens["labels"] = labels
        return tokens
    return process_branch


def _edit_distance(a: str, b: str) -> int:
    """Standard dynamic-programming edit distance."""
    m, n = len(a), len(b)
    dp = list(range(n + 1))
    for i in range(1, m + 1):
        prev, dp[0] = dp[0], i
        for j in range(1, n + 1):
            temp = dp[j]
            dp[j] = prev if a[i-1] == b[j-1] else 1 + min(prev, dp[j], dp[j-1])
            prev = temp
    return dp[n]


EVAL_BATCH_SIZE = 2  # batch size for evaluation inference


def evaluate_model(model, processor, test_dataset, device, label=""):
    """
    Run batched greedy inference on EVAL_SAMPLES test examples and report:
      - Exact Match Rate  (EM)
      - Mean Normalized Edit Distance  (NED, higher = more similar)
    """
    model.eval()
    processor.tokenizer.padding_side = "left"  # required for batch generation
    subset = test_dataset[:EVAL_SAMPLES]

    exact_matches = 0
    ned_total = 0.0

    with torch.no_grad():
        for batch_start in tqdm(range(0, len(subset), EVAL_BATCH_SIZE), desc=f"Eval {label}"):
            batch = subset[batch_start: batch_start + EVAL_BATCH_SIZE]

            prompt_texts = [
                processor.apply_chat_template(
                    s[:-1], tokenize=False, add_generation_prompt=True, enable_thinking=False
                )
                for s in batch
            ]
            images = [s[1]["content"][0]["image"] for s in batch]
            ground_truths = [s[2]["content"][0]["text"].strip() for s in batch]

            inputs = processor(
                text=prompt_texts,
                images=images,
                return_tensors="pt",
                padding=True,
            ).to(device)

            output_ids = model.generate(
                **inputs,
                max_new_tokens=EVAL_MAX_NEW_TOKENS,
                do_sample=False,
            )

            prompt_len = inputs["input_ids"].shape[1]
            for i, gt in enumerate(ground_truths):
                generated = processor.tokenizer.decode(
                    output_ids[i][prompt_len:],
                    skip_special_tokens=True,
                ).strip()

                if generated == gt:
                    exact_matches += 1
                max_len = max(len(generated), len(gt), 1)
                ned_total += 1.0 - _edit_distance(generated, gt) / max_len

    em = exact_matches / len(subset) * 100
    ned = ned_total / len(subset) * 100
    tag = f"[{label}] " if label else ""
    print(
        f"{'='*5} {tag}Evaluation on {len(subset)} samples: "
        f"Exact Match = {em:.2f}%  |  "
        f"Normalized Edit Similarity = {ned:.2f}% {'='*5}"
    )
    processor.tokenizer.padding_side = "right"  # restore for training
    model.train()
    return {"exact_match": em, "ned": ned}


def train(model_id, ds_id, device, resume_from=None):
    # load model
    if device == "cuda":
        bnb_config = BitsAndBytesConfig(
            load_in_4bit=True,
            bnb_4bit_quant_type="nf4",
            bnb_4bit_use_double_quant=True,
            bnb_4bit_compute_dtype=torch.bfloat16,
        )
        model = AutoModelForImageTextToText.from_pretrained(
            model_id,
            device_map="auto",
            quantization_config=bnb_config,
        )
    else:
        model = AutoModelForImageTextToText.from_pretrained(
            model_id,
            device_map="auto",
        )

    processor = AutoProcessor.from_pretrained(model_id)
    processor.tokenizer.padding_side = "right"

    # load dataset
    train_dataset, test_dataset = load_ds(ds_id)

    # lora
    peft_config = LoraConfig(
        r=16,
        lora_alpha=32,
        lora_dropout=0.1,
        bias="none",
        task_type="CAUSAL_LM",
        target_modules=["q_proj", "v_proj"]
    )
    print("="*5 + f" Before LoRA parameters: {model.num_parameters()}")
    peft_model = get_peft_model(model, peft_config)
    peft_model.print_trainable_parameters()

    # Evaluate BEFORE fine-tuning
    before_metrics = evaluate_model(peft_model, processor, test_dataset, device, label="Before fine-tuning")

    # SFT Trainer
    sft_config = SFTConfig(
        output_dir="./output",
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=GRAD_ACCUM_STEPS,
        gradient_checkpointing=GRADIENT_CHECKPOINTING,
        gradient_checkpointing_kwargs={"use_reentrant": USE_REENTRANT},
        learning_rate=LEARNING_RATE,
        logging_steps=LOGGING_STEPS,
        eval_steps=EVAL_STEPS,
        eval_strategy=EVAL_STRATEGY,
        save_strategy=SAVE_STRATEGY,
        save_steps=SAVE_STEPS,
        metric_for_best_model=METRIC_FOR_BEST_MODEL,
        load_best_model_at_end=LOAD_BEST_MODEL_AT_END,
        max_grad_norm=MAX_GRAD_NORM,
        warmup_steps=WARMUP_STEPS,
        dataset_kwargs=DATASET_KWARGS,
        max_length=MAX_SEQ_LEN,
        remove_unused_columns=REMOVE_UNUSED_COLUMNS,
        optim=OPTIM,
        bf16=True,
        dataloader_num_workers=0,
        dataloader_pin_memory=False,
    )

    process_branch = gen_process_branch(processor)

    trainer = SFTTrainer(
        model=peft_model,
        args=sft_config,
        train_dataset=train_dataset,
        eval_dataset=test_dataset,
        data_collator=process_branch,
        processing_class=processor,
    )

    print("="*5 + " Start training " + "="*5)
    trainer.train(resume_from_checkpoint=resume_from)
    trainer.save_model("./output/res")
    print("="*5 + " Training completed " + "="*5)

    # Evaluate AFTER fine-tuning
    after_metrics = evaluate_model(peft_model, processor, test_dataset, device, label="After fine-tuning")

    # Print comparison summary
    print("\n" + "="*50)
    print(" Fine-tuning impact summary")
    print("="*50)
    print(f"  Exact Match:              {before_metrics['exact_match']:6.2f}%  ->  {after_metrics['exact_match']:6.2f}%  "
          f"(+{after_metrics['exact_match'] - before_metrics['exact_match']:.2f}%)")
    print(f"  Normalized Edit Sim.:     {before_metrics['ned']:6.2f}%  ->  {after_metrics['ned']:6.2f}%  "
          f"(+{after_metrics['ned'] - before_metrics['ned']:.2f}%)")
    print("="*50 + "\n")


if __name__ == "__main__":
    import sys
    resume = sys.argv[1] if len(sys.argv) > 1 else None
    train(MODEL_ID, DATASET_ID, "cuda" if torch.cuda.is_available() else "cpu", resume_from=resume)

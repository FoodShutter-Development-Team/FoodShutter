"""
MM-Food-100K Dataset Downloader
Downloads the CSV metadata and all food images to ./mm_food_100k/
"""

import csv
import os
import time
import requests
from io import BytesIO
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from PIL import Image
Image.MAX_IMAGE_PIXELS = None  # disable decompression bomb check (we resize immediately)

CSV_URL = "https://huggingface.co/datasets/Codatta/MM-Food-100K/resolve/main/MM-Food-100K.csv"
DATASET_DIR = Path("mm_food_100k")
IMAGES_DIR = DATASET_DIR / "images"
CSV_LOCAL = DATASET_DIR / "MM-Food-100K.csv"

# Limit total images to download, set None to download all 100K
MAX_SAMPLES = 10000
# Concurrent download workers (increase if bandwidth allows)
MAX_WORKERS = 16
# Retry attempts per image
MAX_RETRIES = 3
# Request timeout in seconds
TIMEOUT = 30
# Resize images to fit within this box (longest edge), set None to disable
MAX_IMAGE_SIZE = 1024
# JPEG save quality after resize (1-95)
IMAGE_QUALITY = 85


def compress_and_save(data: bytes, dest: Path):
    """Resize to MAX_IMAGE_SIZE and save as JPEG. Falls back to raw save on error."""
    dest = dest.with_suffix(".jpg")
    tmp = dest.with_suffix(".tmp")
    try:
        if MAX_IMAGE_SIZE is None:
            tmp.write_bytes(data)
        else:
            img = Image.open(BytesIO(data)).convert("RGB")
            img.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.LANCZOS)
            img.save(tmp, format="JPEG", quality=IMAGE_QUALITY, optimize=True)
        tmp.replace(dest)  # atomic rename: only marks complete when fully written
    except Exception:
        tmp.unlink(missing_ok=True)  # delete incomplete temp file
        raise


def download_file(url: str, dest: Path, retries: int = MAX_RETRIES) -> bool:
    # Check both original path and the .jpg variant (in case of prior compress)
    if dest.exists() or dest.with_suffix(".jpg").exists():
        return True
    for attempt in range(retries):
        try:
            r = requests.get(url, timeout=TIMEOUT)
            r.raise_for_status()
            compress_and_save(r.content, dest)
            return True
        except Exception:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                return False
    return False


def download_csv():
    if CSV_LOCAL.exists():
        print(f"[skip] CSV already exists: {CSV_LOCAL}")
        return
    print(f"Downloading CSV metadata ...")
    ok = download_file(CSV_URL, CSV_LOCAL)
    if ok:
        print(f"[ok] CSV saved to {CSV_LOCAL}")
    else:
        raise RuntimeError("Failed to download CSV. Check your network connection.")


def load_image_urls() -> list[tuple[str, Path]]:
    tasks = []
    with open(CSV_LOCAL, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            url = row["image_url"].strip()
            if not url:
                continue
            filename = url.split("/")[-1]
            dest = IMAGES_DIR / filename
            tasks.append((url, dest))
            if MAX_SAMPLES and len(tasks) >= MAX_SAMPLES:
                break
    return tasks


def download_images(tasks: list[tuple[str, Path]]):
    total = len(tasks)
    pending = [(url, dest) for url, dest in tasks
               if not dest.exists() and not dest.with_suffix(".jpg").exists()]
    skipped = total - len(pending)

    if skipped:
        print(f"[skip] {skipped} images already downloaded, {len(pending)} remaining.")

    if not pending:
        print("All images already downloaded.")
        return

    success = skipped
    failed = []

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_url = {
            executor.submit(download_file, url, dest): url
            for url, dest in pending
        }
        for i, future in enumerate(as_completed(future_to_url), 1):
            url = future_to_url[future]
            ok = future.result()
            if ok:
                success += 1
            else:
                failed.append(url)
            if i % 500 == 0 or i == len(pending):
                print(f"  Progress: {i}/{len(pending)}  |  total ok: {success}/{total}  |  failed: {len(failed)}")

    print(f"\nDownload complete: {success}/{total} succeeded, {len(failed)} failed.")

    if failed:
        failed_log = DATASET_DIR / "failed_urls.txt"
        failed_log.write_text("\n".join(failed))
        print(f"Failed URLs saved to {failed_log}")


def main():
    DATASET_DIR.mkdir(exist_ok=True)
    IMAGES_DIR.mkdir(exist_ok=True)

    # Step 1: download CSV
    download_csv()

    # Step 2: parse image URLs
    print("Parsing image URLs from CSV ...")
    tasks = load_image_urls()
    print(f"Found {len(tasks)} images total.")

    # Step 3: download images
    download_images(tasks)


if __name__ == "__main__":
    main()

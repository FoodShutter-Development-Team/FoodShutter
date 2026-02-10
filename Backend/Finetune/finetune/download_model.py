"""
Model Downloader
Downloads the model and processor to ./models/<model_name>/
"""

from huggingface_hub import snapshot_download

MODEL_ID = "Qwen/Qwen3.5-9B"
# Set to a local path to save outside HuggingFace cache (recommended for servers)
# Set to None to use the default ~/.cache/huggingface/hub/ cache
LOCAL_DIR = f"models/{MODEL_ID.split('/')[-1]}"


def main():
    print(f"Downloading model: {MODEL_ID}")
    print(f"Saving to: {LOCAL_DIR if LOCAL_DIR else '~/.cache/huggingface/hub'}\n")

    path = snapshot_download(
        repo_id=MODEL_ID,
        local_dir=LOCAL_DIR or None,
        ignore_patterns=["*.msgpack", "*.h5", "flax_model*", "tf_model*"],
    )

    print(f"\nModel saved to: {path}")
    if LOCAL_DIR:
        print(f"\nTo use locally in fineTune.py, set:")
        print(f'  MODEL_ID = "{LOCAL_DIR}"')


if __name__ == "__main__":
    main()

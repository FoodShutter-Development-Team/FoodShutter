"""Build ChromaDB from cleaned USDA Foundation Foods data.

Usage:
    python nutrition_db/build_db.py

Prerequisites:
    Run nutrition_db/clean_data.py first to generate foundation_foods_cleaned.json.
"""

import json
import sys
import time
from pathlib import Path

CLEANED_FILE = Path(__file__).parent / "data" / "foundation_foods_cleaned.json"
DB_PATH = str(Path(__file__).parent / "chroma_db")
COLLECTION = "nutrition"
BATCH_SIZE = 512


def main() -> None:
    if not CLEANED_FILE.exists():
        print(f"Cleaned data not found: {CLEANED_FILE}")
        print("Run: python nutrition_db/clean_data.py")
        sys.exit(1)

    with open(CLEANED_FILE, encoding="utf-8") as f:
        records = json.load(f)
    print(f"Loaded {len(records)} records")

    print("Loading BAAI/bge-small-en-v1.5 ...")
    from sentence_transformers import SentenceTransformer
    import chromadb

    model = SentenceTransformer("BAAI/bge-small-en-v1.5")

    client = chromadb.PersistentClient(path=DB_PATH)
    try:
        client.delete_collection(COLLECTION)
        print("Dropped existing collection")
    except Exception:
        pass
    col = client.create_collection(COLLECTION, metadata={"hnsw:space": "cosine"})

    t0 = time.time()
    for i in range(0, len(records), BATCH_SIZE):
        batch = records[i : i + BATCH_SIZE]
        names = [r["name"] for r in batch]
        vecs = model.encode(names, show_progress_bar=False).tolist()
        ids = [str(r["fdc_id"]) for r in batch]
        metas = [
            {
                "fdc_id": r["fdc_id"],
                "protein_g": r["protein_g"],
                "fat_g": r["fat_g"],
                "carb_g": r["carb_g"],
            }
            for r in batch
        ]
        col.add(ids=ids, embeddings=vecs, documents=names, metadatas=metas)
        print(f"  {min(i + BATCH_SIZE, len(records))}/{len(records)}")

    elapsed = time.time() - t0
    print(f"\nDone: {col.count()} vectors in {DB_PATH} ({elapsed:.1f}s)")


if __name__ == "__main__":
    main()

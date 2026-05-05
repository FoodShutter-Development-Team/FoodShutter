"""Nutrition vector DB query interface using ChromaDB + bge-small-en-v1.5."""

from pathlib import Path


class NutritionVectorDB:
    """ChromaDB-backed nutrition database with semantic and exact search."""

    def __init__(self, db_path: str | None = None):
        if db_path is None:
            db_path = str(Path(__file__).parent / "chroma_db")
        self.db_path = db_path
        self.available = False

        if not Path(db_path).exists():
            return

        try:
            import chromadb
            from sentence_transformers import SentenceTransformer

            self._model = SentenceTransformer(
                "BAAI/bge-small-en-v1.5", local_files_only=True
            )
            self._client = chromadb.PersistentClient(path=db_path)
            self._col = self._client.get_collection("nutrition")
            self.available = True
        except Exception:
            pass

    def search(
        self,
        query: str,
        top_k: int = 5,
        mode: str = "semantic",
    ) -> list[dict]:
        """
        Search for nutrition data by ingredient name.

        mode: "semantic" | "exact" | "hybrid"
        Returns list of dicts with name/score/protein_g/fat_g/carb_g/fdc_id.
        """
        if not self.available:
            return []
        if mode == "exact":
            return self._exact_search(query, top_k)
        if mode == "hybrid":
            exact = self._exact_search(query, top_k)
            if len(exact) >= top_k:
                return exact[:top_k]
            seen = {r["name"] for r in exact}
            for r in self._semantic_search(query, top_k):
                if r["name"] not in seen:
                    exact.append(r)
                    seen.add(r["name"])
                if len(exact) >= top_k:
                    break
            return exact[:top_k]
        return self._semantic_search(query, top_k)

    def _semantic_search(self, query: str, top_k: int) -> list[dict]:
        vec = self._model.encode(query).tolist()
        res = self._col.query(query_embeddings=[vec], n_results=top_k)
        out = []
        for i, name in enumerate(res["documents"][0]):
            meta = res["metadatas"][0][i]
            dist = res["distances"][0][i]
            out.append({
                "name": name,
                "score": round(max(0.0, 1.0 - dist), 4),
                "protein_g": meta.get("protein_g", 0),
                "fat_g": meta.get("fat_g", 0),
                "carb_g": meta.get("carb_g", 0),
                "fdc_id": meta.get("fdc_id"),
            })
        return out

    def _exact_search(self, query: str, top_k: int) -> list[dict]:
        q = query.lower()
        try:
            res = self._col.get(where_document={"$contains": q})
        except Exception:
            return []

        def _score(name: str) -> int:
            n = name.lower()
            if n == q:
                return 3
            if n.startswith(q):
                return 2
            return 1

        items = sorted(
            zip(res["documents"], res["metadatas"]),
            key=lambda x: _score(x[0]),
            reverse=True,
        )
        out = []
        for name, meta in items[:top_k]:
            out.append({
                "name": name,
                "score": round(_score(name) / 3.0, 4),
                "protein_g": meta.get("protein_g", 0),
                "fat_g": meta.get("fat_g", 0),
                "carb_g": meta.get("carb_g", 0),
                "fdc_id": meta.get("fdc_id"),
            })
        return out

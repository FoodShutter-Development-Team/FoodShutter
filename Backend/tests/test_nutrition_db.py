"""Tests for nutrition_db/nutrition_db.py — mocked ChromaDB and embedding model."""

import pytest
from unittest.mock import MagicMock, patch, PropertyMock
from nutrition_db.nutrition_db import NutritionVectorDB


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_db_with_mocked_internals(documents, metadatas, distances=None):
    """
    Return a NutritionVectorDB instance with available=True and mocked _col / _model.
    Avoids touching the filesystem or real ChromaDB.
    """
    db = NutritionVectorDB.__new__(NutritionVectorDB)
    db.db_path = "/fake/path"
    db.available = True

    mock_col = MagicMock()
    # _semantic_search: col.query returns {documents, metadatas, distances}
    dists = distances or [0.1] * len(documents)
    mock_col.query.return_value = {
        "documents": [documents],
        "metadatas": [metadatas],
        "distances": [dists],
    }
    # _exact_search: col.get returns {documents, metadatas}
    mock_col.get.return_value = {
        "documents": documents,
        "metadatas": metadatas,
    }

    mock_model = MagicMock()
    fake_vec = MagicMock()
    fake_vec.tolist.return_value = [0.1] * 384
    mock_model.encode.return_value = fake_vec

    db._col = mock_col
    db._model = mock_model
    return db


def _meta(protein=10.0, fat=5.0, carb=20.0, fdc_id=1001):
    return {"protein_g": protein, "fat_g": fat, "carb_g": carb, "fdc_id": fdc_id}


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

class TestInit:
    def test_unavailable_when_path_not_found(self, tmp_path):
        db = NutritionVectorDB(db_path=str(tmp_path / "nonexistent"))
        assert db.available is False

    def test_unavailable_when_import_fails(self, tmp_path):
        existing = tmp_path / "db"
        existing.mkdir()
        with patch.dict("sys.modules", {"chromadb": None}):
            db = NutritionVectorDB(db_path=str(existing))
        assert db.available is False

    def test_default_path_used_when_none(self):
        # Just check that it doesn't raise; path won't exist in test env
        db = NutritionVectorDB(db_path="/definitely/does/not/exist/xyz")
        assert db.available is False


# ---------------------------------------------------------------------------
# search() — unavailable DB
# ---------------------------------------------------------------------------

class TestSearchUnavailable:
    def setup_method(self):
        self.db = NutritionVectorDB.__new__(NutritionVectorDB)
        self.db.available = False

    def test_returns_empty_list_semantic(self):
        assert self.db.search("chicken") == []

    def test_returns_empty_list_exact(self):
        assert self.db.search("chicken", mode="exact") == []

    def test_returns_empty_list_hybrid(self):
        assert self.db.search("chicken", mode="hybrid") == []


# ---------------------------------------------------------------------------
# _semantic_search
# ---------------------------------------------------------------------------

class TestSemanticSearch:
    def test_returns_list_of_dicts(self):
        db = _make_db_with_mocked_internals(["chicken breast"], [_meta()], [0.05])
        results = db._semantic_search("chicken", top_k=1)
        assert len(results) == 1
        assert results[0]["name"] == "chicken breast"

    def test_score_is_one_minus_distance(self):
        db = _make_db_with_mocked_internals(["chicken breast"], [_meta()], [0.2])
        results = db._semantic_search("chicken", top_k=1)
        assert results[0]["score"] == pytest.approx(0.8)

    def test_score_clamped_at_zero_for_large_distance(self):
        db = _make_db_with_mocked_internals(["rare item"], [_meta()], [1.5])
        results = db._semantic_search("rare item", top_k=1)
        assert results[0]["score"] == 0.0

    def test_meta_fields_present(self):
        meta = _meta(protein=25.0, fat=3.5, carb=0.0, fdc_id=9999)
        db = _make_db_with_mocked_internals(["chicken breast"], [meta], [0.1])
        r = db._semantic_search("chicken", top_k=1)[0]
        assert r["protein_g"] == 25.0
        assert r["fat_g"] == 3.5
        assert r["carb_g"] == 0.0
        assert r["fdc_id"] == 9999

    def test_multiple_results(self):
        docs = ["chicken breast", "chicken thigh", "chicken wing"]
        metas = [_meta(), _meta(protein=20), _meta(fat=8)]
        dists = [0.05, 0.10, 0.15]
        db = _make_db_with_mocked_internals(docs, metas, dists)
        results = db._semantic_search("chicken", top_k=3)
        assert len(results) == 3
        # Ordered by distance (from query result)
        assert results[0]["name"] == "chicken breast"


# ---------------------------------------------------------------------------
# _exact_search — scoring and ranking
# ---------------------------------------------------------------------------

class TestExactSearch:
    def _db_with_docs(self, doc_names):
        metas = [_meta() for _ in doc_names]
        return _make_db_with_mocked_internals(doc_names, metas)

    def test_exact_match_scores_highest(self):
        db = self._db_with_docs(["chicken", "chicken breast", "fried chicken"])
        results = db._exact_search("chicken", top_k=3)
        assert results[0]["name"] == "chicken"
        assert results[0]["score"] == pytest.approx(3 / 3.0)  # score=1.0

    def test_startswith_scores_second(self):
        db = self._db_with_docs(["chicken breast", "fried chicken"])
        results = db._exact_search("chicken", top_k=2)
        names = [r["name"] for r in results]
        assert names[0] == "chicken breast"  # startswith("chicken")

    def test_contains_scores_lowest(self):
        db = self._db_with_docs(["fried chicken"])
        results = db._exact_search("chicken", top_k=1)
        # _exact_search rounds to 4 decimals: round(1/3, 4) = 0.3333
        assert results[0]["score"] == pytest.approx(round(1 / 3.0, 4))

    def test_returns_top_k(self):
        docs = [f"chicken item {i}" for i in range(10)]
        db = self._db_with_docs(docs)
        results = db._exact_search("chicken", top_k=3)
        assert len(results) <= 3

    def test_case_insensitive_scoring(self):
        db = self._db_with_docs(["Chicken"])  # capital C
        results = db._exact_search("chicken", top_k=1)
        # "Chicken".lower() == "chicken" → exact match → score 3/3
        assert results[0]["score"] == pytest.approx(1.0)

    def test_get_exception_returns_empty(self):
        db = _make_db_with_mocked_internals([], [])
        db._col.get.side_effect = Exception("DB error")
        results = db._exact_search("chicken", top_k=3)
        assert results == []


# ---------------------------------------------------------------------------
# search() — mode routing
# ---------------------------------------------------------------------------

class TestSearchModes:
    def setup_method(self):
        docs = ["chicken breast", "roasted chicken"]
        metas = [_meta(), _meta(protein=22)]
        dists = [0.05, 0.15]
        self.db = _make_db_with_mocked_internals(docs, metas, dists)

    def test_default_mode_is_semantic(self):
        self.db.search("chicken", top_k=2)
        self.db._model.encode.assert_called_once()

    def test_exact_mode_skips_embedding(self):
        self.db.search("chicken", mode="exact", top_k=2)
        self.db._model.encode.assert_not_called()

    def test_hybrid_uses_exact_first(self):
        # exact search fills top_k → semantic never called
        self.db._col.get.return_value = {
            "documents": ["chicken breast", "roasted chicken"],
            "metadatas": [_meta(), _meta()],
        }
        results = self.db.search("chicken", mode="hybrid", top_k=2)
        self.db._model.encode.assert_not_called()
        assert len(results) == 2

    def test_hybrid_falls_back_to_semantic_when_exact_insufficient(self):
        # exact search returns only 1 result, need top_k=3
        self.db._col.get.return_value = {
            "documents": ["chicken breast"],
            "metadatas": [_meta()],
        }
        results = self.db.search("chicken", mode="hybrid", top_k=3)
        # Semantic search fills the gap
        self.db._model.encode.assert_called_once()

    def test_hybrid_deduplicates_results(self):
        # Both exact and semantic return "chicken breast"
        self.db._col.get.return_value = {
            "documents": ["chicken breast"],
            "metadatas": [_meta()],
        }
        results = self.db.search("chicken", mode="hybrid", top_k=3)
        names = [r["name"] for r in results]
        assert len(names) == len(set(names))  # no duplicates

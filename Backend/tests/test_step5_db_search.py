"""Tests for pipeline/step5_db_search.py — mocked nutrition DB."""

import pytest
from unittest.mock import MagicMock, patch
import pipeline.step5_db_search as s5


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_db(available=True, search_results=None):
    db = MagicMock()
    db.available = available
    db.search.return_value = search_results or []
    return db


def _dish(bbox_id, ingredients, empty=False):
    return {
        "bbox_id": bbox_id,
        "empty": empty,
        "ingredients": [{"name": n} for n in ingredients],
    }


# ---------------------------------------------------------------------------
# set_shared_db
# ---------------------------------------------------------------------------

class TestSetSharedDb:
    def test_sets_global_db(self):
        fake_db = _make_db()
        s5.set_shared_db(fake_db)
        assert s5._shared_db is fake_db
        s5.set_shared_db(None)  # cleanup

    def test_set_none_clears_singleton(self):
        s5.set_shared_db(_make_db())
        s5.set_shared_db(None)
        assert s5._shared_db is None


# ---------------------------------------------------------------------------
# search_ingredients
# ---------------------------------------------------------------------------

class TestSearchIngredients:
    def setup_method(self):
        s5.set_shared_db(None)

    def teardown_method(self):
        s5.set_shared_db(None)

    def test_empty_step4_returns_empty_dict(self):
        assert s5.search_ingredients([]) == {}

    def test_empty_dishes_only_returns_empty_dict(self):
        result = s5.search_ingredients([_dish(1, ["rice"], empty=True)])
        assert result == {}

    def test_uses_shared_db_when_set(self):
        fake_candidates = [{"name": "rice", "score": 0.95}]
        db = _make_db(search_results=fake_candidates)
        s5.set_shared_db(db)
        result = s5.search_ingredients([_dish(1, ["rice"])])
        assert 1 in result
        assert result[1]["rice"] == fake_candidates

    def test_db_called_with_correct_ingredient_name(self):
        db = _make_db()
        s5.set_shared_db(db)
        s5.search_ingredients([_dish(1, ["chicken breast"])])
        db.search.assert_called_with("chicken breast", top_k=3)

    def test_unavailable_db_returns_empty_candidates(self):
        db = _make_db(available=False)
        s5.set_shared_db(db)
        result = s5.search_ingredients([_dish(1, ["rice"])])
        assert result[1]["rice"] == []

    def test_multiple_ingredients_per_dish(self):
        fake_candidates = [{"name": "x", "score": 0.8}]
        db = _make_db(search_results=fake_candidates)
        s5.set_shared_db(db)
        result = s5.search_ingredients([_dish(1, ["rice", "chicken", "broccoli"])])
        assert set(result[1].keys()) == {"rice", "chicken", "broccoli"}

    def test_multiple_dishes_keyed_by_bbox_id(self):
        db = _make_db(search_results=[])
        s5.set_shared_db(db)
        result = s5.search_ingredients([
            _dish(1, ["rice"]),
            _dish(2, ["chicken"]),
        ])
        assert 1 in result
        assert 2 in result

    def test_dish_with_no_ingredients_returns_empty_dict(self):
        db = _make_db()
        s5.set_shared_db(db)
        result = s5.search_ingredients([_dish(1, [])])
        assert result[1] == {}

    def test_falls_back_to_creating_db_when_no_shared(self):
        # When no shared DB and NutritionVectorDB fails to import, still returns results
        with patch.dict("sys.modules", {"nutrition_db.nutrition_db": None}):
            # Should not raise even if DB is unavailable
            result = s5.search_ingredients([_dish(1, ["rice"])], db_path="/nonexistent")
        assert 1 in result
        assert result[1]["rice"] == []

    def test_none_db_results_in_empty_candidates(self):
        # No shared DB, NutritionVectorDB constructor raises
        with patch("pipeline.step5_db_search._shared_db", None), \
             patch("pipeline.step5_db_search.NutritionVectorDB", side_effect=Exception("no db"), create=True):
            result = s5.search_ingredients([_dish(1, ["rice"])], db_path="/nonexistent")
        assert result[1]["rice"] == []

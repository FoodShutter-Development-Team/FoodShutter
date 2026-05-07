"""Tests for pipeline/step7_assembly.py — pure logic, no mocking needed."""

import pytest
from pipeline.step7_assembly import _overall_confidence, assemble_result


# ---------------------------------------------------------------------------
# _overall_confidence
# ---------------------------------------------------------------------------

class TestOverallConfidence:
    def test_empty_ingredients_returns_low(self):
        assert _overall_confidence([]) == "low"

    def test_all_high(self):
        ings = [{"confidence": "high"}, {"confidence": "high"}]
        assert _overall_confidence(ings) == "high"

    def test_all_medium(self):
        ings = [{"confidence": "medium"}, {"confidence": "medium"}]
        assert _overall_confidence(ings) == "medium"

    def test_all_low(self):
        assert _overall_confidence([{"confidence": "low"}]) == "low"

    def test_mixed_high_and_low_returns_low(self):
        ings = [{"confidence": "high"}, {"confidence": "low"}, {"confidence": "high"}]
        assert _overall_confidence(ings) == "low"

    def test_mixed_high_and_medium_returns_medium(self):
        ings = [{"confidence": "high"}, {"confidence": "medium"}]
        assert _overall_confidence(ings) == "medium"

    def test_mixed_medium_and_low_returns_low(self):
        ings = [{"confidence": "medium"}, {"confidence": "low"}]
        assert _overall_confidence(ings) == "low"

    def test_unknown_confidence_treated_as_low(self):
        assert _overall_confidence([{"confidence": "unknown"}]) == "low"

    def test_missing_confidence_key_treated_as_low(self):
        assert _overall_confidence([{"name": "chicken"}]) == "low"

    def test_single_high(self):
        assert _overall_confidence([{"confidence": "high"}]) == "high"


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

def _dish(bbox_id, label="Rice", empty=False, icon="🍚", container="bowl",
          portion="medium", grams=200, confidence="high"):
    return {
        "bbox_id": bbox_id,
        "empty": empty,
        "dish_name": label,
        "bbox": [0.1, 0.1, 0.5, 0.5],
        "icon": icon,
        "container": container,
        "portion_size": portion,
        "estimated_total_grams": grams,
        "confidence": confidence,
    }


def _s6(bbox_id, ingredients, dish_name="Rice"):
    return {"bbox_id": bbox_id, "dish_name": dish_name, "ingredients": ingredients}


def _ing(name, grams, protein_g, fat_g, carb_g, confidence="high"):
    return {
        "name": name, "grams": grams,
        "protein_g": protein_g, "fat_g": fat_g, "carb_g": carb_g,
        "confidence": confidence,
    }


# ---------------------------------------------------------------------------
# assemble_result
# ---------------------------------------------------------------------------

class TestAssembleResult:
    def test_empty_inputs(self):
        result = assemble_result([], [])
        assert result["dishes"] == []
        totals = result["image_totals"]
        assert totals["dish_count"] == 0
        assert totals["total_calories"] == 0.0

    def test_empty_dish_passthrough(self):
        result = assemble_result([_dish(1, empty=True)], [])
        assert len(result["dishes"]) == 1
        assert result["dishes"][0] == {"bbox_id": 1, "empty": True}
        assert result["image_totals"]["dish_count"] == 0

    def test_empty_dish_excluded_from_totals(self):
        ed = _dish(1, empty=True)
        nd = _dish(2, label="Chicken")
        ing = _ing("chicken", 100, 25, 5, 0)
        result = assemble_result([ed, nd], [_s6(2, [ing])])
        assert result["image_totals"]["dish_count"] == 1

    def test_calories_formula_protein_4_fat_9_carb_4(self):
        # 100 g ingredient: p=20, f=10, c=30 → cal = 20*4 + 10*9 + 30*4 = 290
        ing = _ing("x", 100, 20, 10, 30)
        result = assemble_result([_dish(1)], [_s6(1, [ing])])
        d = result["dishes"][0]
        assert d["total_protein_g"] == pytest.approx(20.0)
        assert d["total_fat_g"] == pytest.approx(10.0)
        assert d["total_carb_g"] == pytest.approx(30.0)
        assert d["total_calories"] == pytest.approx(290.0)

    def test_macro_scaled_by_grams(self):
        # 50 g of ingredient with 10g protein per 100g → 5 g protein
        ing = _ing("x", 50, 10, 0, 0)
        result = assemble_result([_dish(1)], [_s6(1, [ing])])
        assert result["dishes"][0]["total_protein_g"] == pytest.approx(5.0)

    def test_multi_ingredient_sum(self):
        # 100g @ p=20,f=5,c=0  +  200g @ p=4,f=1,c=30
        ing1 = _ing("chicken", 100, 20, 5, 0)
        ing2 = _ing("rice", 200, 4, 1, 30)
        result = assemble_result([_dish(1)], [_s6(1, [ing1, ing2])])
        d = result["dishes"][0]
        # protein: 20 + 4*2=8 = 28, fat: 5 + 1*2=2 = 7, carb: 0 + 30*2=60
        assert d["total_protein_g"] == pytest.approx(28.0, abs=0.1)
        assert d["total_fat_g"] == pytest.approx(7.0, abs=0.1)
        assert d["total_carb_g"] == pytest.approx(60.0, abs=0.1)

    def test_image_totals_sum_across_dishes(self):
        ing1 = _ing("chicken", 100, 20, 0, 0)
        ing2 = _ing("rice", 100, 5, 0, 30)
        result = assemble_result(
            [_dish(1, "Chicken"), _dish(2, "Rice")],
            [_s6(1, [ing1]), _s6(2, [ing2])]
        )
        totals = result["image_totals"]
        assert totals["total_protein_g"] == pytest.approx(25.0)
        assert totals["total_carb_g"] == pytest.approx(30.0)
        assert totals["dish_count"] == 2

    def test_missing_step6_entry_gives_zero_macros(self):
        result = assemble_result([_dish(1)], [])
        d = result["dishes"][0]
        assert d["total_calories"] == 0.0
        assert d["ingredients"] == []

    def test_step6_dish_name_preferred_over_step4(self):
        d = _dish(1, label="OldName")
        s6 = _s6(1, [], dish_name="NewName")
        result = assemble_result([d], [s6])
        assert result["dishes"][0]["dish_name"] == "NewName"

    def test_step4_dish_name_fallback_when_step6_empty_string(self):
        d = _dish(1, label="FallbackName")
        s6 = _s6(1, [], dish_name="")  # empty string is falsy
        result = assemble_result([d], [s6])
        assert result["dishes"][0]["dish_name"] == "FallbackName"

    def test_overall_confidence_from_ingredients(self):
        ing = _ing("x", 100, 10, 5, 20, confidence="low")
        result = assemble_result([_dish(1)], [_s6(1, [ing])])
        assert result["dishes"][0]["overall_confidence"] == "low"

    def test_step4_confidence_preserved(self):
        d = _dish(1, confidence="medium")
        result = assemble_result([d], [_s6(1, [])])
        assert result["dishes"][0]["step4_confidence"] == "medium"

    def test_values_rounded_to_one_decimal(self):
        # 100g @ p=1/3 per 100g → 0.333... → rounds to 0.3
        ing = _ing("x", 100, 1 / 3, 0, 0)
        result = assemble_result([_dish(1)], [_s6(1, [ing])])
        val = result["dishes"][0]["total_protein_g"]
        # Should be rounded to 1 decimal place
        assert val == round(val, 1)

    def test_none_grams_treated_as_zero(self):
        ing = {"name": "x", "grams": None, "protein_g": 20, "fat_g": 5, "carb_g": 30, "confidence": "high"}
        result = assemble_result([_dish(1)], [_s6(1, [ing])])
        assert result["dishes"][0]["total_calories"] == 0.0

    def test_bbox_and_icon_copied_from_step4(self):
        d = _dish(1, icon="🍜")
        result = assemble_result([d], [_s6(1, [])])
        out = result["dishes"][0]
        assert out["icon"] == "🍜"
        assert out["bbox"] == [0.1, 0.1, 0.5, 0.5]

    def test_empty_false_set_on_non_empty_dish(self):
        result = assemble_result([_dish(1)], [_s6(1, [])])
        assert result["dishes"][0]["empty"] is False

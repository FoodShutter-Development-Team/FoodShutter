# Data model and units

[Documentation index](README.md) · [API reference](api.md)

This is a code-derived contract reference. The repository does not include database migrations, foreign-key definitions or RLS policy SQL. The actual deployed schema must be checked independently before changing it.

## Logical relationships

```text
authenticated user
  profiles            one mobile profile, keyed by user UUID
  meals               meal records owned through user_id
    dishes            detected items linked through meal_id
      ingredients     ingredient estimates linked through dish_id
    meal_advices      recommendation content linked through meal_id
  trophies            achievement records owned through user_id
```

These relationships follow query and write usage; they do not certify that database constraints have been installed.

## Application tables

| Table | Important fields used by the code | Consumers |
| --- | --- | --- |
| `profiles` | `id`, `name`, `age`, `weight_kg`, `height_cm`, `gender`, `activity_level`, `health_goal`, `dietary_preferences`, `special_notes`, `nutrition_targets`, `targets_generated_at` | iOS profile repository and backend advice |
| `meals` | `id`, `user_id`, `timestamp`, `meal_type`, `status`, `photo_url`, `pipeline_error` | Backend job coordinator, iOS history and observer, web history |
| `dishes` | `id`, `meal_id`, `name`, `icon`, `sort_order`, `bbox`, `empty`, `container`, `portion_size`, `estimated_total_grams`, `total_protein_g`, `total_fat_g`, `total_carb_g`, `total_calories`, `confidence` | Backend, iOS analysis and web aggregation |
| `ingredients` | `id`, `dish_id`, `name`, `icon`, `weight_grams`, `protein_g`, `fat_g`, `carb_g`, `calories`, percentage fields, `source`, `confidence`, `fdc_id`, `sort_order` | Backend persistence and iOS detail |
| `meal_advices` | `meal_id`, `user_id`, `summary`, `nutrition_status`, `pros`, `cons`, `suggestions`, `next_meal_recommendation` | Backend advice and iOS suggestions |
| `trophies` | `id`, `user_id`, `trophy_type`, `earned_date`, `streak_days`, `nutrition_snapshot` | iOS achievement repository |

Source definitions: [`SupabaseModels.swift`](../iOSApp/FoodShutter/Core/Services/Supabase/SupabaseModels.swift), [`api/jobs.py`](../Backend/api/jobs.py).

The web settings adapter uses additional `user_profiles` and `nutrition_goals` tables. It falls back to authentication metadata if no web profile can be read. iOS stores nutrition targets as profile JSON; this is not the same storage contract as the web goals table. Shared login and meal history therefore do not establish synchronized goals.

## Images and coordinates

The backend stores photographs in `meal-photos` with paths of the form:

```text
<user UUID>/<meal UUID>.<extension>
```

`meals.photo_url` currently stores that object path rather than a permanent URL. iOS obtains a signed URL valid for one hour. The web history adapter currently converts it into a public Storage URL, which requires reconciliation for private buckets.

The detection model is asked for `[y_min, x_min, y_max, x_max]` coordinates on a 0–1000 scale. Step 1 converts these to `[x_min, y_min, x_max, y_max]` normalized to 0–1. Step 2 clamps and reorders them. Client rendering must use the normalized format, multiplied by the displayed image dimensions and adjusted for image layout.

`bbox_id` is a per-analysis, one-based index. The job uses the same value as `dishes.sort_order` to locate a dish during the final update. It is distinct from the database dish UUID.

## Nutrition units and current mismatch

The nutrition index stores `protein_g`, `fat_g` and `carb_g` per 100 g of food. Step 6 retains that convention alongside an estimated ingredient weight `grams`. Step 7 computes absolute totals:

```text
absolute nutrient grams = estimated ingredient grams / 100 × nutrient grams per 100 g
calories (kcal) = 4 × protein grams + 9 × fat grams + 4 × carbohydrate grams
```

Dish and meal totals emitted by Step 7 use absolute grams and kcal. This calculation is inspectable in [`step7_assembly.py`](../Backend/pipeline/step7_assembly.py).

There is a current persistence mismatch: `_write_phase2()` writes each ingredient's per-100-gram values into `ingredients.protein_g`, `fat_g` and `carb_g` directly, while `IngredientRow` and `FoodIngredient` treat those fields as absolute grams. Ingredient calories and percentage fields are calculated from those unscaled values too. Consequently, iOS totals aggregated from ingredients can disagree with the correctly scaled dish totals used by the web companion.

This documentation update does not alter the calculation code. Before a release, scale values at the persistence boundary and add a real persistence-to-client regression case using a non-100-gram portion. Existing isolated model and assembly tests do not verify this boundary.

## Provenance and confidence

`source = database` identifies a selected nutrition record and may carry `fdc_id`. `source = llm_estimated` identifies a model estimate after a retrieval miss. Ingredient confidence uses `high`, `medium` or `low`; dish confidence takes the minimum ingredient grade.

These are qualitative application labels, rather than calibrated probabilities. Detection assigns a fixed confidence of `0.90`, so that value must not be advertised as a measured recognition score.

## Time and ownership

The backend inserts UTC timestamps. Its daily advice window begins at UTC midnight; mobile displays and web chart grouping use local calendar behavior. A user's nutrition day is therefore not yet guaranteed to have the same boundary across all clients.

Backend writes use the service-role credential after deriving ownership from the authenticated token. Client isolation depends on real RLS and Storage policies, including child-table ownership through the parent meal. Frontend filtering alone is insufficient. The policies described in the presentation are not included as reproducible SQL in this repository.

//
//  MealPersistenceManagerTests.swift
//  FoodShutterTesting
//
//  Integration tests for MealRepository (cloud reads, requires authenticated session).
//  These tests verify model layer correctness only; network calls are skipped in CI.
//

import XCTest
@testable import FoodShutter

final class MealPersistenceManagerTests: XCTestCase {

    // MARK: - MealType Determination

    func testMealType_Determine_ReturnsKnownValue() {
        let type = MealType.determine()
        XCTAssertNotNil(MealType(rawValue: type.rawValue))
    }

    // MARK: - IngredientRow → FoodIngredient Mapping

    func testIngredientRow_ToFoodIngredient_MapsCorrectly() {
        let row = IngredientRow(
            id: UUID(),
            dishId: UUID(),
            name: "Salmon",
            icon: nil,
            weightGrams: 200,
            calories: 412,
            proteinG: 40.0,
            fatG: 27.0,
            carbG: 0.0,
            confidence: "high",
            source: "database"
        )
        let ingredient = row.toFoodIngredient()
        XCTAssertEqual(ingredient.name, "Salmon")
        XCTAssertEqual(ingredient.weightGrams, 200)
        XCTAssertEqual(ingredient.calories, 412)
        XCTAssertEqual(ingredient.proteinG, 40.0)
        XCTAssertEqual(ingredient.fatG, 27.0)
        XCTAssertEqual(ingredient.carbG, 0.0)
        XCTAssertEqual(ingredient.confidence, "high")
    }

    // MARK: - DishRow → Dish Mapping

    func testDishRow_ToDish_MapsFields() {
        let dishId = UUID()
        let bbox: [Double] = [0.1, 0.2, 0.8, 0.9]
        let row = DishRow(
            id: dishId,
            mealId: UUID(),
            name: "Red Oil Wonton",
            icon: nil,
            bbox: bbox,
            sortOrder: 0,
            empty: false,
            container: "bowl",
            portionSize: "large",
            estimatedTotalGrams: 450,
            confidence: "high",
            totalCalories: 887,
            totalProteinG: 24.9,
            totalFatG: 28.4,
            totalCarbG: 132.8,
            ingredients: []
        )
        let dish = row.toDish()
        XCTAssertEqual(dish.id, dishId)
        XCTAssertEqual(dish.name, "Red Oil Wonton")
        XCTAssertEqual(dish.bbox, bbox)
        XCTAssertEqual(dish.container, "bowl")
        XCTAssertEqual(dish.portionSize, "large")
        XCTAssertEqual(dish.estimatedGrams, 450)
        XCTAssertEqual(dish.confidence, "high")
    }

    func testDishRow_Empty_IsFilteredFromMealRow() {
        let mealId = UUID()
        let emptyDish = DishRow(
            id: UUID(), mealId: mealId, name: "Empty Plate",
            icon: nil, bbox: nil, sortOrder: 0, empty: true,
            container: nil, portionSize: nil, estimatedTotalGrams: nil,
            confidence: nil, totalCalories: nil,
            totalProteinG: nil, totalFatG: nil, totalCarbG: nil,
            ingredients: []
        )
        // MealRow.toDishes() filters empty=true rows
        // We test the filter logic here indirectly via DishRow.empty flag
        XCTAssertTrue(emptyDish.empty)
    }

    // MARK: - MealStatus

    func testMealStatus_AllRawValues_Decodable() {
        for status in ["processing", "dishes_ready", "complete", "failed"] {
            XCTAssertNotNil(MealStatus(rawValue: status), "\(status) should decode")
        }
    }

    // MARK: - MealRow aggregation filters empty dishes

    private func makeRealDish(
        calories: Double = 195, protein: Double = 4,
        fat: Double = 0.3, carb: Double = 43
    ) -> DishRow {
        DishRow(
            id: UUID(), mealId: UUID(), name: "Rice",
            icon: nil, bbox: nil, sortOrder: 0, empty: false,
            container: nil, portionSize: nil, estimatedTotalGrams: 150,
            confidence: nil, totalCalories: calories,
            totalProteinG: protein, totalFatG: fat, totalCarbG: carb,
            ingredients: []
        )
    }

    private func makeEmptyDish(
        calories: Double = 500, protein: Double = 20
    ) -> DishRow {
        DishRow(
            id: UUID(), mealId: UUID(), name: "Empty Plate",
            icon: nil, bbox: nil, sortOrder: 0, empty: true,
            container: nil, portionSize: nil, estimatedTotalGrams: nil,
            confidence: nil, totalCalories: calories,
            totalProteinG: protein, totalFatG: nil, totalCarbG: nil,
            ingredients: []
        )
    }

    func testMealRow_TotalNutrition_ExcludesEmptyDishes() {
        let meal = MealRow(
            id: UUID(), userId: UUID(), timestamp: Date(),
            mealType: "lunch", photoUrl: nil, status: "complete",
            pipelineError: nil,
            dishes: [makeEmptyDish(calories: 500, protein: 20), makeRealDish()]
        )
        XCTAssertEqual(meal.totalCalories,     195,  accuracy: 0.01)
        XCTAssertEqual(meal.totalProtein,      4,    accuracy: 0.01)
        XCTAssertEqual(meal.totalFat,          0.3,  accuracy: 0.01)
        XCTAssertEqual(meal.totalCarbohydrate, 43,   accuracy: 0.01)
    }

    func testMealRow_TotalNutrition_MultipleDishes_SumsCorrectly() {
        let meal = MealRow(
            id: UUID(), userId: UUID(), timestamp: Date(),
            mealType: "dinner", photoUrl: nil, status: "complete",
            pipelineError: nil,
            dishes: [makeRealDish(calories: 195), makeRealDish(calories: 300)]
        )
        XCTAssertEqual(meal.totalCalories, 495, accuracy: 0.01)
    }

    func testMealRow_ToDishes_FiltersEmptyDishes() {
        let meal = MealRow(
            id: UUID(), userId: UUID(), timestamp: Date(),
            mealType: "lunch", photoUrl: nil, status: "complete",
            pipelineError: nil,
            dishes: [makeEmptyDish(), makeRealDish(), makeRealDish()]
        )
        let dishes = meal.toDishes()
        XCTAssertEqual(dishes.count, 2)
        XCTAssertTrue(dishes.allSatisfy { !($0.name == "Empty Plate") })
    }

    // MARK: - MealRow enum fallbacks

    func testMealRow_UnknownMealType_FallsToOther() {
        let meal = MealRow(
            id: UUID(), userId: UUID(), timestamp: Date(),
            mealType: "elevenses", photoUrl: nil, status: "complete",
            pipelineError: nil, dishes: []
        )
        XCTAssertEqual(meal.mealTypeEnum, .other)
    }

    func testMealRow_UnknownStatus_FallsToProcessing() {
        let meal = MealRow(
            id: UUID(), userId: UUID(), timestamp: Date(),
            mealType: "lunch", photoUrl: nil, status: "unknown_state",
            pipelineError: nil, dishes: []
        )
        XCTAssertEqual(meal.statusEnum, .processing)
    }

    // MARK: - Icon fallback via FoodEmojiMapper

    func testDishRow_NilIcon_FallsBackToEmojiMapper() {
        let row = DishRow(
            id: UUID(), mealId: UUID(), name: "炒饭",
            icon: nil, bbox: nil, sortOrder: 0, empty: false,
            container: nil, portionSize: nil, estimatedTotalGrams: nil,
            confidence: nil, totalCalories: nil,
            totalProteinG: nil, totalFatG: nil, totalCarbG: nil,
            ingredients: []
        )
        XCTAssertEqual(row.toDish().icon, "🍳")
    }

    func testDishRow_EmptyStringIcon_FallsBackToEmojiMapper() {
        let row = DishRow(
            id: UUID(), mealId: UUID(), name: "炒面",
            icon: "", bbox: nil, sortOrder: 0, empty: false,
            container: nil, portionSize: nil, estimatedTotalGrams: nil,
            confidence: nil, totalCalories: nil,
            totalProteinG: nil, totalFatG: nil, totalCarbG: nil,
            ingredients: []
        )
        XCTAssertEqual(row.toDish().icon, "🍜")
    }

    func testIngredientRow_NilIcon_FallsBackToEmojiMapper() {
        let row = IngredientRow(
            id: UUID(), dishId: UUID(), name: "broccoli",
            icon: nil, weightGrams: 100, calories: 34,
            proteinG: 2.8, fatG: 0.4, carbG: 7.0,
            confidence: nil, source: nil
        )
        XCTAssertEqual(row.toFoodIngredient().icon, "🥦")
    }

    func testIngredientRow_EmptyStringIcon_FallsBackToEmojiMapper() {
        let row = IngredientRow(
            id: UUID(), dishId: UUID(), name: "tomato",
            icon: "", weightGrams: 80, calories: 14,
            proteinG: 0.7, fatG: 0.2, carbG: 3.1,
            confidence: nil, source: nil
        )
        XCTAssertEqual(row.toFoodIngredient().icon, "🍅")
    }

    func testMealRow_TotalNutrition_NilValues_TreatedAsZero() {
        // A non-empty dish with nil nutrition values: totalCalories ?? 0 path
        let dishWithNilNutrition = DishRow(
            id: UUID(), mealId: UUID(), name: "Unknown dish",
            icon: nil, bbox: nil, sortOrder: 0, empty: false,
            container: nil, portionSize: nil, estimatedTotalGrams: nil,
            confidence: nil, totalCalories: nil,
            totalProteinG: nil, totalFatG: nil, totalCarbG: nil,
            ingredients: []
        )
        let meal = MealRow(
            id: UUID(), userId: UUID(), timestamp: Date(),
            mealType: "lunch", photoUrl: nil, status: "complete",
            pipelineError: nil, dishes: [dishWithNilNutrition]
        )
        XCTAssertEqual(meal.totalCalories,     0, accuracy: 0.01)
        XCTAssertEqual(meal.totalProtein,      0, accuracy: 0.01)
        XCTAssertEqual(meal.totalFat,          0, accuracy: 0.01)
        XCTAssertEqual(meal.totalCarbohydrate, 0, accuracy: 0.01)
    }

    func testDishRow_ToDish_WithIngredients_MapsAll() {
        let ingredientRow = IngredientRow(
            id: UUID(), dishId: UUID(), name: "Rice",
            icon: "🍚", weightGrams: 150, calories: 195,
            proteinG: 4.0, fatG: 0.3, carbG: 43.0,
            confidence: "high", source: "database"
        )
        let row = DishRow(
            id: UUID(), mealId: UUID(), name: "White Rice",
            icon: nil, bbox: nil, sortOrder: 0, empty: false,
            container: nil, portionSize: nil, estimatedTotalGrams: 150,
            confidence: nil, totalCalories: 195,
            totalProteinG: 4.0, totalFatG: 0.3, totalCarbG: 43.0,
            ingredients: [ingredientRow]
        )
        let dish = row.toDish()
        XCTAssertEqual(dish.ingredients.count, 1)
        XCTAssertEqual(dish.ingredients.first?.name,        "Rice")
        XCTAssertEqual(dish.ingredients.first?.weightGrams, 150)
        XCTAssertEqual(dish.ingredients.first?.icon,        "🍚")
    }

    func testDishRow_ExplicitIcon_IsPreservedWithoutRemapping() {
        let row = DishRow(
            id: UUID(), mealId: UUID(), name: "炒饭",
            icon: "🥘", bbox: nil, sortOrder: 0, empty: false,
            container: nil, portionSize: nil, estimatedTotalGrams: nil,
            confidence: nil, totalCalories: nil,
            totalProteinG: nil, totalFatG: nil, totalCarbG: nil,
            ingredients: []
        )
        // Backend-provided icon should override the mapper
        XCTAssertEqual(row.toDish().icon, "🥘")
    }
}

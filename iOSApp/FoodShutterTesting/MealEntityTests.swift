//
//  MealEntityTests.swift
//  FoodShutterTesting
//
//  Tests for SupabaseModels decoding and computed aggregates.
//

import XCTest
@testable import FoodShutter

final class MealEntityTests: XCTestCase {

    // MARK: - MealType Tests

    func testMealType_RawValues_AreLowercase() {
        XCTAssertEqual(MealType.breakfast.rawValue, "breakfast")
        XCTAssertEqual(MealType.lunch.rawValue, "lunch")
        XCTAssertEqual(MealType.dinner.rawValue, "dinner")
        XCTAssertEqual(MealType.snack.rawValue, "snack")
        XCTAssertEqual(MealType.other.rawValue, "other")
    }

    func testMealType_Determine_ReturnsValidType() {
        let type = MealType.determine()
        XCTAssertTrue(MealType.allCases.contains(type))
    }

    // MARK: - MealStatus Tests

    func testMealStatus_RawValues() {
        XCTAssertEqual(MealStatus.processing.rawValue, "processing")
        XCTAssertEqual(MealStatus.dishesReady.rawValue, "dishes_ready")
        XCTAssertEqual(MealStatus.complete.rawValue, "complete")
        XCTAssertEqual(MealStatus.failed.rawValue, "failed")
    }

    func testMealStatus_Decode_UnknownFallsToProcessing() {
        let decoded = MealStatus(rawValue: "unknown")
        XCTAssertNil(decoded)
    }

    // MARK: - FoodIngredient Tests

    func testFoodIngredient_BackendModel_StoresAbsoluteGrams() {
        let ing = FoodIngredient(
            name: "Chicken",
            weightGrams: 150,
            calories: 234,
            proteinG: 46.5,
            fatG: 5.4,
            carbG: 0
        )
        XCTAssertEqual(ing.proteinWeight, 46.5)
        XCTAssertEqual(ing.fatWeight, 5.4)
        XCTAssertEqual(ing.carbohydrateWeight, 0)
        XCTAssertEqual(ing.calories, 234)
    }

    func testFoodIngredient_BarPercentages_SumToHundred() {
        let ing = FoodIngredient(
            name: "Mixed",
            weightGrams: 100,
            calories: 100,
            proteinG: 20,
            fatG: 10,
            carbG: 70
        )
        let total = ing.proteinPercent + ing.fatPercent + ing.carbohydratePercent
        XCTAssertEqual(total, 100.0, accuracy: 0.01)
    }

    // MARK: - Dish Aggregation

    func testDish_TotalCalories_SumsIngredients() {
        let ingredients = [
            FoodIngredient(name: "A", weightGrams: 100, calories: 200, proteinG: 10, fatG: 5, carbG: 30),
            FoodIngredient(name: "B", weightGrams: 50,  calories: 100, proteinG: 5,  fatG: 2, carbG: 15)
        ]
        let dish = Dish(name: "Test", ingredients: ingredients)
        XCTAssertEqual(dish.totalCalories, 300, accuracy: 0.01)
        XCTAssertEqual(dish.totalProtein, 15, accuracy: 0.01)
        XCTAssertEqual(dish.totalFat, 7, accuracy: 0.01)
        XCTAssertEqual(dish.totalCarbohydrate, 45, accuracy: 0.01)
    }

    // MARK: - NutritionSummaryData

    func testNutritionSummaryData_AggregatesCorrectly() {
        let ingredients = [
            FoodIngredient(name: "X", weightGrams: 200, calories: 300, proteinG: 30, fatG: 10, carbG: 40),
            FoodIngredient(name: "Y", weightGrams: 100, calories: 150, proteinG: 15, fatG: 5,  carbG: 20)
        ]
        let data = NutritionSummaryData(ingredients: ingredients)
        XCTAssertEqual(data.totalWeight, 300, accuracy: 0.01)
        XCTAssertEqual(data.totalCalories, 450, accuracy: 0.01)
        XCTAssertEqual(data.totalProtein, 45, accuracy: 0.01)
        XCTAssertEqual(data.totalFat, 15, accuracy: 0.01)
        XCTAssertEqual(data.totalCarbohydrate, 60, accuracy: 0.01)
    }

    func testNutritionSummaryData_EmptyIngredients_ZeroPercentages() {
        let data = NutritionSummaryData(ingredients: [])
        XCTAssertEqual(data.proteinPercent,      0)
        XCTAssertEqual(data.fatPercent,          0)
        XCTAssertEqual(data.carbohydratePercent, 0)
    }

    func testNutritionSummaryData_PercentagesSumToHundred() {
        let ingredients = [
            FoodIngredient(name: "A", weightGrams: 100, calories: 200, proteinG: 25, fatG: 10, carbG: 65)
        ]
        let data = NutritionSummaryData(ingredients: ingredients)
        let total = data.proteinPercent + data.fatPercent + data.carbohydratePercent
        XCTAssertEqual(total, 100.0, accuracy: 0.01)
    }

    // MARK: - MealType completeness

    func testMealType_AfternoonTea_RawValue() {
        XCTAssertEqual(MealType.afternoonTea.rawValue, "afternoon_tea")
    }

    func testMealType_AllCases_HaveNonEmptyRawValues() {
        for type in MealType.allCases {
            XCTAssertFalse(type.rawValue.isEmpty, "\(type) should have a non-empty rawValue")
        }
    }

    // MARK: - FoodIngredient edge cases

    func testFoodIngredient_ZeroMacros_AllPercentsAreZero() {
        let ing = FoodIngredient(
            name: "Water",
            weightGrams: 200,
            calories: 0,
            proteinG: 0,
            fatG: 0,
            carbG: 0
        )
        XCTAssertEqual(ing.proteinPercent,      0)
        XCTAssertEqual(ing.fatPercent,          0)
        XCTAssertEqual(ing.carbohydratePercent, 0)
    }

    func testFoodIngredient_FatAndCarbPercents_ComputedFromMacroRatio() {
        let ing = FoodIngredient(
            name: "Oil",
            weightGrams: 10,
            calories: 90,
            proteinG: 0,
            fatG: 10,
            carbG: 0
        )
        // pure fat → 100%
        XCTAssertEqual(ing.fatPercent,     100.0, accuracy: 0.01)
        XCTAssertEqual(ing.proteinPercent, 0)
        XCTAssertEqual(ing.carbohydratePercent, 0)
    }

    // MARK: - available aliases

    func testDish_Available_EqualsTotalMacros() {
        let ingredients = [
            FoodIngredient(name: "A", weightGrams: 100, calories: 200, proteinG: 10, fatG: 5, carbG: 30)
        ]
        let dish = Dish(name: "Test", ingredients: ingredients)
        XCTAssertEqual(dish.available, dish.totalProtein + dish.totalFat + dish.totalCarbohydrate, accuracy: 0.01)
    }

    func testFoodIngredient_Available_EqualsTotalMacros() {
        let ing = FoodIngredient(
            name: "Mixed", weightGrams: 100, calories: 200,
            proteinG: 20, fatG: 10, carbG: 70
        )
        XCTAssertEqual(ing.available, ing.proteinG + ing.fatG + ing.carbG, accuracy: 0.01)
    }

    // MARK: - FoodIngredient equality

    func testFoodIngredient_SameInstance_IsEqual() {
        let ing = FoodIngredient(name: "Chicken", weightGrams: 150, calories: 234, proteinG: 46.5, fatG: 5.4, carbG: 0)
        XCTAssertEqual(ing, ing)
    }

    func testFoodIngredient_DifferentIDs_AreNotEqual() {
        let a = FoodIngredient(name: "Chicken", weightGrams: 150, calories: 234, proteinG: 46.5, fatG: 5.4, carbG: 0)
        let b = FoodIngredient(name: "Chicken", weightGrams: 150, calories: 234, proteinG: 46.5, fatG: 5.4, carbG: 0)
        XCTAssertNotEqual(a, b)
    }

    func testFoodIngredient_SameID_IsEqual() {
        let id = UUID()
        let a = FoodIngredient(id: id, name: "Chicken", weightGrams: 150, calories: 234, proteinG: 46.5, fatG: 5.4, carbG: 0)
        let b = FoodIngredient(id: id, name: "Broccoli", weightGrams: 100, calories: 43, proteinG: 2.8, fatG: 0.4, carbG: 7)
        XCTAssertEqual(a, b)
    }
}

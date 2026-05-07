//
//  DishTests.swift
//  FoodShutterTesting
//

import XCTest
@testable import FoodShutter

final class DishTests: XCTestCase {

    var ingredient1: FoodIngredient!
    var ingredient2: FoodIngredient!
    var testDish: Dish!

    override func setUp() {
        super.setUp()
        // Chicken Breast: 150g, backend-style absolute grams
        ingredient1 = FoodIngredient(
            name: "Chicken Breast",
            icon: "🐔",
            weightGrams: 150,
            calories: 234,
            proteinG: 46.5,
            fatG: 5.4,
            carbG: 0
        )
        // Broccoli: 100g
        ingredient2 = FoodIngredient(
            name: "Broccoli",
            icon: "🥦",
            weightGrams: 100,
            calories: 43,
            proteinG: 2.8,
            fatG: 0.4,
            carbG: 7.0
        )
        testDish = Dish(
            name: "Healthy Bowl",
            icon: "🥗",
            ingredients: [ingredient1, ingredient2]
        )
    }

    override func tearDown() {
        testDish = nil
        ingredient1 = nil
        ingredient2 = nil
        super.tearDown()
    }

    func testTotalWeight_MultipleIngredients_SumsCorrectly() {
        XCTAssertEqual(testDish.totalWeight, 250, accuracy: 0.01)
    }

    func testTotalCalories_MultipleIngredients_SumsCorrectly() {
        // 234 + 43 = 277
        XCTAssertEqual(testDish.totalCalories, 277, accuracy: 1.0)
    }

    func testTotalProtein_MultipleIngredients_SumsCorrectly() {
        XCTAssertEqual(testDish.totalProtein, 49.3, accuracy: 0.01)
    }

    func testTotalFat_MultipleIngredients_SumsCorrectly() {
        XCTAssertEqual(testDish.totalFat, 5.8, accuracy: 0.01)
    }

    func testTotalCarbohydrate_MultipleIngredients_SumsCorrectly() {
        XCTAssertEqual(testDish.totalCarbohydrate, 7.0, accuracy: 0.01)
    }

    func testProteinPercent_ValidNutrients_CalculatesCorrectly() {
        // totalMacros = 49.3 + 5.8 + 7 = 62.1
        // proteinPercent = 49.3 / 62.1 * 100 ≈ 79.4
        XCTAssertEqual(testDish.proteinPercent, 79.4, accuracy: 0.5)
    }

    func testFatPercent_ValidNutrients_CalculatesCorrectly() {
        // fatPercent = 5.8 / 62.1 * 100 ≈ 9.3
        XCTAssertEqual(testDish.fatPercent, 9.3, accuracy: 0.5)
    }

    func testCarbohydratePercent_ValidNutrients_CalculatesCorrectly() {
        // carbPercent = 7 / 62.1 * 100 ≈ 11.3
        XCTAssertEqual(testDish.carbohydratePercent, 11.3, accuracy: 0.5)
    }

    func testNutritionPercent_ZeroNutrients_ReturnsZero() {
        let emptyDish = Dish(name: "Empty", ingredients: [])
        XCTAssertEqual(emptyDish.proteinPercent, 0)
        XCTAssertEqual(emptyDish.fatPercent, 0)
        XCTAssertEqual(emptyDish.carbohydratePercent, 0)
    }

    func testEquality_SameDishes_UsesUUID() {
        let dish1 = Dish(name: "Test", ingredients: [ingredient1])
        let dish2 = Dish(name: "Test", ingredients: [ingredient1])
        // Each Dish gets a unique UUID by default, so they are not equal
        XCTAssertNotEqual(dish1, dish2)
    }

    func testEquality_SameID_ReturnsTrue() {
        let id = UUID()
        let dish1 = Dish(id: id, name: "Test", ingredients: [ingredient1])
        let dish2 = Dish(id: id, name: "Test", ingredients: [ingredient1])
        XCTAssertEqual(dish1, dish2)
    }

    func testFoodIngredient_MacroPercentages_ComputedFromGrams() {
        // 46.5g protein out of 46.5+5.4+0 = 51.9g total macros → ~89.6%
        XCTAssertEqual(ingredient1.proteinPercent, 46.5 / 51.9 * 100, accuracy: 0.5)
    }

    func testFoodIngredient_WeightAlias() {
        XCTAssertEqual(ingredient1.weight, ingredient1.weightGrams)
    }
}

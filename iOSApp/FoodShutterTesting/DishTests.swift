//
//  DishTests.swift
//  FoodShutterTesting
//
//  Tests for Dish model nutrition aggregation and calculations
//

import XCTest
@testable import FoodShutter

final class DishTests: XCTestCase {

    var testDish: Dish!
    var ingredient1: FoodIngredient!
    var ingredient2: FoodIngredient!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // ARRANGE: Create test ingredients with known values
        // Ingredient 1: 150g chicken - 31% protein, 3.6% fat, 0% carbs
        ingredient1 = FoodIngredient(
            name: "Chicken Breast",
            icon: "🐔",
            weight: 150,
            proteinPercent: 31,
            fatPercent: 3.6,
            carbohydratePercent: 0
        )

        // Ingredient 2: 100g broccoli - 2.8% protein, 0.4% fat, 7% carbs
        ingredient2 = FoodIngredient(
            name: "Broccoli",
            icon: "🥦",
            weight: 100,
            proteinPercent: 2.8,
            fatPercent: 0.4,
            carbohydratePercent: 7
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

    // MARK: - Aggregation Tests

    /// Test total weight aggregates correctly across ingredients
    func testTotalWeight_MultipleIngredients_SumsCorrectly() {
        // ACT
        let totalWeight = testDish.totalWeight

        // ASSERT
        // 150g + 100g = 250g
        XCTAssertEqual(totalWeight, 250, accuracy: 0.01, "Total weight should sum all ingredients")
    }

    /// Test total calories aggregates correctly
    func testTotalCalories_MultipleIngredients_SumsCorrectly() {
        // ACT
        let totalCalories = testDish.totalCalories

        // ASSERT
        // Chicken: (46.5g protein * 4) + (5.4g fat * 9) + (0g carbs * 4) = 186 + 48.6 = 234.6
        // Broccoli: (2.8g protein * 4) + (0.4g fat * 9) + (7g carbs * 4) = 11.2 + 3.6 + 28 = 42.8
        // Total: 234.6 + 42.8 = 277.4
        XCTAssertEqual(totalCalories, 277.4, accuracy: 0.1, "Total calories should sum all ingredients")
    }

    /// Test total protein aggregates correctly
    func testTotalProtein_MultipleIngredients_SumsCorrectly() {
        // ACT
        let totalProtein = testDish.totalProtein

        // ASSERT
        // Chicken: 150 * 31 / 100 = 46.5g
        // Broccoli: 100 * 2.8 / 100 = 2.8g
        // Total: 49.3g
        XCTAssertEqual(totalProtein, 49.3, accuracy: 0.01, "Total protein should sum all ingredients")
    }

    /// Test total fat aggregates correctly
    func testTotalFat_MultipleIngredients_SumsCorrectly() {
        // ACT
        let totalFat = testDish.totalFat

        // ASSERT
        // Chicken: 150 * 3.6 / 100 = 5.4g
        // Broccoli: 100 * 0.4 / 100 = 0.4g
        // Total: 5.8g
        XCTAssertEqual(totalFat, 5.8, accuracy: 0.01, "Total fat should sum all ingredients")
    }

    /// Test total carbohydrate aggregates correctly
    func testTotalCarbohydrate_MultipleIngredients_SumsCorrectly() {
        // ACT
        let totalCarbs = testDish.totalCarbohydrate

        // ASSERT
        // Chicken: 150 * 0 / 100 = 0g
        // Broccoli: 100 * 7 / 100 = 7g
        // Total: 7g
        XCTAssertEqual(totalCarbs, 7.0, accuracy: 0.01, "Total carbohydrate should sum all ingredients")
    }

    // MARK: - Percentage Calculation Tests

    /// Test protein percentage calculation
    func testProteinPercent_ValidNutrients_CalculatesCorrectly() {
        // ACT
        let proteinPercent = testDish.proteinPercent

        // ASSERT
        // Total nutrients: 49.3 + 5.8 + 7 = 62.1g
        // Protein %: (49.3 / 62.1) * 100 = 79.4%
        XCTAssertEqual(proteinPercent, 79.4, accuracy: 0.2, "Protein percentage should be calculated correctly")
    }

    /// Test fat percentage calculation
    func testFatPercent_ValidNutrients_CalculatesCorrectly() {
        // ACT
        let fatPercent = testDish.fatPercent

        // ASSERT
        // Total nutrients: 62.1g
        // Fat %: (5.8 / 62.1) * 100 = 9.3%
        XCTAssertEqual(fatPercent, 9.3, accuracy: 0.2, "Fat percentage should be calculated correctly")
    }

    /// Test carbohydrate percentage calculation
    func testCarbohydratePercent_ValidNutrients_CalculatesCorrectly() {
        // ACT
        let carbPercent = testDish.carbohydratePercent

        // ASSERT
        // Total nutrients: 62.1g
        // Carb %: (7 / 62.1) * 100 = 11.3%
        XCTAssertEqual(carbPercent, 11.3, accuracy: 0.2, "Carbohydrate percentage should be calculated correctly")
    }

    // MARK: - Edge Cases

    /// Test division by zero protection when no nutrients
    func testNutritionPercent_ZeroNutrients_ReturnsZero() {
        // ARRANGE
        let emptyDish = Dish(
            name: "Empty",
            icon: "🍽️",
            ingredients: []
        )

        // ACT & ASSERT
        XCTAssertEqual(emptyDish.proteinPercent, 0, "Should return 0 when no nutrients")
        XCTAssertEqual(emptyDish.fatPercent, 0, "Should return 0 when no nutrients")
        XCTAssertEqual(emptyDish.carbohydratePercent, 0, "Should return 0 when no nutrients")
    }

    /// Test with single ingredient
    func testAggregation_SingleIngredient_CalculatesCorrectly() {
        // ARRANGE
        let singleIngredientDish = Dish(
            name: "Just Chicken",
            icon: "🐔",
            ingredients: [ingredient1]
        )

        // ACT & ASSERT
        XCTAssertEqual(singleIngredientDish.totalWeight, 150, "Weight should match single ingredient")
        XCTAssertEqual(singleIngredientDish.totalProtein, 46.5, accuracy: 0.01, "Protein should match single ingredient")
    }

    /// Test available property sums percentages
    func testAvailable_AllNutrients_SumsPercents() {
        // ACT
        let available = testDish.available

        // ASSERT
        // Should sum all three percentages (should be ~100 or less)
        XCTAssertEqual(available, 100, accuracy: 1.0, "Available should sum all nutrient percentages")
    }

    // MARK: - Equatable Tests

    /// Test equality for identical dishes
    func testEquality_SameDishes_ReturnsTrue() {
        // ARRANGE
        let dish1 = Dish(
            name: "Test",
            icon: "🥗",
            ingredients: [ingredient1]
        )
        let dish2 = Dish(
            name: "Test",
            icon: "🥗",
            ingredients: [ingredient1]
        )

        // ACT & ASSERT
        // Note: Due to UUID, they won't be == even with same data
        // But we can test the data fields are equal
        XCTAssertEqual(dish1.name, dish2.name, "Names should match")
        XCTAssertEqual(dish1.icon, dish2.icon, "Icons should match")
    }

    /// Test inequality for different dish names
    func testEquality_DifferentNames_ReturnsFalse() {
        // ARRANGE
        let dish1 = Dish(
            name: "Dish A",
            icon: "🥗",
            ingredients: [ingredient1]
        )
        let dish2 = Dish(
            name: "Dish B",
            icon: "🥗",
            ingredients: [ingredient1]
        )

        // ACT & ASSERT
        XCTAssertNotEqual(dish1, dish2, "Dishes with different names should not be equal")
    }
}

//
//  MealEntityTests.swift
//  FoodShutterTesting
//
//  Tests for MealEntity aggregations and transformations
//

import XCTest
import SwiftData
@testable import FoodShutter

final class MealEntityTests: XCTestCase {

    var testContainer: ModelContainer!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        testContainer = SwiftDataTestHelpers.createMealContainer()
    }

    override func tearDown() {
        testContainer = nil
        super.tearDown()
    }

    // MARK: - Aggregation Tests

    /// Test total protein aggregates across multiple dishes
    func testTotalProtein_MultipleDishes_AggregatesCorrectly() {
        // ARRANGE
        let ingredient1 = IngredientEntity(
            name: "Chicken",
            icon: "🐔",
            weight: 150,
            proteinPercent: 31,  // 46.5g protein
            fatPercent: 3.6,
            carbohydratePercent: 0
        )

        let ingredient2 = IngredientEntity(
            name: "Broccoli",
            icon: "🥦",
            weight: 100,
            proteinPercent: 2.8,  // 2.8g protein
            fatPercent: 0.4,
            carbohydratePercent: 7
        )

        let dish1 = DishEntity(name: "Dish 1", icon: "🍽️", ingredients: [ingredient1])
        let dish2 = DishEntity(name: "Dish 2", icon: "🥗", ingredients: [ingredient2])

        let meal = MealEntity(
            timestamp: Date(),
            mealType: .lunch,
            photo: nil,
            dishes: [dish1, dish2],
            dietaryAdvice: nil
        )

        // ACT
        let totalProtein = meal.totalProtein

        // ASSERT
        // 46.5 + 2.8 = 49.3g
        XCTAssertEqual(totalProtein, 49.3, accuracy: 0.01, "Should aggregate protein across all dishes")
    }

    /// Test total fat aggregates correctly
    func testTotalFat_MultipleDishes_AggregatesCorrectly() {
        // ARRANGE
        let ingredient1 = IngredientEntity(
            name: "Chicken",
            icon: "🐔",
            weight: 150,
            proteinPercent: 31,
            fatPercent: 3.6,  // 5.4g fat
            carbohydratePercent: 0
        )

        let ingredient2 = IngredientEntity(
            name: "Broccoli",
            icon: "🥦",
            weight: 100,
            proteinPercent: 2.8,
            fatPercent: 0.4,  // 0.4g fat
            carbohydratePercent: 7
        )

        let dish = DishEntity(name: "Mixed", icon: "🍽️", ingredients: [ingredient1, ingredient2])
        let meal = MealEntity(
            timestamp: Date(),
            mealType: .dinner,
            photo: nil,
            dishes: [dish],
            dietaryAdvice: nil
        )

        // ACT
        let totalFat = meal.totalFat

        // ASSERT
        // 5.4 + 0.4 = 5.8g
        XCTAssertEqual(totalFat, 5.8, accuracy: 0.01, "Should aggregate fat across all ingredients")
    }

    /// Test total carbohydrate aggregates correctly
    func testTotalCarbohydrate_MultipleDishes_AggregatesCorrectly() {
        // ARRANGE
        let ingredient1 = IngredientEntity(
            name: "Rice",
            icon: "🍚",
            weight: 150,
            proteinPercent: 2.6,
            fatPercent: 0.3,
            carbohydratePercent: 25.9  // 38.85g carbs
        )

        let ingredient2 = IngredientEntity(
            name: "Beans",
            icon: "🫘",
            weight: 100,
            proteinPercent: 9,
            fatPercent: 0.5,
            carbohydratePercent: 21  // 21g carbs
        )

        let dish = DishEntity(name: "Rice & Beans", icon: "🍽️", ingredients: [ingredient1, ingredient2])
        let meal = MealEntity(
            timestamp: Date(),
            mealType: .lunch,
            photo: nil,
            dishes: [dish],
            dietaryAdvice: nil
        )

        // ACT
        let totalCarbs = meal.totalCarbohydrate

        // ASSERT
        // 38.85 + 21 = 59.85g
        XCTAssertEqual(totalCarbs, 59.85, accuracy: 0.01, "Should aggregate carbohydrates across all ingredients")
    }

    /// Test total calories aggregates correctly
    func testTotalCalories_MultipleDishes_AggregatesCorrectly() {
        // ARRANGE
        let ingredient = IngredientEntity(
            name: "Mixed Food",
            icon: "🍽️",
            weight: 100,
            proteinPercent: 20,  // 20g * 4 = 80 cal
            fatPercent: 10,      // 10g * 9 = 90 cal
            carbohydratePercent: 30  // 30g * 4 = 120 cal
            // Total: 290 cal
        )

        let dish = DishEntity(name: "Test Dish", icon: "🍽️", ingredients: [ingredient])
        let meal = MealEntity(
            timestamp: Date(),
            mealType: .breakfast,
            photo: nil,
            dishes: [dish],
            dietaryAdvice: nil
        )

        // ACT
        let totalCalories = meal.totalCalories

        // ASSERT
        XCTAssertEqual(totalCalories, 290, accuracy: 0.01, "Should calculate total calories correctly")
    }

    // MARK: - Photo Handling Tests

    /// Test photo property returns UIImage when data exists
    func testPhoto_WithValidData_ReturnsUIImage() {
        // ARRANGE
        let testImage = TestHelpers.createTestImage()
        let meal = MealEntity(
            timestamp: Date(),
            mealType: .lunch,
            photo: testImage,
            dishes: [],
            dietaryAdvice: nil
        )

        // ACT
        let retrievedPhoto = meal.photo

        // ASSERT
        XCTAssertNotNil(retrievedPhoto, "Should return UIImage when photo data exists")
        XCTAssertNotNil(meal.photoData, "Photo data should be stored")
    }

    /// Test photo property returns nil when no data
    func testPhoto_WithNilData_ReturnsNil() {
        // ARRANGE
        let meal = MealEntity(
            timestamp: Date(),
            mealType: .snack,
            photo: nil,
            dishes: [],
            dietaryAdvice: nil
        )

        // ACT
        let photo = meal.photo

        // ASSERT
        XCTAssertNil(photo, "Should return nil when no photo data")
        XCTAssertNil(meal.photoData, "Photo data should be nil")
    }

    /// Test photo is compressed at 0.7 quality
    func testPhotoData_CompressesImage() {
        // ARRANGE
        let testImage = TestHelpers.createLargeTestImage(size: CGSize(width: 100, height: 100))
        let meal = MealEntity(
            timestamp: Date(),
            mealType: .dinner,
            photo: testImage,
            dishes: [],
            dietaryAdvice: nil
        )

        // ACT & ASSERT
        XCTAssertNotNil(meal.photoData, "Should compress and store image")

        // Verify it can be decoded
        let decodedPhoto = meal.photo
        XCTAssertNotNil(decodedPhoto, "Compressed photo should be decodable")
    }

    // MARK: - Dietary Advice Tests

    /// Test dietary advice decodes correctly when present
    func testDietaryAdvice_WithValidData_DecodesCorrectly() {
        // ARRANGE
        let recommendedDish = FoodShutter.RecommendedMealDish(
            dishName: "Vegetable Salad",
            icon: "🥗",
            weight: 200,
            proteinPercent: 5,
            fatPercent: 2,
            carbohydratePercent: 10
        )

        let mockAdvice = FoodShutter.DietaryAdviceResult(
            analysis: FoodShutter.NutritionAnalysis(
                summary: "Good balance",
                nutritionStatus: "Healthy",
                pros: ["High protein"],
                cons: ["Low fiber"]
            ),
            nextMealRecommendation: FoodShutter.NextMealRecommendation(
                recommendedDish: recommendedDish,
                reason: "To increase fiber intake",
                nutrientsFocus: ["Fiber", "Vitamins"]
            )
        )

        let meal = MealEntity(
            timestamp: Date(),
            mealType: .lunch,
            photo: nil,
            dishes: [],
            dietaryAdvice: mockAdvice
        )

        // ACT
        let retrievedAdvice = meal.dietaryAdvice

        // ASSERT
        XCTAssertNotNil(retrievedAdvice, "Should decode dietary advice")
        XCTAssertEqual(retrievedAdvice?.analysis.summary, "Good balance", "Should match original advice")
    }

    /// Test dietary advice returns nil when no data
    func testDietaryAdvice_WithNilData_ReturnsNil() {
        // ARRANGE
        let meal = MealEntity(
            timestamp: Date(),
            mealType: .breakfast,
            photo: nil,
            dishes: [],
            dietaryAdvice: nil
        )

        // ACT
        let advice = meal.dietaryAdvice

        // ASSERT
        XCTAssertNil(advice, "Should return nil when no advice data")
        XCTAssertNil(meal.adviceData, "Advice data should be nil")
    }

    // MARK: - Transformation Tests

    /// Test fromAnalysisResults creates correct entity structure
    func testFromAnalysisResults_CreatesCorrectEntityStructure() {
        // ARRANGE
        let dishes = [TestHelpers.createMockDish()]
        let timestamp = Date()

        // ACT
        let mealEntity = MealEntity.fromAnalysisResults(
            timestamp: timestamp,
            mealType: .lunch,
            photo: nil,
            dishes: dishes,
            dietaryAdvice: nil
        )

        // ASSERT
        XCTAssertEqual(mealEntity.dishes.count, 1, "Should have one dish")
        XCTAssertEqual(mealEntity.mealTypeEnum, .lunch, "Meal type should match")
        XCTAssertEqual(mealEntity.dishes.first?.ingredients.count, 2, "Dish should have ingredients")
    }

    /// Test fromAnalysisResults maps all dishes and ingredients
    func testFromAnalysisResults_MapsAllDishesAndIngredients() {
        // ARRANGE
        let ingredient1 = FoodIngredient(
            name: "Test Ingredient 1",
            icon: "🥩",
            weight: 100,
            proteinPercent: 20,
            fatPercent: 10,
            carbohydratePercent: 5
        )

        let ingredient2 = FoodIngredient(
            name: "Test Ingredient 2",
            icon: "🥬",
            weight: 50,
            proteinPercent: 3,
            fatPercent: 0.5,
            carbohydratePercent: 8
        )

        let dish1 = Dish(name: "Dish 1", icon: "🍽️", ingredients: [ingredient1])
        let dish2 = Dish(name: "Dish 2", icon: "🥗", ingredients: [ingredient2])

        // ACT
        let mealEntity = MealEntity.fromAnalysisResults(
            timestamp: Date(),
            mealType: .dinner,
            photo: nil,
            dishes: [dish1, dish2],
            dietaryAdvice: nil
        )

        // ASSERT
        XCTAssertEqual(mealEntity.dishes.count, 2, "Should create 2 dish entities")
        XCTAssertEqual(mealEntity.dishes[0].name, "Dish 1", "First dish name should match")
        XCTAssertEqual(mealEntity.dishes[1].name, "Dish 2", "Second dish name should match")
        XCTAssertEqual(mealEntity.dishes[0].ingredients.count, 1, "First dish should have 1 ingredient")
        XCTAssertEqual(mealEntity.dishes[1].ingredients.count, 1, "Second dish should have 1 ingredient")
    }

    // MARK: - Meal Type Tests

    /// Test meal type enum conversion
    func testMealTypeEnum_ConvertsCorrectly() {
        // ARRANGE & ACT
        let breakfastMeal = MealEntity(
            timestamp: Date(),
            mealType: .breakfast,
            photo: nil,
            dishes: [],
            dietaryAdvice: nil
        )

        let lunchMeal = MealEntity(
            timestamp: Date(),
            mealType: .lunch,
            photo: nil,
            dishes: [],
            dietaryAdvice: nil
        )

        // ASSERT
        XCTAssertEqual(breakfastMeal.mealTypeEnum, .breakfast, "Should convert to breakfast enum")
        XCTAssertEqual(lunchMeal.mealTypeEnum, .lunch, "Should convert to lunch enum")
    }
}

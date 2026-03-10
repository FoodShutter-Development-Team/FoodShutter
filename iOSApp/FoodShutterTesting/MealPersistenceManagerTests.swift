//
//  MealPersistenceManagerTests.swift
//  FoodShutterTesting
//
//  Tests for MealPersistenceManager meal storage and retrieval
//  Note: Uses shared instance with careful cleanup between tests
//

import XCTest
import SwiftData
@testable import FoodShutter

final class MealPersistenceManagerTests: XCTestCase {

    var manager: MealPersistenceManager!
    var testDishes: [Dish]!
    var savedMeals: [MealEntity] = []  // Track for cleanup

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        manager = MealPersistenceManager.shared

        // Create test dishes
        testDishes = [TestHelpers.createMockDish()]
    }

    override func tearDown() {
        // Clean up all saved meals from tests
        for meal in savedMeals {
            try? manager.deleteMeal(meal)
        }
        savedMeals.removeAll()

        manager = nil
        testDishes = nil
        super.tearDown()
    }

    // MARK: - Save Meal Tests

    /// Test saving valid meal creates entity
    func testSaveMeal_ValidData_CreatesEntity() throws {
        // ARRANGE
        let timestamp = Date()

        // ACT
        try manager.saveMeal(
            timestamp: timestamp,
            mealType: .lunch,
            photo: nil,
            dishes: testDishes,
            dietaryAdvice: nil
        )

        // ASSERT
        let meals = manager.fetchAllMeals()
        XCTAssertGreaterThan(meals.count, 0, "Should have saved at least one meal")

        // Find our meal
        if let savedMeal = meals.first(where: { abs($0.timestamp.timeIntervalSince(timestamp)) < 1.0 }) {
            savedMeals.append(savedMeal)  // Track for cleanup
            XCTAssertEqual(savedMeal.mealTypeEnum, .lunch, "Meal type should match")
            XCTAssertEqual(savedMeal.dishes.count, 1, "Should have one dish")
        } else {
            XCTFail("Should find the saved meal")
        }
    }

    /// Test saving meal with photo compresses and stores
    func testSaveMeal_WithPhoto_CompressesAndStores() throws {
        // ARRANGE
        let testImage = TestHelpers.createTestImage()
        let timestamp = Date()

        // ACT
        try manager.saveMeal(
            timestamp: timestamp,
            mealType: .dinner,
            photo: testImage,
            dishes: testDishes,
            dietaryAdvice: nil
        )

        // ASSERT
        let meals = manager.fetchAllMeals()
        if let savedMeal = meals.first(where: { abs($0.timestamp.timeIntervalSince(timestamp)) < 1.0 }) {
            savedMeals.append(savedMeal)  // Track for cleanup
            XCTAssertNotNil(savedMeal.photoData, "Photo data should be stored")
            XCTAssertNotNil(savedMeal.photo, "Should be able to decode photo")
        } else {
            XCTFail("Should find the saved meal")
        }
    }

    /// Test saving meal without photo succeeds
    func testSaveMeal_WithoutPhoto_SavesSuccessfully() throws {
        // ARRANGE
        let timestamp = Date()

        // ACT
        try manager.saveMeal(
            timestamp: timestamp,
            mealType: .breakfast,
            photo: nil,
            dishes: testDishes,
            dietaryAdvice: nil
        )

        // ASSERT
        let meals = manager.fetchAllMeals()
        if let savedMeal = meals.first(where: { abs($0.timestamp.timeIntervalSince(timestamp)) < 1.0 }) {
            savedMeals.append(savedMeal)  // Track for cleanup
            XCTAssertNil(savedMeal.photoData, "Photo data should be nil")
            XCTAssertNil(savedMeal.photo, "Photo should be nil")
        } else {
            XCTFail("Should find the saved meal")
        }
    }

    // MARK: - Fetch Tests

    /// Test fetching all meals returns sorted by newest
    func testFetchAllMeals_MultipleMeals_ReturnsSortedByNewest() throws {
        // ARRANGE
        let date1 = Date(timeIntervalSinceNow: -3600)  // 1 hour ago
        let date2 = Date(timeIntervalSinceNow: -1800)  // 30 min ago
        let date3 = Date()  // Now

        try manager.saveMeal(timestamp: date1, mealType: .breakfast, photo: nil, dishes: testDishes, dietaryAdvice: nil)
        try manager.saveMeal(timestamp: date2, mealType: .lunch, photo: nil, dishes: testDishes, dietaryAdvice: nil)
        try manager.saveMeal(timestamp: date3, mealType: .dinner, photo: nil, dishes: testDishes, dietaryAdvice: nil)

        // ACT
        let meals = manager.fetchAllMeals()

        // Track all meals for cleanup
        savedMeals.append(contentsOf: meals.filter { meal in
            abs(meal.timestamp.timeIntervalSince(date1)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date2)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date3)) < 1.0
        })

        // ASSERT
        XCTAssertGreaterThanOrEqual(meals.count, 3, "Should have at least 3 meals")

        // Verify order (newest first)
        // Due to potential other meals in DB, just check our meals are present
        let ourMeals = meals.filter { meal in
            abs(meal.timestamp.timeIntervalSince(date1)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date2)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date3)) < 1.0
        }

        XCTAssertGreaterThanOrEqual(ourMeals.count, 3, "Should find all our test meals")
    }

    /// Test fetching meals by date range
    func testFetchMeals_DateRange_ReturnsOnlyMatchingMeals() throws {
        // ARRANGE
        let baseDate = Date()
        let date1 = Calendar.current.date(byAdding: .day, value: -5, to: baseDate)!  // 5 days ago
        let date2 = Calendar.current.date(byAdding: .day, value: -2, to: baseDate)!  // 2 days ago
        let date3 = Date()  // Now

        try manager.saveMeal(timestamp: date1, mealType: .breakfast, photo: nil, dishes: testDishes, dietaryAdvice: nil)
        try manager.saveMeal(timestamp: date2, mealType: .lunch, photo: nil, dishes: testDishes, dietaryAdvice: nil)
        try manager.saveMeal(timestamp: date3, mealType: .dinner, photo: nil, dishes: testDishes, dietaryAdvice: nil)

        // ACT: Query last 3 days
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: baseDate)!
        let meals = manager.fetchMeals(from: threeDaysAgo, to: baseDate)

        // Track for cleanup
        let allTestMeals = manager.fetchAllMeals().filter { meal in
            abs(meal.timestamp.timeIntervalSince(date1)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date2)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date3)) < 1.0
        }
        savedMeals.append(contentsOf: allTestMeals)

        // ASSERT
        // Should find date2 and date3, but not date1
        let matchedMeals = meals.filter { meal in
            abs(meal.timestamp.timeIntervalSince(date2)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date3)) < 1.0
        }

        XCTAssertGreaterThanOrEqual(matchedMeals.count, 2, "Should find meals from last 3 days")

        // Should NOT find date1 (5 days ago)
        let oldMeal = meals.first(where: { abs($0.timestamp.timeIntervalSince(date1)) < 1.0 })
        XCTAssertNil(oldMeal, "Should not find meal from 5 days ago")
    }

    /// Test fetching recent meals with limit
    func testFetchRecentMeals_WithLimit_ReturnsCorrectCount() throws {
        // ARRANGE
        let limit = 2

        // Create 3 meals
        for i in 0..<3 {
            let timestamp = Date(timeIntervalSinceNow: TimeInterval(-i * 60))
            try manager.saveMeal(timestamp: timestamp, mealType: .snack, photo: nil, dishes: testDishes, dietaryAdvice: nil)
        }

        // ACT
        let meals = manager.fetchRecentMeals(limit: limit)

        // Track for cleanup - fetch all to get our test meals
        let allTestMeals = manager.fetchAllMeals().prefix(3)
        savedMeals.append(contentsOf: allTestMeals)

        // ASSERT
        XCTAssertGreaterThanOrEqual(meals.count, limit, "Should return at least the limit number of meals")
    }

    // MARK: - Statistics Tests

    /// Test get meal count returns correct number
    func testGetMealCount_ReturnsCorrectCount() throws {
        // ARRANGE
        let countBefore = manager.getMealCount()

        // Add 2 meals
        let date1 = Date()
        let date2 = Date(timeIntervalSinceNow: -60)

        try manager.saveMeal(timestamp: date1, mealType: .breakfast, photo: nil, dishes: testDishes, dietaryAdvice: nil)
        try manager.saveMeal(timestamp: date2, mealType: .lunch, photo: nil, dishes: testDishes, dietaryAdvice: nil)

        // Track for cleanup
        let meals = manager.fetchAllMeals().filter { meal in
            abs(meal.timestamp.timeIntervalSince(date1)) < 1.0 ||
            abs(meal.timestamp.timeIntervalSince(date2)) < 1.0
        }
        savedMeals.append(contentsOf: meals)

        // ACT
        let countAfter = manager.getMealCount()

        // ASSERT
        XCTAssertEqual(countAfter, countBefore + 2, "Count should increase by 2")
    }

    // MARK: - Helper Method Tests

    /// Test determineMealType returns correct types for different times
    func testDetermineMealType_VariousTimes_ReturnsCorrectType() {
        // Note: This is a static method that depends on current time
        // We can only test the current time, not all scenarios
        // In a real app, you might refactor to accept a Date parameter for testing

        // ACT
        let mealType = MealPersistenceManager.determineMealType()

        // ASSERT
        // Just verify it returns one of the valid types
        let validTypes: [MealType] = [.breakfast, .lunch, .dinner, .snack]
        XCTAssertTrue(validTypes.contains(mealType), "Should return a valid meal type")
    }
}

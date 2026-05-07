//
//  NutritionTargetsTests.swift
//  FoodShutterTesting
//
//  Tests for NutritionTargets range-checking logic and NutritionTargetsRow conversion.
//

import XCTest
@testable import FoodShutter

final class NutritionTargetsTests: XCTestCase {

    var targets: NutritionTargets!

    override func setUp() {
        super.setUp()
        targets = NutritionTargets(
            caloriesMin: 1800, caloriesMax: 2200, caloriesTarget: 2000,
            proteinMin: 80,    proteinMax: 120,   proteinTarget: 100,
            fatMin: 50,        fatMax: 80,        fatTarget: 65,
            carbMin: 200,      carbMax: 280,      carbTarget: 240,
            explanation: "Test targets",
            generatedDate: Date()
        )
    }

    override func tearDown() {
        targets = nil
        super.tearDown()
    }

    // MARK: - isCaloriesInRange

    func testIsCaloriesInRange_WithinRange_ReturnsTrue() {
        XCTAssertTrue(targets.isCaloriesInRange(2000))
    }

    func testIsCaloriesInRange_AtMinBoundary_ReturnsTrue() {
        XCTAssertTrue(targets.isCaloriesInRange(1800))
    }

    func testIsCaloriesInRange_AtMaxBoundary_ReturnsTrue() {
        XCTAssertTrue(targets.isCaloriesInRange(2200))
    }

    func testIsCaloriesInRange_BelowMin_ReturnsFalse() {
        XCTAssertFalse(targets.isCaloriesInRange(1799))
    }

    func testIsCaloriesInRange_AboveMax_ReturnsFalse() {
        XCTAssertFalse(targets.isCaloriesInRange(2201))
    }

    // MARK: - isProteinInRange / isFatInRange / isCarbInRange

    func testIsProteinInRange_BoundaryValues() {
        XCTAssertTrue(targets.isProteinInRange(80))
        XCTAssertTrue(targets.isProteinInRange(120))
        XCTAssertFalse(targets.isProteinInRange(79))
        XCTAssertFalse(targets.isProteinInRange(121))
    }

    func testIsFatInRange_BoundaryValues() {
        XCTAssertTrue(targets.isFatInRange(50))
        XCTAssertTrue(targets.isFatInRange(80))
        XCTAssertFalse(targets.isFatInRange(49))
        XCTAssertFalse(targets.isFatInRange(81))
    }

    func testIsCarbInRange_BoundaryValues() {
        XCTAssertTrue(targets.isCarbInRange(200))
        XCTAssertTrue(targets.isCarbInRange(280))
        XCTAssertFalse(targets.isCarbInRange(199))
        XCTAssertFalse(targets.isCarbInRange(281))
    }

    // MARK: - isAllNutrientsInRange

    func testIsAllNutrientsInRange_AllInRange_ReturnsTrue() {
        XCTAssertTrue(targets.isAllNutrientsInRange(
            calories: 2000, protein: 100, fat: 65, carb: 240
        ))
    }

    func testIsAllNutrientsInRange_CaloriesOutOfRange_ReturnsFalse() {
        XCTAssertFalse(targets.isAllNutrientsInRange(
            calories: 1500, protein: 100, fat: 65, carb: 240
        ))
    }

    func testIsAllNutrientsInRange_SingleNutrientOutOfRange_ReturnsFalse() {
        // fat exceeds max
        XCTAssertFalse(targets.isAllNutrientsInRange(
            calories: 2000, protein: 100, fat: 100, carb: 240
        ))
    }

    // MARK: - init(from: NutritionTargetsResult)

    func testInitFromResult_MapsAllFields() {
        let result = NutritionTargetsResult(
            dailyCalories:     NutrientRange(min: 1600, max: 2000, target: 1800),
            dailyProtein:      NutrientRange(min: 60,   max: 100,  target: 80),
            dailyFat:          NutrientRange(min: 40,   max: 70,   target: 55),
            dailyCarbohydrate: NutrientRange(min: 180,  max: 260,  target: 220),
            explanation: "From API"
        )
        let mapped = NutritionTargets(from: result)

        XCTAssertEqual(mapped.caloriesMin,    1600)
        XCTAssertEqual(mapped.caloriesMax,    2000)
        XCTAssertEqual(mapped.caloriesTarget, 1800)
        XCTAssertEqual(mapped.proteinMin,     60)
        XCTAssertEqual(mapped.proteinTarget,  80)
        XCTAssertEqual(mapped.fatMax,         70)
        XCTAssertEqual(mapped.carbTarget,     220)
        XCTAssertEqual(mapped.explanation,    "From API")
    }

    // MARK: - NutritionTargetsRow round-trip

    func testNutritionTargetsRow_ToNutritionTargets_MapsAllRanges() {
        let row = NutritionTargetsRow(
            dailyCalories:     NutritionRange(min: 1800, max: 2200, target: 2000),
            dailyProtein:      NutritionRange(min: 80,   max: 120,  target: 100),
            dailyFat:          NutritionRange(min: 50,   max: 80,   target: 65),
            dailyCarbohydrate: NutritionRange(min: 200,  max: 280,  target: 240),
            explanation: "Row targets"
        )
        let mapped = row.toNutritionTargets(generatedAt: Date())

        XCTAssertEqual(mapped.caloriesMin,    1800)
        XCTAssertEqual(mapped.caloriesMax,    2200)
        XCTAssertEqual(mapped.caloriesTarget, 2000)
        XCTAssertEqual(mapped.proteinMin,     80)
        XCTAssertEqual(mapped.fatTarget,      65)
        XCTAssertEqual(mapped.carbMax,        280)
        XCTAssertEqual(mapped.explanation,    "Row targets")
    }

    func testNutritionTargetsRow_From_RoundTrip_PreservesAllValues() {
        let row = NutritionTargetsRow.from(targets)

        XCTAssertEqual(row.dailyCalories.min,     targets.caloriesMin)
        XCTAssertEqual(row.dailyCalories.max,     targets.caloriesMax)
        XCTAssertEqual(row.dailyCalories.target,  targets.caloriesTarget)
        XCTAssertEqual(row.dailyProtein.target,   targets.proteinTarget)
        XCTAssertEqual(row.dailyFat.min,          targets.fatMin)
        XCTAssertEqual(row.dailyCarbohydrate.max, targets.carbMax)
        XCTAssertEqual(row.explanation,           targets.explanation)
    }
}

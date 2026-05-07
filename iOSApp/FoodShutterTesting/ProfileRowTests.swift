//
//  ProfileRowTests.swift
//  FoodShutterTesting
//
//  Tests for ProfileRow decoding (custom init, ISO8601 date parsing) and
//  toUserNutritionProfile / toNutritionTargets conversion logic.
//

import XCTest
@testable import FoodShutter

final class ProfileRowTests: XCTestCase {

    // MARK: - JSON helpers

    private let fullProfileJSON = """
    {
        "id": "550E8400-E29B-41D4-A716-446655440000",
        "name": "Alice",
        "age": 28,
        "weight_kg": 60.0,
        "height_cm": 165.0,
        "gender": "Female",
        "activity_level": "Moderate",
        "health_goal": "Weight loss",
        "dietary_preferences": ["vegetarian", "low-carb"],
        "special_notes": "No nuts",
        "nutrition_targets": {
            "daily_calories":     {"min": 1800, "max": 2200, "target": 2000},
            "daily_protein":      {"min": 80,   "max": 120,  "target": 100},
            "daily_fat":          {"min": 50,   "max": 80,   "target": 65},
            "daily_carbohydrate": {"min": 200,  "max": 280,  "target": 240},
            "explanation": "Balanced for weight loss"
        },
        "targets_generated_at": "2026-05-01T10:00:00Z"
    }
    """

    private let minimalProfileJSON = """
    {
        "id": "550E8400-E29B-41D4-A716-446655440001"
    }
    """

    private func decode(_ json: String) throws -> ProfileRow {
        try JSONDecoder().decode(ProfileRow.self, from: json.data(using: .utf8)!)
    }

    // MARK: - Decoding: all fields

    func testProfileRow_Decode_AllFields_MapsCorrectly() throws {
        let row = try decode(fullProfileJSON)

        XCTAssertEqual(row.name,             "Alice")
        XCTAssertEqual(row.age,              28)
        XCTAssertEqual(row.weightKg,         60.0)
        XCTAssertEqual(row.heightCm,         165.0)
        XCTAssertEqual(row.gender,           "Female")
        XCTAssertEqual(row.activityLevel,    "Moderate")
        XCTAssertEqual(row.healthGoal,       "Weight loss")
        XCTAssertEqual(row.dietaryPreferences, ["vegetarian", "low-carb"])
        XCTAssertEqual(row.specialNotes,     "No nuts")
        XCTAssertNotNil(row.nutritionTargets)
        XCTAssertNotNil(row.targetsGeneratedAt)
    }

    func testProfileRow_Decode_MinimalFields_AllOptionalsAreNil() throws {
        let row = try decode(minimalProfileJSON)

        XCTAssertNil(row.name)
        XCTAssertNil(row.age)
        XCTAssertNil(row.weightKg)
        XCTAssertNil(row.heightCm)
        XCTAssertNil(row.gender)
        XCTAssertNil(row.activityLevel)
        XCTAssertNil(row.healthGoal)
        XCTAssertNil(row.dietaryPreferences)
        XCTAssertNil(row.specialNotes)
        XCTAssertNil(row.nutritionTargets)
        XCTAssertNil(row.targetsGeneratedAt)
    }

    // MARK: - ISO8601 date parsing

    func testProfileRow_DateParsing_PlainISO8601_ParsesCorrectly() throws {
        let row = try decode(fullProfileJSON) // "2026-05-01T10:00:00Z"
        let cal = Calendar(identifier: .gregorian)
        var utc = cal
        utc.timeZone = TimeZone(identifier: "UTC")!
        let components = utc.dateComponents([.year, .month, .day, .hour], from: row.targetsGeneratedAt!)
        XCTAssertEqual(components.year,  2026)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day,   1)
        XCTAssertEqual(components.hour,  10)
    }

    func testProfileRow_DateParsing_ISO8601WithFractionalSeconds_ParsesCorrectly() throws {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "targets_generated_at": "2026-05-01T10:00:00.123Z"
        }
        """
        let row = try decode(json)
        XCTAssertNotNil(row.targetsGeneratedAt)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let components = utc.dateComponents([.year, .month, .day], from: row.targetsGeneratedAt!)
        XCTAssertEqual(components.year,  2026)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day,   1)
    }

    func testProfileRow_DateParsing_MalformedDate_YieldsNilDate() throws {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "targets_generated_at": "not-a-date"
        }
        """
        let row = try decode(json)
        // parseISO8601 returns nil for unrecognized formats → targetsGeneratedAt is nil
        XCTAssertNil(row.targetsGeneratedAt)
    }

    func testProfileRow_DateParsing_AbsentKey_YieldsNilDate() throws {
        let row = try decode(minimalProfileJSON)
        XCTAssertNil(row.targetsGeneratedAt)
    }

    // MARK: - toUserNutritionProfile with all fields populated

    func testProfileRow_ToUserNutritionProfile_WithAllFields_MapsCorrectly() throws {
        let row = try decode(fullProfileJSON)
        let profile = row.toUserNutritionProfile()

        XCTAssertEqual(profile.name,          "Alice")
        XCTAssertEqual(profile.weight,        60.0)
        XCTAssertEqual(profile.height,        165.0)
        XCTAssertEqual(profile.age,           28)
        XCTAssertEqual(profile.gender,        "Female")
        XCTAssertEqual(profile.activityLevel, "Moderate")
        XCTAssertEqual(profile.goals,         ["vegetarian", "low-carb"])
        XCTAssertEqual(profile.preference,    "Weight loss")
        XCTAssertEqual(profile.other,         "No nuts")
    }

    // MARK: - toUserNutritionProfile nil-coalescing defaults

    func testProfileRow_ToUserNutritionProfile_WithNilFields_UsesDefaults() throws {
        let row = try decode(minimalProfileJSON)
        let profile = row.toUserNutritionProfile()

        XCTAssertEqual(profile.name,          "")
        XCTAssertEqual(profile.weight,        70,        accuracy: 0.01)
        XCTAssertEqual(profile.height,        170,       accuracy: 0.01)
        XCTAssertEqual(profile.age,           25)
        XCTAssertEqual(profile.gender,        "Male")
        XCTAssertEqual(profile.activityLevel, "Moderate")
        XCTAssertEqual(profile.goals,         [])
        XCTAssertEqual(profile.preference,    "")
        XCTAssertEqual(profile.other,         "")
    }

    // MARK: - toNutritionTargets

    func testProfileRow_ToNutritionTargets_BothPresent_ReturnsValue() throws {
        let row = try decode(fullProfileJSON)
        let targets = row.toNutritionTargets()

        XCTAssertNotNil(targets)
        XCTAssertEqual(targets?.caloriesMin,    1800)
        XCTAssertEqual(targets?.caloriesTarget, 2000)
        XCTAssertEqual(targets?.proteinMax,     120)
        XCTAssertEqual(targets?.explanation,    "Balanced for weight loss")
    }

    func testProfileRow_ToNutritionTargets_NilTargets_ReturnsNil() throws {
        // Has a date but no nutrition_targets object
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "targets_generated_at": "2026-05-01T10:00:00Z"
        }
        """
        let row = try decode(json)
        XCTAssertNil(row.toNutritionTargets())
    }

    func testProfileRow_ToNutritionTargets_NilGeneratedAt_ReturnsNil() throws {
        // Has nutrition_targets but no date
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "nutrition_targets": {
                "daily_calories":     {"min": 1800, "max": 2200, "target": 2000},
                "daily_protein":      {"min": 80,   "max": 120,  "target": 100},
                "daily_fat":          {"min": 50,   "max": 80,   "target": 65},
                "daily_carbohydrate": {"min": 200,  "max": 280,  "target": 240},
                "explanation": "Test"
            }
        }
        """
        let row = try decode(json)
        XCTAssertNil(row.toNutritionTargets())
    }
}

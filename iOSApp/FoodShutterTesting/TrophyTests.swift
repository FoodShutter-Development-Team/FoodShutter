//
//  TrophyTests.swift
//  FoodShutterTesting
//
//  Tests for TrophyType computed properties and TrophyRow → Trophy mapping.
//

import XCTest
@testable import FoodShutter

final class TrophyTests: XCTestCase {

    // MARK: - TrophyType

    func testTrophyType_RawValues_MatchDisplayStrings() {
        XCTAssertEqual(TrophyType.singleDay.rawValue, "Single Day Achievement")
        XCTAssertEqual(TrophyType.threeDay.rawValue,  "3-Day Streak")
        XCTAssertEqual(TrophyType.sevenDay.rawValue,  "7-Day Streak")
    }

    func testTrophyType_Icons_AreDistinctEmoji() {
        XCTAssertEqual(TrophyType.singleDay.icon, "🏅")
        XCTAssertEqual(TrophyType.threeDay.icon,  "🥈")
        XCTAssertEqual(TrophyType.sevenDay.icon,  "🏆")
    }

    func testTrophyType_Titles_AreNonEmpty() {
        for type in [TrophyType.singleDay, .threeDay, .sevenDay] {
            XCTAssertFalse(type.title.isEmpty, "\(type) title should not be empty")
        }
    }

    func testTrophyType_Descriptions_AreNonEmpty() {
        for type in [TrophyType.singleDay, .threeDay, .sevenDay] {
            XCTAssertFalse(type.description.isEmpty, "\(type) description should not be empty")
        }
    }

    // MARK: - TrophyRow → Trophy (via JSON decoding, no memberwise init)

    private func makeTrophyRowJSON(
        trophyType: String = "Single Day Achievement",
        earnedDate: String = "2026-05-01",
        streakDays: Int = 1,
        snapshot: String = #"{"calories":1950,"protein":95,"fat":62,"carbohydrate":230}"#
    ) -> Data {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "user_id": "550E8400-E29B-41D4-A716-446655440001",
            "trophy_type": "\(trophyType)",
            "earned_date": "\(earnedDate)",
            "streak_days": \(streakDays),
            "nutrition_snapshot": \(snapshot)
        }
        """
        return json.data(using: .utf8)!
    }

    func testTrophyRow_ToTrophy_MapsAllFields() throws {
        let row = try JSONDecoder().decode(TrophyRow.self, from: makeTrophyRowJSON(
            trophyType: "7-Day Streak",
            streakDays: 7,
            snapshot: #"{"calories":2100,"protein":110,"fat":70,"carbohydrate":260}"#
        ))
        let trophy = row.toTrophy()

        XCTAssertEqual(trophy.type,         .sevenDay)
        XCTAssertEqual(trophy.streakDays,   7)
        XCTAssertEqual(trophy.calories,     2100)
        XCTAssertEqual(trophy.protein,      110)
        XCTAssertEqual(trophy.fat,          70)
        XCTAssertEqual(trophy.carbohydrate, 260)
    }

    func testTrophyRow_ToTrophy_ThreeDay_MapsCorrectly() throws {
        let row = try JSONDecoder().decode(TrophyRow.self, from: makeTrophyRowJSON(
            trophyType: "3-Day Streak",
            streakDays: 3
        ))
        XCTAssertEqual(row.toTrophy().type, .threeDay)
        XCTAssertEqual(row.toTrophy().streakDays, 3)
    }

    func testTrophyRow_ToTrophy_NilSnapshot_DefaultsToZero() throws {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "user_id": "550E8400-E29B-41D4-A716-446655440001",
            "trophy_type": "Single Day Achievement",
            "earned_date": "2026-05-01",
            "streak_days": 1
        }
        """.data(using: .utf8)!
        let trophy = try JSONDecoder().decode(TrophyRow.self, from: json).toTrophy()

        XCTAssertEqual(trophy.calories,     0)
        XCTAssertEqual(trophy.protein,      0)
        XCTAssertEqual(trophy.fat,          0)
        XCTAssertEqual(trophy.carbohydrate, 0)
    }

    func testTrophyRow_ToTrophy_UnknownType_FallsToSingleDay() throws {
        let row = try JSONDecoder().decode(TrophyRow.self, from: makeTrophyRowJSON(
            trophyType: "Unknown Trophy"
        ))
        XCTAssertEqual(row.toTrophy().type, .singleDay)
    }

    func testTrophyRow_NilStreakDays_DefaultsToOne() throws {
        let json = """
        {
            "id": "550E8400-E29B-41D4-A716-446655440000",
            "user_id": "550E8400-E29B-41D4-A716-446655440001",
            "trophy_type": "Single Day Achievement",
            "earned_date": "2026-05-01",
            "nutrition_snapshot": {"calories":0,"protein":0,"fat":0,"carbohydrate":0}
        }
        """.data(using: .utf8)!
        let trophy = try JSONDecoder().decode(TrophyRow.self, from: json).toTrophy()
        XCTAssertEqual(trophy.streakDays, 1)
    }

    // MARK: - Date parsing

    func testTrophyRow_DateParsing_YMDFormat() throws {
        let row = try JSONDecoder().decode(TrophyRow.self, from: makeTrophyRowJSON(
            earnedDate: "2026-05-07"
        ))
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: row.earnedDate)
        XCTAssertEqual(components.year,  2026)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day,   7)
    }

    func testTrophyRow_DateParsing_ISO8601Fallback() throws {
        let row = try JSONDecoder().decode(TrophyRow.self, from: makeTrophyRowJSON(
            earnedDate: "2026-05-07T00:00:00Z"
        ))
        let calendar = Calendar(identifier: .gregorian)
        var utc = calendar
        utc.timeZone = TimeZone(identifier: "UTC")!
        let components = utc.dateComponents([.year, .month, .day], from: row.earnedDate)
        XCTAssertEqual(components.year,  2026)
        XCTAssertEqual(components.month, 5)
        XCTAssertEqual(components.day,   7)
    }
}

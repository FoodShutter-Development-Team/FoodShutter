//
//  Trophy.swift
//  FoodShutter
//
//  Domain models for trophy/achievement system
//

import Foundation

// MARK: - Trophy Type

/// Types of trophies that can be earned
enum TrophyType: String, Codable {
    case singleDay = "Single Day Achievement"
    case threeDay = "3-Day Streak"
    case sevenDay = "7-Day Streak"

    /// Emoji icon for trophy type
    var icon: String {
        switch self {
        case .singleDay: return "🏅"
        case .threeDay: return "🥈"
        case .sevenDay: return "🏆"
        }
    }

    /// Display title for trophy
    var title: String {
        switch self {
        case .singleDay: return "Daily Goal"
        case .threeDay: return "3-Day Champion"
        case .sevenDay: return "Week Warrior"
        }
    }

    /// Description of achievement
    var description: String {
        switch self {
        case .singleDay:
            return "Met all nutrition targets for the day"
        case .threeDay:
            return "Maintained nutrition goals for 3 consecutive days"
        case .sevenDay:
            return "Stayed on track for 7 consecutive days"
        }
    }
}

// MARK: - Trophy Model

/// Represents an earned trophy/achievement
struct Trophy: Identifiable {
    let id: UUID
    let type: TrophyType
    let earnedDate: Date
    let streakDays: Int  // Number of days in streak when earned

    // Nutrition stats snapshot when trophy was earned
    let calories: Double
    let protein: Double
    let fat: Double
    let carbohydrate: Double
}

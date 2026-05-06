//
//  FoodIngredient.swift
//  FoodShutter
//

import SwiftUI

struct FoodIngredient: Identifiable, Equatable {
    let id: UUID
    let name: String
    let icon: String
    let weightGrams: Double
    let calories: Double
    let proteinG: Double
    let fatG: Double
    let carbG: Double
    let confidence: String?
    let source: String?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "🍽️",
        weightGrams: Double,
        calories: Double,
        proteinG: Double,
        fatG: Double,
        carbG: Double,
        confidence: String? = nil,
        source: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.weightGrams = weightGrams
        self.calories = calories
        self.proteinG = proteinG
        self.fatG = fatG
        self.carbG = carbG
        self.confidence = confidence
        self.source = source
    }

    // MARK: - Aliases for UI compatibility

    var weight: Double { weightGrams }
    var proteinWeight: Double { proteinG }
    var fatWeight: Double { fatG }
    var carbohydrateWeight: Double { carbG }

    // MARK: - Bar chart percentages (proportion of total macros)

    private var totalMacros: Double { proteinG + fatG + carbG }

    var available: Double { totalMacros }

    var proteinPercent: Double {
        guard totalMacros > 0 else { return 0 }
        return proteinG / totalMacros * 100
    }

    var fatPercent: Double {
        guard totalMacros > 0 else { return 0 }
        return fatG / totalMacros * 100
    }

    var carbohydratePercent: Double {
        guard totalMacros > 0 else { return 0 }
        return carbG / totalMacros * 100
    }
}

extension FoodIngredient {
    static func == (lhs: FoodIngredient, rhs: FoodIngredient) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension FoodIngredient {
    static let sampleData: [FoodIngredient] = [
        FoodIngredient(
            name: "Fresh Fish (Carp/Grass Carp)",
            icon: "🐟",
            weightGrams: 200,
            calories: 216,
            proteinG: 34.0,
            fatG: 9.0,
            carbG: 0.6
        ),
        FoodIngredient(
            name: "Kale",
            icon: "🥬",
            weightGrams: 50,
            calories: 22,
            proteinG: 2.2,
            fatG: 0.5,
            carbG: 4.4
        ),
        FoodIngredient(
            name: "Sour Soup Base",
            icon: "🍲",
            weightGrams: 300,
            calories: 36,
            proteinG: 2.4,
            fatG: 0.9,
            carbG: 10.5
        ),
        FoodIngredient(
            name: "Tomato in Soup",
            icon: "🍅",
            weightGrams: 80,
            calories: 14,
            proteinG: 0.7,
            fatG: 0.2,
            carbG: 3.1
        ),
        FoodIngredient(
            name: "Wood Ginger Oil",
            icon: "🌿",
            weightGrams: 5,
            calories: 45,
            proteinG: 0,
            fatG: 5.0,
            carbG: 0
        )
    ]
}

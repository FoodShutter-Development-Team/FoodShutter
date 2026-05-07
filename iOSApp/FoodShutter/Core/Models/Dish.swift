//
//  Dish.swift
//  FoodShutter
//

import SwiftUI

struct Dish: Identifiable, Equatable {
    let id: UUID
    let name: String
    let icon: String
    var ingredients: [FoodIngredient]
    var bbox: [Double]?
    var container: String?
    var portionSize: String?
    var estimatedGrams: Double?
    var confidence: String?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "🍽️",
        ingredients: [FoodIngredient] = [],
        bbox: [Double]? = nil,
        container: String? = nil,
        portionSize: String? = nil,
        estimatedGrams: Double? = nil,
        confidence: String? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.ingredients = ingredients
        self.bbox = bbox
        self.container = container
        self.portionSize = portionSize
        self.estimatedGrams = estimatedGrams
        self.confidence = confidence
    }

    // MARK: - Computed Nutrition (aggregated from ingredients)

    var totalWeight: Double { ingredients.reduce(0) { $0 + $1.weightGrams } }
    var totalCalories: Double { ingredients.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { ingredients.reduce(0) { $0 + $1.proteinG } }
    var totalFat: Double { ingredients.reduce(0) { $0 + $1.fatG } }
    var totalCarbohydrate: Double { ingredients.reduce(0) { $0 + $1.carbG } }

    private var totalMacros: Double { totalProtein + totalFat + totalCarbohydrate }

    var available: Double { totalMacros }

    var proteinPercent: Double {
        guard totalMacros > 0 else { return 0 }
        return totalProtein / totalMacros * 100
    }

    var fatPercent: Double {
        guard totalMacros > 0 else { return 0 }
        return totalFat / totalMacros * 100
    }

    var carbohydratePercent: Double {
        guard totalMacros > 0 else { return 0 }
        return totalCarbohydrate / totalMacros * 100
    }
}

extension Dish {
    static func == (lhs: Dish, rhs: Dish) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension Dish {
    static let sampleData: [Dish] = [
        Dish(
            name: "Guizhou Sour Soup Fish",
            icon: "🐟",
            ingredients: FoodIngredient.sampleData
        ),
        Dish(
            name: "Steamed White Rice",
            icon: "🍚",
            ingredients: [
                FoodIngredient(
                    name: "Steamed White Rice",
                    icon: "🍚",
                    weightGrams: 150,
                    calories: 195,
                    proteinG: 4.0,
                    fatG: 0.3,
                    carbG: 43.0
                )
            ]
        )
    ]
}

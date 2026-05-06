//
//  NutritionSummaryData.swift
//  FoodShutter
//

import Foundation

struct NutritionSummaryData {
    let ingredients: [FoodIngredient]

    var totalWeight: Double { ingredients.reduce(0) { $0 + $1.weightGrams } }
    var totalCalories: Double { ingredients.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { ingredients.reduce(0) { $0 + $1.proteinG } }
    var totalFat: Double { ingredients.reduce(0) { $0 + $1.fatG } }
    var totalCarbohydrate: Double { ingredients.reduce(0) { $0 + $1.carbG } }

    private var totalNutrients: Double { totalProtein + totalFat + totalCarbohydrate }

    var proteinPercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return totalProtein / totalNutrients * 100
    }

    var fatPercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return totalFat / totalNutrients * 100
    }

    var carbohydratePercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return totalCarbohydrate / totalNutrients * 100
    }
}

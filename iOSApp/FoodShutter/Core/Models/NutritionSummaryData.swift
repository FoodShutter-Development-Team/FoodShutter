//
//  NutritionSummaryData.swift
//  FoodShutter
//
//  Data model for nutrition summary calculations
//

import Foundation

/// 营养总结数据模型
struct NutritionSummaryData {
    let ingredients: [FoodIngredient]

    /// 总重量（克）
    var totalWeight: Double {
        ingredients.reduce(0) { $0 + $1.weight }
    }

    /// 总卡路里
    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }

    /// 总蛋白质重量（克）
    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.proteinWeight }
    }

    /// 总脂肪重量（克）
    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fatWeight }
    }

    /// 总碳水化合物重量（克）
    var totalCarbohydrate: Double {
        ingredients.reduce(0) { $0 + $1.carbohydrateWeight }
    }

    /// 总营养成分重量
    var totalNutrients: Double {
        totalProtein + totalFat + totalCarbohydrate
    }

    /// 蛋白质百分比
    var proteinPercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return (totalProtein / totalNutrients) * 100
    }

    /// 脂肪百分比
    var fatPercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return (totalFat / totalNutrients) * 100
    }

    /// 碳水化合物百分比
    var carbohydratePercent: Double {
        guard totalNutrients > 0 else { return 0 }
        return (totalCarbohydrate / totalNutrients) * 100
    }
}

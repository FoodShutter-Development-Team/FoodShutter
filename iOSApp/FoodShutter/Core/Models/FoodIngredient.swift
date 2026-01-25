//
//  FoodIngredient.swift
//  FoodShutter
//
//  Created by Cosmos on 19/10/2025.
//

import SwiftUI

/// 食物成分模型
struct FoodIngredient: Identifiable, Equatable {
    let id = UUID()
    let name: String              // 食物名称
    let icon: String              // Emoji 图标
    let weight: Double            // 重量（克）
    let proteinPercent: Double    // 蛋白质百分比 (0-100)
    let fatPercent: Double        // 脂肪百分比 (0-100)
    let carbohydratePercent: Double // 碳水化合物百分比 (0-100)

    /// 计算蛋白质重量（克）
    var available: Double {
        carbohydratePercent+proteinPercent+fatPercent
    }
    
    var proteinWeight: Double {
        weight * proteinPercent / 100
    }

    /// 计算脂肪重量（克）
    var fatWeight: Double {
        weight * fatPercent / 100
    }

    /// 计算碳水化合物重量（克）
    var carbohydrateWeight: Double {
        weight * carbohydratePercent / 100
    }

    /// 计算总卡路里（蛋白质4卡/克，脂肪9卡/克，碳水4卡/克）
    var calories: Double {
        proteinWeight * 4 + fatWeight * 9 + carbohydrateWeight * 4
    }
}

extension FoodIngredient {
    static func == (lhs: FoodIngredient, rhs: FoodIngredient) -> Bool {
        lhs.name == rhs.name &&
        lhs.icon == rhs.icon &&
        lhs.weight == rhs.weight &&
        lhs.proteinPercent == rhs.proteinPercent &&
        lhs.fatPercent == rhs.fatPercent &&
        lhs.carbohydratePercent == rhs.carbohydratePercent
    }
}

// MARK: - 示例数据
extension FoodIngredient {
    static let sampleData: [FoodIngredient] = [
        FoodIngredient(
            name: "Fresh Fish (Carp/Grass Carp)",
            icon: "🐟",
            weight: 200,  // 约200克鱼肉（去骨净肉）
            proteinPercent: 17.0,  // 鲤鱼和草鱼平均值
            fatPercent: 4.5,
            carbohydratePercent: 0.3
        ),
        FoodIngredient(
            name: "Kale",
            icon: "🥬",
            weight: 50,  // 羽衣甘蓝装饰部分
            proteinPercent: 4.3,
            fatPercent: 0.9,
            carbohydratePercent: 8.8
        ),
        FoodIngredient(
            name: "Sour Soup Base",
            icon: "🍲",
            weight: 300,  // 酸汤底料（含番茄、辣椒发酵）
            proteinPercent: 0.8,
            fatPercent: 0.3,
            carbohydratePercent: 3.5
        ),
        FoodIngredient(
            name: "Tomato in Soup",
            icon: "🍅",
            weight: 80,  // 额外添加的番茄
            proteinPercent: 0.9,
            fatPercent: 0.2,
            carbohydratePercent: 3.9
        ),
        FoodIngredient(
            name: "Wood Ginger Oil",
            icon: "🌿",
            weight: 5,  // 木姜子油调味
            proteinPercent: 0,
            fatPercent: 100,
            carbohydratePercent: 0
        ),
        FoodIngredient(
            name: "Ginger & Garlic",
            icon: "🧄",
            weight: 10,
            proteinPercent: 1.8,
            fatPercent: 0.5,
            carbohydratePercent: 16.3
        ),
        FoodIngredient(
            name: "Green Onion",
            icon: "🥬",
            weight: 5,
            proteinPercent: 1.8,
            fatPercent: 0.3,
            carbohydratePercent: 7.3
        ),
        FoodIngredient(
            name: "Chili Pepper",
            icon: "🌶️",
            weight: 10,
            proteinPercent: 1.9,
            fatPercent: 0.4,
            carbohydratePercent: 8.8
        )
    ]
}

//
//  GeminiModels.swift
//  FoodShutter
//
//  Shared models for Gemini API integration
//

import Foundation

// MARK: - Food Analysis Models

struct FoodAnalysisResult: Codable {
    let dishNum: Int
    let dishes: [FoodDish]

    enum CodingKeys: String, CodingKey {
        case dishNum = "dish_num"
        case dishes
    }
}

struct FoodDish: Codable {
    let dishName: String
    let icon: String
    let ingredients: [FoodIngredientDetail]

    enum CodingKeys: String, CodingKey {
        case dishName = "dish_name"
        case icon
        case ingredients
    }
}

struct FoodIngredientDetail: Codable {
    let name: String
    let icon: String
    let weight: Double
    let proteinPercent: Double
    let fatPercent: Double
    let carbohydratePercent: Double
}

// MARK: - Dietary Advice Models (for advice.py equivalent)

struct DietaryAdviceInput: Codable {
    let kind: String
    let timestamp: String
    let dishes: [MealDish]
    let currentMealStats: CurrentMealStats
    let nutritionAverage: NutritionAverage?
    let userProfile: UserNutritionProfile

    enum CodingKeys: String, CodingKey {
        case kind, timestamp, dishes
        case currentMealStats = "current_meal_stats"
        case nutritionAverage = "nutrition_average"
        case userProfile = "user_profile"
    }
}

struct MealDish: Codable {
    let name: String
    let ingredients: [BasicIngredient]
}

struct BasicIngredient: Codable {
    let name: String
    let weight: Double
}

struct CurrentMealStats: Codable {
    let totalcalories: Double
    let totalweight: Double
    let totalprotein: Double
    let totalfat: Double
    let totalcarbohydrate: Double
}

struct NutritionAverage: Codable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let daysCovered: Int
    let mealCount: Int

    enum CodingKeys: String, CodingKey {
        case calories, protein, fat, carbs
        case daysCovered = "days_covered"
        case mealCount = "meal_count"
    }
}

struct UserNutritionProfile: Codable {
    var name: String
    var weight: Double
    var height: Double
    var age: Int
    var gender: String
    var activityLevel: String
    var goals: [String]
    var preference: String
    var other: String

    enum CodingKeys: String, CodingKey {
        case name, weight, height, age, gender, preference, other
        case activityLevel = "activity_level"
        case goals
    }

    init(
        name: String = "",
        weight: Double,
        height: Double,
        age: Int,
        gender: String,
        activityLevel: String,
        goals: [String],
        preference: String,
        other: String
    ) {
        self.name = name
        self.weight = weight
        self.height = height
        self.age = age
        self.gender = gender
        self.activityLevel = activityLevel
        self.goals = goals
        self.preference = preference
        self.other = other
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        weight = try container.decode(Double.self, forKey: .weight)
        height = try container.decode(Double.self, forKey: .height)
        age = try container.decode(Int.self, forKey: .age)
        gender = try container.decode(String.self, forKey: .gender)
        activityLevel = try container.decode(String.self, forKey: .activityLevel)
        goals = try container.decode([String].self, forKey: .goals)
        preference = try container.decode(String.self, forKey: .preference)
        other = try container.decode(String.self, forKey: .other)
    }
}

struct DietaryAdviceResult: Codable {
    let analysis: NutritionAnalysis
    let nextMealRecommendation: NextMealRecommendation

    enum CodingKeys: String, CodingKey {
        case analysis
        case nextMealRecommendation = "next_meal_recommendation"
    }
}

struct NutritionAnalysis: Codable {
    let summary: String
    let nutritionStatus: String
    let pros: [String]
    let cons: [String]

    enum CodingKeys: String, CodingKey {
        case summary
        case nutritionStatus = "nutrition_status"
        case pros, cons
    }
}

struct NextMealRecommendation: Codable {
    let recommendedDish: RecommendedMealDish
    let reason: String
    let nutrientsFocus: [String]

    enum CodingKeys: String, CodingKey {
        case recommendedDish = "recommended_dish"
        case reason
        case nutrientsFocus = "nutrients_focus"
    }
}

struct RecommendedMealDish: Codable {
    let dishName: String
    let icon: String
    let weight: Double
    let proteinPercent: Double
    let fatPercent: Double
    let carbohydratePercent: Double

    enum CodingKeys: String, CodingKey {
        case dishName = "dish_name"
        case icon, weight
        case proteinPercent, fatPercent, carbohydratePercent
    }
}


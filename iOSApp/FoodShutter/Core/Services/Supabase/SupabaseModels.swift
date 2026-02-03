//
//  SupabaseModels.swift
//  FoodShutter
//
//  Supabase 数据库 Row / Insert / Update 模型
//  命名约定：XxxRow（读取）、XxxInsert（写入）、XxxUpdate（更新）
//

import Foundation

// MARK: - MealType（从 MealEntity.swift 迁移至此）

enum MealType: String, Codable {
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snack     = "Snack"

    static func determine() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<10:  return .breakfast
        case 10..<15: return .lunch
        case 15..<22: return .dinner
        default:      return .snack
        }
    }
}

// MARK: - Nutrition Targets JSONB

struct NutritionRange: Codable {
    let min: Double
    let max: Double
    let target: Double
}

/// 对应 Supabase nutrition_targets JSONB 列结构
struct NutritionTargetsRow: Codable {
    let dailyCalories:     NutritionRange
    let dailyProtein:      NutritionRange
    let dailyFat:          NutritionRange
    let dailyCarbohydrate: NutritionRange
    let explanation:       String

    enum CodingKeys: String, CodingKey {
        case dailyCalories     = "daily_calories"
        case dailyProtein      = "daily_protein"
        case dailyFat          = "daily_fat"
        case dailyCarbohydrate = "daily_carbohydrate"
        case explanation
    }

    /// 从 Supabase 行转换为 App 域模型
    func toNutritionTargets(generatedAt: Date) -> NutritionTargets {
        NutritionTargets(
            caloriesMin:    dailyCalories.min,
            caloriesMax:    dailyCalories.max,
            caloriesTarget: dailyCalories.target,
            proteinMin:     dailyProtein.min,
            proteinMax:     dailyProtein.max,
            proteinTarget:  dailyProtein.target,
            fatMin:         dailyFat.min,
            fatMax:         dailyFat.max,
            fatTarget:      dailyFat.target,
            carbMin:        dailyCarbohydrate.min,
            carbMax:        dailyCarbohydrate.max,
            carbTarget:     dailyCarbohydrate.target,
            explanation:    explanation,
            generatedDate:  generatedAt
        )
    }

    /// 从 App 域模型构建 Supabase 行
    static func from(_ targets: NutritionTargets) -> NutritionTargetsRow {
        NutritionTargetsRow(
            dailyCalories:     NutritionRange(min: targets.caloriesMin, max: targets.caloriesMax, target: targets.caloriesTarget),
            dailyProtein:      NutritionRange(min: targets.proteinMin,  max: targets.proteinMax,  target: targets.proteinTarget),
            dailyFat:          NutritionRange(min: targets.fatMin,      max: targets.fatMax,      target: targets.fatTarget),
            dailyCarbohydrate: NutritionRange(min: targets.carbMin,     max: targets.carbMax,     target: targets.carbTarget),
            explanation:       targets.explanation
        )
    }
}

// MARK: - Profile Models

/// 从 Supabase profiles 表读取
struct ProfileRow: Decodable {
    let id: UUID
    let name: String?
    let age: Int?
    let weightKg: Double?
    let heightCm: Double?
    let gender: String?
    let activityLevel: String?
    let healthGoal: String?
    let dietaryPreferences: [String]?
    let specialNotes: String?
    let nutritionTargets: NutritionTargetsRow?
    let targetsGeneratedAt: Date?

    /// 转换为 App 域模型（不含 NutritionTargets，单独处理）
    func toUserNutritionProfile() -> UserNutritionProfile {
        UserNutritionProfile(
            name:          name ?? "",
            weight:        weightKg ?? 70,
            height:        heightCm ?? 170,
            age:           age ?? 25,
            gender:        gender ?? "Male",
            activityLevel: activityLevel ?? "Moderate",
            goals:         dietaryPreferences ?? [],
            preference:    healthGoal ?? "",
            other:         specialNotes ?? ""
        )
    }

    /// 转换 nutritionTargets JSONB → App NutritionTargets
    func toNutritionTargets() -> NutritionTargets? {
        guard let row = nutritionTargets,
              let generatedAt = targetsGeneratedAt else { return nil }
        return row.toNutritionTargets(generatedAt: generatedAt)
    }
}

/// 写入 Supabase profiles 表（upsert 时使用）
struct ProfileUpsert: Encodable {
    let id: UUID
    let name: String
    let age: Int
    let weightKg: Double
    let heightCm: Double
    let gender: String
    let activityLevel: String
    let healthGoal: String
    let dietaryPreferences: [String]
    let specialNotes: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case age
        case weightKg          = "weight_kg"
        case heightCm          = "height_cm"
        case gender
        case activityLevel     = "activity_level"
        case healthGoal        = "health_goal"
        case dietaryPreferences = "dietary_preferences"
        case specialNotes      = "special_notes"
        case updatedAt         = "updated_at"
    }

    /// 从 App 域模型构建 Supabase upsert 载荷
    static func from(_ profile: UserNutritionProfile, userId: UUID) -> ProfileUpsert {
        ProfileUpsert(
            id:                  userId,
            name:                profile.name,
            age:                 profile.age,
            weightKg:            profile.weight,
            heightCm:            profile.height,
            gender:              profile.gender,
            activityLevel:       profile.activityLevel,
            healthGoal:          profile.preference,
            dietaryPreferences:  profile.goals,
            specialNotes:        profile.other,
            updatedAt:           Date()
        )
    }
}

/// 只更新 nutrition_targets 和 targets_generated_at
struct ProfileTargetsUpdate: Encodable {
    let nutritionTargets: NutritionTargetsRow
    let targetsGeneratedAt: Date

    enum CodingKeys: String, CodingKey {
        case nutritionTargets    = "nutrition_targets"
        case targetsGeneratedAt  = "targets_generated_at"
    }
}

// MARK: - Meal Models

/// 从 Supabase meals 表读取（含嵌套 dishes + ingredients JOIN）
struct MealRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let timestamp: Date
    let mealType: String
    let photoUrl: String?
    let advice: DietaryAdviceResult?
    let dishes: [DishRow]

    // MARK: Computed Nutrition Aggregates

    var totalProtein: Double {
        dishes.reduce(0) { $0 + $1.totalProtein }
    }

    var totalFat: Double {
        dishes.reduce(0) { $0 + $1.totalFat }
    }

    var totalCarbohydrate: Double {
        dishes.reduce(0) { $0 + $1.totalCarbohydrate }
    }

    var totalCalories: Double {
        dishes.reduce(0) { $0 + $1.totalCalories }
    }

    var mealTypeEnum: MealType {
        MealType(rawValue: mealType) ?? .snack
    }

    var dietaryAdvice: DietaryAdviceResult? { advice }

    /// 将所有菜品转换为 UI 域模型
    func toDishes() -> [Dish] {
        dishes.map { $0.toDish() }
    }
}

/// 写入 Supabase meals 表
struct MealInsert: Encodable {
    let id: UUID
    let userId: UUID
    let timestamp: Date
    let mealType: String
    let photoUrl: String?
    let advice: DietaryAdviceResult?

    enum CodingKeys: String, CodingKey {
        case id
        case userId   = "user_id"
        case timestamp
        case mealType = "meal_type"
        case photoUrl = "photo_url"
        case advice
    }
}

// MARK: - Dish Models

/// 从 Supabase dishes 表读取
struct DishRow: Decodable, Identifiable {
    let id: UUID
    let mealId: UUID
    let name: String
    let icon: String?
    let sortOrder: Int?
    let ingredients: [IngredientRow]

    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.proteinWeight }
    }

    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fatWeight }
    }

    var totalCarbohydrate: Double {
        ingredients.reduce(0) { $0 + $1.carbohydrateWeight }
    }

    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }

    func toDish() -> Dish {
        Dish(
            name:        name,
            icon:        icon ?? "🍽️",
            ingredients: ingredients.map { $0.toFoodIngredient() }
        )
    }
}

/// 写入 Supabase dishes 表
struct DishInsert: Encodable {
    let id: UUID
    let mealId: UUID
    let name: String
    let icon: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case mealId    = "meal_id"
        case name
        case icon
        case sortOrder = "sort_order"
    }
}

// MARK: - Ingredient Models

/// 从 Supabase ingredients 表读取
struct IngredientRow: Decodable, Identifiable {
    let id: UUID
    let dishId: UUID
    let name: String
    let weightGrams: Double
    let proteinPct: Double    // 0~1
    let fatPct: Double        // 0~1
    let carbohydratePct: Double // 0~1
    let sortOrder: Int?

    // 计算营养克重（基于 0~1 比例）
    var proteinWeight:      Double { weightGrams * proteinPct }
    var fatWeight:          Double { weightGrams * fatPct }
    var carbohydrateWeight: Double { weightGrams * carbohydratePct }
    var calories:           Double { proteinWeight * 4 + fatWeight * 9 + carbohydrateWeight * 4 }

    func toFoodIngredient() -> FoodIngredient {
        FoodIngredient(
            name:                name,
            icon:                "",               // Supabase 不存储食材图标
            weight:              weightGrams,
            proteinPercent:      proteinPct * 100,  // 0~1 → 0~100
            fatPercent:          fatPct * 100,
            carbohydratePercent: carbohydratePct * 100
        )
    }
}

/// 写入 Supabase ingredients 表
struct IngredientInsert: Encodable {
    let id: UUID
    let dishId: UUID
    let name: String
    let weightGrams: Double
    let proteinPct: Double
    let fatPct: Double
    let carbohydratePct: Double
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case dishId          = "dish_id"
        case name
        case weightGrams     = "weight_grams"
        case proteinPct      = "protein_pct"
        case fatPct          = "fat_pct"
        case carbohydratePct = "carbohydrate_pct"
        case sortOrder       = "sort_order"
    }
}

// MARK: - Trophy Models

/// 从 Supabase trophies 表读取
struct TrophyRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let trophyType: String
    let earnedDate: Date
    let streakDays: Int?
    let nutritionSnapshot: TrophyNutritionSnapshot?

    func toTrophy() -> Trophy {
        let snapshot = nutritionSnapshot
        return Trophy(
            id:            id,
            type:          TrophyType(rawValue: trophyType) ?? .singleDay,
            earnedDate:    earnedDate,
            streakDays:    streakDays ?? 1,
            calories:      snapshot?.calories ?? 0,
            protein:       snapshot?.protein ?? 0,
            fat:           snapshot?.fat ?? 0,
            carbohydrate:  snapshot?.carbohydrate ?? 0
        )
    }
}

/// 奖杯营养快照（存入 nutrition_snapshot JSONB）
struct TrophyNutritionSnapshot: Codable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbohydrate: Double
}

/// 写入 Supabase trophies 表
struct TrophyInsert: Encodable {
    let id: UUID
    let userId: UUID
    let trophyType: String
    let earnedDate: String   // DATE 格式：yyyy-MM-dd
    let streakDays: Int
    let nutritionSnapshot: TrophyNutritionSnapshot

    enum CodingKeys: String, CodingKey {
        case id
        case userId            = "user_id"
        case trophyType        = "trophy_type"
        case earnedDate        = "earned_date"
        case streakDays        = "streak_days"
        case nutritionSnapshot = "nutrition_snapshot"
    }
}

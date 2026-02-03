//
//  MealRepository.swift
//  FoodShutter
//
//  餐食云端存储（替换 MealPersistenceManager）
//  含照片上传至 Supabase Storage
//

import Foundation
import UIKit
import Supabase

@MainActor
final class MealRepository {
    static let shared = MealRepository()

    private let bucket = "meal-photos"

    private init() {}

    // MARK: - Save Meal

    /// 保存完整餐食（照片上传 + 写入 meals / dishes / ingredients 表）
    func saveMeal(
        timestamp:     Date = Date(),
        mealType:      MealType,
        photo:         UIImage?,
        dishes:        [Dish],
        dietaryAdvice: DietaryAdviceResult?
    ) async throws -> UUID {
        guard let userId = AuthManager.shared.userId else {
            throw RepositoryError.notAuthenticated
        }

        let mealId = UUID()

        // 1. 上传照片（失败不阻断主流程）
        var photoUrl: String? = nil
        if let photo = photo {
            photoUrl = try? await uploadPhoto(photo, userId: userId, mealId: mealId)
        }

        // 2. 插入 meals 行
        let mealInsert = MealInsert(
            id:        mealId,
            userId:    userId,
            timestamp: timestamp,
            mealType:  mealType.rawValue,
            photoUrl:  photoUrl,
            advice:    dietaryAdvice
        )
        try await supabase.from("meals").insert(mealInsert).execute()

        // 3. 插入 dishes + ingredients
        for (dishIdx, dish) in dishes.enumerated() {
            let dishId = UUID()
            let dishInsert = DishInsert(
                id:        dishId,
                mealId:    mealId,
                name:      dish.name,
                icon:      dish.icon,
                sortOrder: dishIdx
            )
            try await supabase.from("dishes").insert(dishInsert).execute()

            for (ingIdx, ingredient) in dish.ingredients.enumerated() {
                let ingredientInsert = IngredientInsert(
                    id:              UUID(),
                    dishId:          dishId,
                    name:            ingredient.name,
                    weightGrams:     ingredient.weight,
                    proteinPct:      ingredient.proteinPercent / 100,  // 0-100 → 0-1
                    fatPct:          ingredient.fatPercent / 100,
                    carbohydratePct: ingredient.carbohydratePercent / 100,
                    sortOrder:       ingIdx
                )
                try await supabase.from("ingredients").insert(ingredientInsert).execute()
            }
        }

        print("✓ Meal saved to Supabase: \(mealType.rawValue) at \(timestamp)")
        return mealId
    }

    // MARK: - Fetch Meals

    /// 获取最近 N 条餐食（含菜品和食材）
    func fetchRecentMeals(limit: Int = 50) async throws -> [MealRow] {
        guard let userId = AuthManager.shared.userId else { return [] }
        return try await supabase
            .from("meals")
            .select("*, dishes(*, ingredients(*))")
            .eq("user_id", value: userId)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// 获取指定日期范围内的餐食
    func fetchMeals(from startDate: Date, to endDate: Date) async throws -> [MealRow] {
        guard let userId = AuthManager.shared.userId else { return [] }
        let iso = ISO8601DateFormatter()
        return try await supabase
            .from("meals")
            .select("*, dishes(*, ingredients(*))")
            .eq("user_id", value: userId)
            .gte("timestamp", value: iso.string(from: startDate))
            .lte("timestamp", value: iso.string(from: endDate))
            .order("timestamp", ascending: false)
            .execute()
            .value
    }

    // MARK: - Delete Meal

    func deleteMeal(id: UUID) async throws {
        try await supabase
            .from("meals")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Photo URL

    /// 获取 Storage 签名 URL（1 小时有效）
    func getMealPhotoURL(path: String) async throws -> URL {
        return try await supabase.storage
            .from(bucket)
            .createSignedURL(path: path, expiresIn: 3600)
    }

    // MARK: - Nutrition Average（供 FoodAnalysisViewModel 调用）

    /// 计算过去 3 天的餐食营养均值
    func getNutritionAverage() async -> NutritionAverage? {
        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.date(byAdding: .day, value: -3, to: now) else { return nil }

        guard let meals = try? await fetchMeals(from: start, to: now),
              !meals.isEmpty else { return nil }

        let count = Double(meals.count)
        let avgCalories     = meals.reduce(0) { $0 + $1.totalCalories }     / count
        let avgProtein      = meals.reduce(0) { $0 + $1.totalProtein }      / count
        let avgFat          = meals.reduce(0) { $0 + $1.totalFat }          / count
        let avgCarbs        = meals.reduce(0) { $0 + $1.totalCarbohydrate } / count
        let oldestTimestamp = meals.map { $0.timestamp }.min() ?? now
        let daysCovered     = max(1, calendar.dateComponents([.day], from: oldestTimestamp, to: now).day ?? 1)

        return NutritionAverage(
            calories:    avgCalories,
            protein:     avgProtein,
            fat:         avgFat,
            carbs:       avgCarbs,
            daysCovered: min(daysCovered, 3),
            mealCount:   meals.count
        )
    }

    // MARK: - Private Helpers

    private func uploadPhoto(_ image: UIImage, userId: UUID, mealId: UUID) async throws -> String {
        let optimized = ModelTransformers.optimizeImageForUpload(image)
        guard let jpegData = optimized.jpegData(compressionQuality: 0.7) else {
            throw TransformError.imageConversionFailed
        }
        let path = "\(userId)/\(mealId).jpg"
        try await supabase.storage
            .from(bucket)
            .upload(path, data: jpegData, options: FileOptions(contentType: "image/jpeg"))
        return path
    }
}

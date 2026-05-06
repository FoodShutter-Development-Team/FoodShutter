//
//  MealRepository.swift
//  FoodShutter
//
//  Cloud read operations for meals (writes are handled by the backend pipeline)
//

import Foundation
import Supabase

@MainActor
final class MealRepository {
    static let shared = MealRepository()
    private init() {}

    // MARK: - Fetch All Meals

    func fetchRecentMeals(limit: Int = 50) async throws -> [MealRow] {
        guard let userId = AuthManager.shared.userId else { return [] }
        return try await supabase
            .from("meals")
            .select("*, dishes(*, ingredients(*))")
            .eq("user_id", value: userId)
            .eq("status", value: MealStatus.complete.rawValue)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchMeals(from startDate: Date, to endDate: Date) async throws -> [MealRow] {
        guard let userId = AuthManager.shared.userId else { return [] }
        let iso = ISO8601DateFormatter()
        return try await supabase
            .from("meals")
            .select("*, dishes(*, ingredients(*))")
            .eq("user_id", value: userId)
            .eq("status", value: MealStatus.complete.rawValue)
            .gte("timestamp", value: iso.string(from: startDate))
            .lte("timestamp", value: iso.string(from: endDate))
            .order("timestamp", ascending: false)
            .execute()
            .value
    }

    // MARK: - Fetch Single Meal

    func fetchMeal(id: UUID) async throws -> MealRow {
        return try await supabase
            .from("meals")
            .select("*, dishes(*, ingredients(*))")
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    // MARK: - Phase 1: Dishes (names + bbox, no nutrition)

    func fetchDishesPhase1(mealId: UUID) async throws -> [DishRow] {
        return try await supabase
            .from("dishes")
            .select("id, meal_id, name, icon, bbox, sort_order, empty")
            .eq("meal_id", value: mealId)
            .eq("empty", value: false)
            .order("sort_order")
            .execute()
            .value
    }

    // MARK: - Phase 2: Full Dishes (nutrition + ingredients)

    func fetchDishesPhase2(mealId: UUID) async throws -> [DishRow] {
        return try await supabase
            .from("dishes")
            .select("""
                id, meal_id, name, icon, bbox, sort_order, empty,
                container, portion_size, estimated_total_grams, confidence,
                total_calories, total_protein_g, total_fat_g, total_carb_g,
                ingredients(
                    id, dish_id, name, icon, weight_grams, calories,
                    protein_g, fat_g, carb_g, confidence, source
                )
            """)
            .eq("meal_id", value: mealId)
            .eq("empty", value: false)
            .order("sort_order")
            .execute()
            .value
    }

    // MARK: - Meal Advice

    func fetchAdvice(mealId: UUID) async throws -> MealAdviceRow? {
        return try? await supabase
            .from("meal_advices")
            .select("meal_id, summary, nutrition_status, pros, cons, suggestions, next_meal_recommendation")
            .eq("meal_id", value: mealId)
            .single()
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

    func getMealPhotoURL(path: String) async throws -> URL {
        return try await supabase.storage
            .from("meal-photos")
            .createSignedURL(path: path, expiresIn: 3600)
    }
}

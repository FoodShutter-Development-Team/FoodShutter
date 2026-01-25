//
//  ModelTransformers.swift
//  FoodShutter
//
//  数据转换层：API 模型 ↔ UI 模型
//  （Supabase 版：移除 MealPersistenceManager 依赖）
//

import UIKit
import Foundation

enum TransformError: Error, LocalizedError {
    case imageConversionFailed
    case imageOptimizationFailed
    case noFoodDetected

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:    return "Failed to convert image to JPEG format"
        case .imageOptimizationFailed:  return "Failed to optimize image for upload"
        case .noFoodDetected:           return "No food detected in the image. Please try again with a clearer photo."
        }
    }
}

struct ModelTransformers {

    // MARK: - Image Processing

    static func saveImageToTempFile(_ image: UIImage) throws -> URL {
        let tempDir  = FileManager.default.temporaryDirectory
        let filename = "food_\(UUID().uuidString).jpg"
        let fileURL  = tempDir.appendingPathComponent(filename)
        let optimized = optimizeImageForUpload(image)
        guard let data = optimized.jpegData(compressionQuality: 0.8) else {
            throw TransformError.imageConversionFailed
        }
        try data.write(to: fileURL)
        return fileURL
    }

    static func optimizeImageForUpload(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        if scale >= 1.0 { return image }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    // MARK: - API → UI Model

    static func transformToDishes(_ result: FoodAnalysisResult) -> [Dish] {
        result.dishes.map { foodDish in
            Dish(
                name: foodDish.dishName,
                icon: firstIcon(from: foodDish.icon),
                ingredients: foodDish.ingredients.map { ingredient in
                    FoodIngredient(
                        name:                ingredient.name,
                        icon:                firstIcon(from: ingredient.icon),
                        weight:              ingredient.weight,
                        proteinPercent:      ingredient.proteinPercent,
                        fatPercent:          ingredient.fatPercent,
                        carbohydratePercent: ingredient.carbohydratePercent
                    )
                }
            )
        }
    }

    private static func firstIcon(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "" }
        return String(first)
    }

    /// 创建饮食建议输入（nutritionAverage 由调用方从 MealRepository 异步获取后传入）
    static func createDietaryAdviceInput(
        from analysis: FoodAnalysisResult,
        userProfile: UserNutritionProfile,
        nutritionAverage: NutritionAverage?
    ) -> DietaryAdviceInput {
        let currentStats = calculateCurrentMealStats(from: analysis)
        let mealKind     = determineMealKind()
        let timestamp    = ISO8601DateFormatter().string(from: Date())

        let dishes: [MealDish] = analysis.dishes.map { dish in
            MealDish(
                name: dish.dishName,
                ingredients: dish.ingredients.map {
                    BasicIngredient(name: $0.name, weight: $0.weight)
                }
            )
        }

        return DietaryAdviceInput(
            kind:              mealKind,
            timestamp:         timestamp,
            dishes:            dishes,
            currentMealStats:  currentStats,
            nutritionAverage:  nutritionAverage,
            userProfile:       userProfile
        )
    }

    // MARK: - Private Helpers

    private static func calculateCurrentMealStats(from analysis: FoodAnalysisResult) -> CurrentMealStats {
        var totalCalories: Double = 0
        var totalWeight:   Double = 0
        var totalProtein:  Double = 0
        var totalFat:      Double = 0
        var totalCarbs:    Double = 0

        for dish in analysis.dishes {
            for ingredient in dish.ingredients {
                let protein = ingredient.weight * ingredient.proteinPercent / 100
                let fat     = ingredient.weight * ingredient.fatPercent / 100
                let carbs   = ingredient.weight * ingredient.carbohydratePercent / 100
                totalCalories += (protein * 4) + (fat * 9) + (carbs * 4)
                totalWeight   += ingredient.weight
                totalProtein  += protein
                totalFat      += fat
                totalCarbs    += carbs
            }
        }
        return CurrentMealStats(
            totalcalories:     totalCalories,
            totalweight:       totalWeight,
            totalprotein:      totalProtein,
            totalfat:          totalFat,
            totalcarbohydrate: totalCarbs
        )
    }

    private static func determineMealKind() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<10:  return "Breakfast"
        case 10..<15: return "Lunch"
        case 15..<22: return "Dinner"
        default:      return "Snack"
        }
    }
}

//
//  GeminiNutritionPlanner.swift
//  FoodShutter
//
//  Nutrition target generation — delegates to backend API
//

import Foundation

class GeminiNutritionPlanner {

    private let backend = BackendAPIClient.shared

    /// Generate personalized nutrition targets based on user profile
    func generateNutritionTargets(profile: UserNutritionProfile) async throws -> NutritionTargetsResult {
        print("🎯 Generating nutrition targets via backend...")

        guard profile.weight > 0, profile.height > 0, profile.age > 0 else {
            throw NutritionPlannerError.invalidProfile
        }

        let result = try await backend.generateNutritionTargets(profile: profile)
        print("✓ Nutrition targets generated successfully")
        return result
    }
}

// MARK: - Error Types (kept for backward compatibility)

enum NutritionPlannerError: Error, LocalizedError {
    case invalidURL
    case invalidProfile
    case requestFailed
    case noValidResponse
    case invalidJSON
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidProfile:
            return "Invalid user profile data (weight, height, or age is invalid)"
        case .requestFailed:
            return "Request failed"
        case .noValidResponse:
            return "No valid response received from API"
        case .invalidJSON:
            return "Invalid JSON response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

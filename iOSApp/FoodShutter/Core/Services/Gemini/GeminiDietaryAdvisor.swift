//
//  GeminiDietaryAdvisor.swift
//  FoodShutter
//
//  Dietary advice — delegates to backend API
//

import Foundation

class GeminiDietaryAdvisor {

    private let backend = BackendAPIClient.shared

    /// Get dietary advice based on user's meal data and profile
    func getDietaryAdvice(input: DietaryAdviceInput) async throws -> DietaryAdviceResult {
        print("🧠 Requesting dietary advice from backend...")
        let result = try await backend.getDietaryAdvice(input: input)
        print("✅ Dietary advice received!")
        return result
    }
}

// MARK: - Error Types (kept for backward compatibility)

enum DietaryAdvisorError: Error, LocalizedError {
    case invalidURL
    case invalidInputData
    case requestFailed
    case noValidResponse
    case invalidJSON
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidInputData:
            return "Invalid input data"
        case .requestFailed:
            return "Request failed"
        case .noValidResponse:
            return "No valid response received"
        case .invalidJSON:
            return "Invalid JSON response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

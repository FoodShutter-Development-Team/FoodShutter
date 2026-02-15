//
//  GeminiFoodImageAnalyzer.swift
//  FoodShutter
//
//  Food image analysis — delegates to backend API
//

import Foundation

class GeminiFoodImageAnalyzer {

    private let backend = BackendAPIClient.shared

    /// Analyze food image and return structured nutrition data
    /// - Parameter imageURL: Local file URL of the image
    /// - Returns: FoodAnalysisResult containing dishes and ingredients
    func analyzeFoodImage(imageURL: URL) async throws -> FoodAnalysisResult {
        print("📤 Uploading image to backend for analysis...")
        let result = try await backend.analyzeFoodImage(imageURL: imageURL)
        print("✅ Analysis complete!")
        return result
    }
}

// MARK: - Error Types (kept for backward compatibility)

enum FoodImageAnalyzerError: Error, LocalizedError {
    case fileReadError
    case invalidURL
    case uploadInitializationFailed
    case uploadFailed
    case analysisRequestFailed
    case noValidResponse
    case invalidJSON
    case apiError(message: String)

    var errorDescription: String? {
        switch self {
        case .fileReadError:
            return "Unable to read image file"
        case .invalidURL:
            return "Invalid URL"
        case .uploadInitializationFailed:
            return "File upload initialization failed"
        case .uploadFailed:
            return "File upload failed"
        case .analysisRequestFailed:
            return "Analysis request failed"
        case .noValidResponse:
            return "No valid response received"
        case .invalidJSON:
            return "Invalid JSON response"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

//
//  BackendAPIClient.swift
//  FoodShutter
//
//  Backend API client that authenticates requests with a Supabase JWT
//

import Foundation
import Supabase

final class BackendAPIClient {

    // MARK: - Configuration

    static let baseURL = "http://192.168.28.80:8000"
    static let shared  = BackendAPIClient()

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Upload Meal

    /// POST /analyze（multipart）→ job_id (= meal_id)
    func uploadMeal(imageData: Data, mealType: MealType) async throws -> UUID {
        guard let url = URL(string: BackendAPIClient.baseURL + "/analyze") else {
            throw BackendAPIError.invalidURL
        }

        let data = try await performMultipart(
            url: url,
            imageData: imageData,
            mealType: mealType,
            retryOnUnauthorized: true
        )

        let response = try JSONDecoder().decode(AnalyzeResponse.self, from: data)
        return response.jobId
    }

    // MARK: - Private: Multipart Request

    private func performMultipart(
        url: URL,
        imageData: Data,
        mealType: MealType,
        retryOnUnauthorized: Bool
    ) async throws -> Data {
        guard let accessToken = try await getAccessToken() else {
            throw BackendAPIError.unauthorized
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = buildMultipartBody(imageData: imageData, mealType: mealType, boundary: boundary)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.requestFailed
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            guard retryOnUnauthorized else { throw BackendAPIError.unauthorized }
            try await supabase.auth.refreshSession()
            return try await performMultipart(
                url: url,
                imageData: imageData,
                mealType: mealType,
                retryOnUnauthorized: false
            )
        case 413:
            throw BackendAPIError.imageTooLarge
        case 415:
            throw BackendAPIError.unsupportedFormat
        default:
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorBody["error"] as? String {
                throw BackendAPIError.serverError(message: message)
            }
            throw BackendAPIError.requestFailed
        }
    }

    // MARK: - Private: Helpers

    private func getAccessToken() async throws -> String? {
        return try await supabase.auth.session.accessToken
    }

    private func buildMultipartBody(imageData: Data, mealType: MealType, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"

        // meal_type field
        body += "--\(boundary)\(crlf)".utf8Data
        body += "Content-Disposition: form-data; name=\"meal_type\"\(crlf)\(crlf)".utf8Data
        body += mealType.rawValue.utf8Data
        body += crlf.utf8Data

        // image file field
        body += "--\(boundary)\(crlf)".utf8Data
        body += "Content-Disposition: form-data; name=\"image\"; filename=\"meal.jpg\"\(crlf)".utf8Data
        body += "Content-Type: image/jpeg\(crlf)\(crlf)".utf8Data
        body += imageData
        body += crlf.utf8Data

        body += "--\(boundary)--\(crlf)".utf8Data
        return body
    }
}

// MARK: - Response Models

private struct AnalyzeResponse: Decodable {
    let jobId: UUID

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
    }
}

// MARK: - Error Types

enum BackendAPIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case imageTooLarge
    case unsupportedFormat
    case requestFailed
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL"
        case .unauthorized:
            return "Authentication failed. Please sign in again."
        case .imageTooLarge:
            return "Image exceeds 20 MB limit. Please use a smaller photo."
        case .unsupportedFormat:
            return "Unsupported image format. Please use JPEG, PNG, HEIC, or WebP."
        case .requestFailed:
            return "Server request failed. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Data Helper

private extension Data {
    static func += (lhs: inout Data, rhs: Data) {
        lhs.append(rhs)
    }

    var utf8Data: Data { self }
}

private extension String {
    var utf8Data: Data { Data(utf8) }
}

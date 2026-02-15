//
//  BackendAPIClient.swift
//  FoodShutter
//
//  统一的后端 API 客户端，携带 Supabase JWT 进行鉴权
//

import Foundation
import Supabase

final class BackendAPIClient {

    // MARK: - Configuration

    /// 后端 Base URL（上线前替换为你的正式地址）
    static let baseURL = "https://your-backend.example.com/api"

    static let shared = BackendAPIClient()

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public: Food Image Analysis

    /// 将图片编码为 base64 发送到后端，返回食物分析结果
    func analyzeFoodImage(imageURL: URL) async throws -> FoodAnalysisResult {
        guard let imageData = try? Data(contentsOf: imageURL) else {
            throw BackendAPIError.fileReadError
        }

        let base64String = imageData.base64EncodedString()
        let mimeType = getMimeType(for: imageURL)

        let body: [String: Any] = [
            "imageBase64": base64String,
            "mimeType": mimeType
        ]

        let data = try await post(endpoint: "/analyze-food", body: body)
        return try JSONDecoder().decode(FoodAnalysisResult.self, from: data)
    }

    // MARK: - Public: Dietary Advice

    /// 发送餐食数据到后端，获取饮食建议
    func getDietaryAdvice(input: DietaryAdviceInput) async throws -> DietaryAdviceResult {
        let encoder = JSONEncoder()
        let inputData = try encoder.encode(input)
        let inputDict = try JSONSerialization.jsonObject(with: inputData) as? [String: Any] ?? [:]

        let data = try await post(endpoint: "/dietary-advice", body: inputDict)
        return try JSONDecoder().decode(DietaryAdviceResult.self, from: data)
    }

    // MARK: - Public: Nutrition Plan

    /// 发送用户资料到后端，生成个性化营养目标
    func generateNutritionTargets(profile: UserNutritionProfile) async throws -> NutritionTargetsResult {
        let encoder = JSONEncoder()
        let profileData = try encoder.encode(profile)
        let profileDict = try JSONSerialization.jsonObject(with: profileData) as? [String: Any] ?? [:]

        let data = try await post(endpoint: "/nutrition-plan", body: profileDict)
        return try JSONDecoder().decode(NutritionTargetsResult.self, from: data)
    }

    // MARK: - Private: Networking

    private func post(endpoint: String, body: [String: Any]) async throws -> Data {
        guard let url = URL(string: BackendAPIClient.baseURL + endpoint) else {
            throw BackendAPIError.invalidURL
        }

        // 获取 Supabase access token
        guard let accessToken = try await getAccessToken() else {
            throw BackendAPIError.unauthorized
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 120  // 图片分析可能较慢

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.requestFailed
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw BackendAPIError.unauthorized
        case 429:
            throw BackendAPIError.rateLimited
        default:
            // 尝试解析后端错误信息
            if let errorBody = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = errorBody["error"] as? String {
                throw BackendAPIError.serverError(message: message)
            }
            throw BackendAPIError.requestFailed
        }
    }

    private func getAccessToken() async throws -> String? {
        return try await supabase.auth.session.accessToken
    }

    private func getMimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png":  return "image/png"
        case "heic": return "image/heic"
        case "webp": return "image/webp"
        default:     return "image/jpeg"
        }
    }
}

// MARK: - Error Types

enum BackendAPIError: Error, LocalizedError {
    case fileReadError
    case invalidURL
    case unauthorized
    case rateLimited
    case requestFailed
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .fileReadError:
            return "Unable to read image file"
        case .invalidURL:
            return "Invalid backend URL"
        case .unauthorized:
            return "Authentication failed. Please sign in again."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .requestFailed:
            return "Server request failed"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

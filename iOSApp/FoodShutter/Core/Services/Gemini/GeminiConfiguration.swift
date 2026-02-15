//
//  GeminiConfiguration.swift
//  FoodShutter
//
//  后端 API 配置（API Key 已移至后端，前端仅需配置后端地址）
//

import Foundation

struct GeminiConfiguration {
    /// 后端地址引用（与 BackendAPIClient.baseURL 保持一致）
    static var backendBaseURL: String {
        BackendAPIClient.baseURL
    }
}

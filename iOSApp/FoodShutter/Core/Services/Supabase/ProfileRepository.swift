//
//  ProfileRepository.swift
//  FoodShutter
//
//  用户资料的云端 CRUD（替换 UserProfileManager）
//

import Foundation
import Supabase

@MainActor
final class ProfileRepository {
    static let shared = ProfileRepository()

    private init() {}

    // MARK: - Profile CRUD

    /// 获取当前用户的资料
    func getProfile() async throws -> ProfileRow? {
        guard let userId = AuthManager.shared.userId else { return nil }
        let rows: [ProfileRow] = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// 检查当前用户是否已有资料
    func hasProfile() async throws -> Bool {
        let profile = try await getProfile()
        return profile != nil
    }

    /// 创建或更新用户资料
    func upsertProfile(_ profile: UserNutritionProfile) async throws {
        guard let userId = AuthManager.shared.userId else {
            throw RepositoryError.notAuthenticated
        }
        let upsertData = ProfileUpsert.from(profile, userId: userId)
        try await supabase
            .from("profiles")
            .upsert(upsertData)
            .execute()
    }

    /// 保存营养目标（单独更新 nutrition_targets 列）
    func saveNutritionTargets(_ targets: NutritionTargets) async throws {
        guard let userId = AuthManager.shared.userId else {
            throw RepositoryError.notAuthenticated
        }
        let update = ProfileTargetsUpdate(
            nutritionTargets:   NutritionTargetsRow.from(targets),
            targetsGeneratedAt: targets.generatedDate
        )
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }

    /// 获取营养目标（若不存在或已过期 30 天则返回 nil）
    func getNutritionTargets() async throws -> NutritionTargets? {
        guard let row = try await getProfile() else { return nil }
        guard let targets = row.toNutritionTargets() else { return nil }

        // 30 天有效期检查
        let daysSince = Calendar.current.dateComponents(
            [.day], from: targets.generatedDate, to: Date()
        ).day ?? 999
        return daysSince < 30 ? targets : nil
    }

    /// 通过后端 AI 生成并保存营养目标
    func generateNutritionTargets() async throws {
        guard let row = try await getProfile() else {
            throw RepositoryError.profileNotFound
        }
        let profile = row.toUserNutritionProfile()
        let planner = GeminiNutritionPlanner()
        let result  = try await planner.generateNutritionTargets(profile: profile)
        let targets = NutritionTargets(from: result)
        try await saveNutritionTargets(targets)
    }

    /// 删除用户资料（级联删除所有关联数据）
    func deleteProfile() async throws {
        guard let userId = AuthManager.shared.userId else { return }
        try await supabase
            .from("profiles")
            .delete()
            .eq("id", value: userId)
            .execute()
    }
}

// MARK: - Repository Errors

enum RepositoryError: Error, LocalizedError {
    case notAuthenticated
    case profileNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "User is not authenticated"
        case .profileNotFound:  return "User profile not found"
        }
    }
}

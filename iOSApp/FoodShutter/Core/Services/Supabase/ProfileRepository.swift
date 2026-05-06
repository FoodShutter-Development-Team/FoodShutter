//
//  ProfileRepository.swift
//  FoodShutter
//
//  Cloud CRUD operations for user profiles (replaces UserProfileManager)
//

import Foundation
import Supabase

@MainActor
final class ProfileRepository {
    static let shared = ProfileRepository()

    private init() {}

    // MARK: - Profile CRUD

    /// Fetch the current user's profile
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

    /// Check whether the current user already has a profile
    func hasProfile() async throws -> Bool {
        let profile = try await getProfile()
        return profile != nil
    }

    /// Create or update the user's profile
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

    /// Save nutrition targets (updates only the nutrition_targets column)
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

    /// Fetch nutrition targets (returns nil if absent or older than 30 days)
    func getNutritionTargets() async throws -> NutritionTargets? {
        guard let row = try await getProfile() else { return nil }
        guard let targets = row.toNutritionTargets() else { return nil }

        // 30-day validity check
        let daysSince = Calendar.current.dateComponents(
            [.day], from: targets.generatedDate, to: Date()
        ).day ?? 999
        return daysSince < 30 ? targets : nil
    }

    /// Delete the user's profile (cascades to all associated data)
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

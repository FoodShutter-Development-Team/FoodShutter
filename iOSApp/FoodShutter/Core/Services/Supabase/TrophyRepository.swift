//
//  TrophyRepository.swift
//  FoodShutter
//
//  Cloud storage and detection for trophies (replaces TrophyManager)
//

import Foundation
import Supabase

@MainActor
final class TrophyRepository {
    static let shared = TrophyRepository()

    private init() {}

    // MARK: - Trophy Detection

    /// Check for and award new trophies (call after saving a meal)
    func checkForNewTrophies() async -> [Trophy] {
        let targets: NutritionTargets?
        do {
            targets = try await ProfileRepository.shared.getNutritionTargets()
        } catch {
            print("⚠️ Could not load nutrition targets: \(error.localizedDescription)")
            return []
        }
        guard let targets else {
            print("⚠️ No nutrition targets set, skipping trophy check")
            return []
        }

        var newTrophies: [Trophy] = []
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())

        let dailyTotals = await calculateDailyTotals(goingBack: 7, from: today)

        // Single-day goal met
        if let todayStats = dailyTotals.first,
           targets.isAllNutrientsInRange(
               calories: todayStats.calories,
               protein:  todayStats.protein,
               fat:      todayStats.fat,
               carb:     todayStats.carbohydrate
           ),
           !(await hasTrophy(type: .singleDay, forDate: today)) {
            let trophy = Trophy(
                id: UUID(), type: .singleDay, earnedDate: Date(), streakDays: 1,
                calories: todayStats.calories, protein: todayStats.protein,
                fat: todayStats.fat, carbohydrate: todayStats.carbohydrate
            )
            newTrophies.append(trophy)
        }

        // 3-day streak
        if dailyTotals.count >= 3 {
            let last3 = Array(dailyTotals.prefix(3))
            let streakStart = calendar.date(byAdding: .day, value: -2, to: today)!
            if allDaysInRange(last3, targets: targets),
               !(await hasTrophy(type: .threeDay, forDate: streakStart)) {
                let avg = average(last3)
                newTrophies.append(Trophy(
                    id: UUID(), type: .threeDay, earnedDate: Date(), streakDays: 3,
                    calories: avg.calories, protein: avg.protein,
                    fat: avg.fat, carbohydrate: avg.carbohydrate
                ))
            }
        }

        // 7-day streak
        if dailyTotals.count >= 7 {
            let last7 = Array(dailyTotals.prefix(7))
            let streakStart = calendar.date(byAdding: .day, value: -6, to: today)!
            if allDaysInRange(last7, targets: targets),
               !(await hasTrophy(type: .sevenDay, forDate: streakStart)) {
                let avg = average(last7)
                newTrophies.append(Trophy(
                    id: UUID(), type: .sevenDay, earnedDate: Date(), streakDays: 7,
                    calories: avg.calories, protein: avg.protein,
                    fat: avg.fat, carbohydrate: avg.carbohydrate
                ))
            }
        }

        // Save new trophies
        for trophy in newTrophies {
            try? await saveTrophy(trophy)
        }

        return newTrophies
    }

    // MARK: - CRUD

    func fetchAllTrophies() async throws -> [Trophy] {
        guard let userId = AuthManager.shared.userId else { return [] }
        let rows: [TrophyRow] = try await supabase
            .from("trophies")
            .select()
            .eq("user_id", value: userId)
            .order("earned_date", ascending: false)
            .execute()
            .value
        return rows.map { $0.toTrophy() }
    }

    func saveTrophyDirectly(_ trophy: Trophy) async throws {
        try await saveTrophy(trophy)
    }

    /// Insert a few historical trophies if the user has none (demo seeding).
    func seedDemoTrophiesIfNeeded() async {
        guard let userId = AuthManager.shared.userId else { return }
        let existing = (try? await fetchAllTrophies()) ?? []
        guard existing.isEmpty else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        func daysAgo(_ n: Int) -> String {
            let d = cal.date(byAdding: .day, value: -n, to: today) ?? today
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: d)
        }

        let seeds: [(type: String, daysAgo: Int, streak: Int, cal: Double, pro: Double, fat: Double, carb: Double)] = [
            ("single_day", 9,  1, 1923, 87, 64, 241),
            ("single_day", 6,  1, 1978, 94, 61, 256),
            ("three_day",  5,  3, 1952, 89, 63, 248),
            ("single_day", 2,  1, 1961, 91, 67, 239),
        ]

        for s in seeds {
            let insert = TrophyInsert(
                id:                UUID(),
                userId:            userId,
                trophyType:        s.type,
                earnedDate:        daysAgo(s.daysAgo),
                streakDays:        s.streak,
                nutritionSnapshot: TrophyNutritionSnapshot(
                    calories: s.cal, protein: s.pro, fat: s.fat, carbohydrate: s.carb
                )
            )
            try? await supabase.from("trophies").insert(insert).execute()
        }
        print("🏆 Demo trophies seeded")
    }

    // MARK: - Private Helpers

    private struct DayStats {
        let date: Date
        let calories, protein, fat, carbohydrate: Double
    }

    private func calculateDailyTotals(goingBack days: Int, from endDate: Date) async -> [DayStats] {
        let calendar = Calendar.current
        var results: [DayStats] = []

        for offset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: endDate),
                  let dayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: targetDate),
                  let dayEnd   = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            guard let meals = try? await MealRepository.shared.fetchMeals(from: dayStart, to: dayEnd),
                  !meals.isEmpty else { break }

            results.append(DayStats(
                date:         dayStart,
                calories:     meals.reduce(0) { $0 + $1.totalCalories },
                protein:      meals.reduce(0) { $0 + $1.totalProtein },
                fat:          meals.reduce(0) { $0 + $1.totalFat },
                carbohydrate: meals.reduce(0) { $0 + $1.totalCarbohydrate }
            ))
        }
        return results
    }

    private func allDaysInRange(_ days: [DayStats], targets: NutritionTargets) -> Bool {
        days.allSatisfy {
            targets.isAllNutrientsInRange(
                calories: $0.calories, protein: $0.protein,
                fat: $0.fat, carb: $0.carbohydrate
            )
        }
    }

    private func average(_ days: [DayStats]) -> DayStats {
        let n = Double(days.count)
        return DayStats(
            date:         Date(),
            calories:     days.reduce(0) { $0 + $1.calories }     / n,
            protein:      days.reduce(0) { $0 + $1.protein }      / n,
            fat:          days.reduce(0) { $0 + $1.fat }          / n,
            carbohydrate: days.reduce(0) { $0 + $1.carbohydrate } / n
        )
    }

    private func hasTrophy(type: TrophyType, forDate date: Date) async -> Bool {
        guard let userId = AuthManager.shared.userId else { return false }
        let calendar = Calendar.current
        let daysBack: Int
        switch type {
        case .singleDay: daysBack = 1
        case .threeDay:  daysBack = 3
        case .sevenDay:  daysBack = 7
        }
        guard let windowStart = calendar.date(byAdding: .day, value: -daysBack, to: date) else { return false }

        let iso = ISO8601DateFormatter()
        let count: Int = (try? await supabase
            .from("trophies")
            .select("id", head: false)
            .eq("user_id", value: userId)
            .eq("trophy_type", value: type.rawValue)
            .gte("earned_date", value: iso.string(from: windowStart))
            .lte("earned_date", value: iso.string(from: Date()))
            .execute()
            .value as [TrophyRow])?.count ?? 0
        return count > 0
    }

    private func saveTrophy(_ trophy: Trophy) async throws {
        guard let userId = AuthManager.shared.userId else {
            throw RepositoryError.notAuthenticated
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let insert = TrophyInsert(
            id:                UUID(),
            userId:            userId,
            trophyType:        trophy.type.rawValue,
            earnedDate:        formatter.string(from: trophy.earnedDate),
            streakDays:        trophy.streakDays,
            nutritionSnapshot: TrophyNutritionSnapshot(
                calories:     trophy.calories,
                protein:      trophy.protein,
                fat:          trophy.fat,
                carbohydrate: trophy.carbohydrate
            )
        )
        try await supabase.from("trophies").insert(insert).execute()
        print("🏆 Trophy saved: \(trophy.type.title)")
    }
}

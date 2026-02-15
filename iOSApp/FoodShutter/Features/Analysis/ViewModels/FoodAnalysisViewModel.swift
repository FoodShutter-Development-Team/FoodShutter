//
//  FoodAnalysisViewModel.swift
//  FoodShutter
//
//  主 ViewModel：食物分析流程 + 云端保存（Supabase 版）
//

import SwiftUI
import UIKit
import Combine

/// 分析流程状态
enum AnalysisState {
    case idle
    case uploadingImage
    case analyzingFood
    case transformingData
    case fetchingAdvice
    case completed
    case failed(Error)
}

extension AnalysisState: Equatable {
    static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.uploadingImage, .uploadingImage),
             (.analyzingFood, .analyzingFood), (.transformingData, .transformingData),
             (.fetchingAdvice, .fetchingAdvice), (.completed, .completed):
            return true
        case let (.failed(l), .failed(r)):
            let le = l as NSError, re = r as NSError
            return le.domain == re.domain && le.code == re.code
                && type(of: l) == type(of: r)
        default:
            return false
        }
    }
}

enum AnalysisError: Error, LocalizedError {
    case noFoodDetected
    case partialSuccess(String)

    var errorDescription: String? {
        switch self {
        case .noFoodDetected:
            return "No food detected in the image. Please try again with a clearer photo."
        case .partialSuccess(let message):
            return message
        }
    }
}

@MainActor
class FoodAnalysisViewModel: ObservableObject {
    // MARK: - Published State
    @Published var state:         AnalysisState = .idle
    @Published var dishes:        [Dish]        = []
    @Published var dietaryAdvice: DietaryAdviceResult?
    @Published var errorMessage:  String?

    // MARK: - Private
    private let foodAnalyzer          = GeminiFoodImageAnalyzer()
    private let dietaryAdvisor        = GeminiDietaryAdvisor()
    private var currentAnalysisResult: FoodAnalysisResult?
    private var capturedImage:         UIImage?

    // MARK: - Analysis Flow

    func analyzeFood(from image: UIImage) async {
        self.capturedImage = image

        do {
            state = .uploadingImage
            let tempURL = try ModelTransformers.saveImageToTempFile(image)

            state = .analyzingFood
            let analysisResult = try await foodAnalyzer.analyzeFoodImage(imageURL: tempURL)

            guard !analysisResult.dishes.isEmpty else {
                throw AnalysisError.noFoodDetected
            }
            currentAnalysisResult = analysisResult

            state = .transformingData
            dishes = ModelTransformers.transformToDishes(analysisResult)

            state = .fetchingAdvice
            await fetchDietaryAdvice()

            state = .completed
            try? FileManager.default.removeItem(at: tempURL)

        } catch let error as FoodImageAnalyzerError {
            state = .failed(error)
            errorMessage = "Food analysis failed: \(error.localizedDescription)"
        } catch let error as DietaryAdvisorError {
            state = .completed
            errorMessage = "Dietary advice unavailable: \(error.localizedDescription)"
        } catch let error as AnalysisError {
            state = .failed(error)
            errorMessage = error.localizedDescription
        } catch {
            state = .failed(error)
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Helpers

    private func fetchDietaryAdvice() async {
        guard let analysisResult = currentAnalysisResult else { return }
        do {
            // 从 Supabase 获取用户资料
            let userProfile: UserNutritionProfile
            if let row = try? await ProfileRepository.shared.getProfile() {
                userProfile = row.toUserNutritionProfile()
            } else {
                userProfile = UserNutritionProfile(
                    weight: 70, height: 170, age: 25, gender: "Male",
                    activityLevel: "Moderate", goals: [], preference: "", other: ""
                )
            }

            // 获取近期营养均值
            let nutritionAvg = await MealRepository.shared.getNutritionAverage()

            let adviceInput = ModelTransformers.createDietaryAdviceInput(
                from: analysisResult,
                userProfile: userProfile,
                nutritionAverage: nutritionAvg
            )
            dietaryAdvice = try await dietaryAdvisor.getDietaryAdvice(input: adviceInput)
            print("✓ Dietary advice received")
        } catch {
            print("⚠️ Failed to fetch dietary advice: \(error.localizedDescription)")
        }
    }

    // MARK: - Public

    func reset() {
        state                = .idle
        dishes               = []
        dietaryAdvice        = nil
        errorMessage         = nil
        currentAnalysisResult = nil
    }

    func retry(with image: UIImage) async {
        reset()
        await analyzeFood(from: image)
    }

    // MARK: - Meal Persistence（异步版本）

    /// 保存餐食并检查奖杯（async，由调用者用 Task 包装）
    func saveMealIfNeeded() async -> [Trophy] {
        guard !dishes.isEmpty else {
            print("⚠️ No dishes to save")
            return []
        }

        let mealType = MealType.determine()

        do {
            _ = try await MealRepository.shared.saveMeal(
                timestamp:     Date(),
                mealType:      mealType,
                photo:         capturedImage,
                dishes:        dishes,
                dietaryAdvice: dietaryAdvice
            )
            print("✓ Meal saved to Supabase: \(mealType.rawValue)")

            let newTrophies = await TrophyRepository.shared.checkForNewTrophies()
            if !newTrophies.isEmpty {
                print("🏆 \(newTrophies.count) new trophy(ies) earned!")
            }
            return newTrophies
        } catch {
            print("⚠️ Failed to save meal: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Cleanup

    deinit { cleanupTempFiles() }

    nonisolated private func cleanupTempFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        if let files = try? FileManager.default.contentsOfDirectory(
            at: tempDir, includingPropertiesForKeys: nil
        ) {
            for file in files where file.lastPathComponent.hasPrefix("food_") {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
}

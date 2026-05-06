//
//  FoodAnalysisViewModel.swift
//  FoodShutter
//
//  两阶段异步分析流程：上传 → 等待 → 菜品就绪 → 营养完成
//

import SwiftUI
import UIKit

// MARK: - State

enum AnalysisState: Equatable {
    case idle
    case uploading
    case awaitingDishes
    case dishesReady
    case computingNutrition
    case complete
    case failed(String)

    static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.uploading, .uploading),
             (.awaitingDishes, .awaitingDishes), (.dishesReady, .dishesReady),
             (.computingNutrition, .computingNutrition), (.complete, .complete):
            return true
        case let (.failed(l), .failed(r)):
            return l == r
        default:
            return false
        }
    }

    var loadingMessage: String {
        switch self {
        case .uploading:           return "Uploading photo..."
        case .awaitingDishes:      return "Identifying dishes..."
        case .computingNutrition:  return "Analyzing nutrition..."
        default:                   return "Relax a Bit :)"
        }
    }

    var isLoading: Bool {
        switch self {
        case .uploading, .awaitingDishes, .computingNutrition: return true
        default: return false
        }
    }
}

// MARK: - ViewModel

@MainActor
final class FoodAnalysisViewModel: ObservableObject {
    @Published var state:       AnalysisState = .idle
    @Published var dishes:      [Dish]        = []
    @Published var mealAdvice:  MealAdviceRow?
    @Published var newTrophies: [Trophy]      = []

    private var currentMealId: UUID?

    // MARK: - Main Entry Point

    func analyzeFood(from image: UIImage) async {
        reset()

        do {
            // Step 1: Compress and upload
            state = .uploading
            let jpegData = try ModelTransformers.imageToJPEGData(image)
            let mealType = MealType.determine()
            let mealId   = try await BackendAPIClient.shared.uploadMeal(imageData: jpegData, mealType: mealType)
            currentMealId = mealId

            // Step 2: Observe async pipeline
            state = .awaitingDishes
            let observer = MealStatusObserver(mealId: mealId)

            for await event in observer.stream() {
                switch event {
                case .dishesReady:
                    await handleDishesReady(mealId: mealId)

                case .complete:
                    await handleComplete(mealId: mealId)
                    return

                case .failed(let reason):
                    state = .failed(reason ?? "Analysis failed. Please try again.")
                    return

                case .timeout:
                    state = .failed("Analysis timed out. Please try again.")
                    return
                }
            }

        } catch let error as BackendAPIError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed("Unexpected error: \(error.localizedDescription)")
        }
    }

    // MARK: - Phase Handlers

    private func handleDishesReady(mealId: UUID) async {
        do {
            let rows = try await MealRepository.shared.fetchDishesPhase1(mealId: mealId)
            dishes = rows.map { $0.toDish() }
            state  = .dishesReady
        } catch {
            print("⚠️ Phase 1 fetch failed: \(error)")
        }
    }

    private func handleComplete(mealId: UUID) async {
        state = .computingNutrition
        do {
            let rows = try await MealRepository.shared.fetchDishesPhase2(mealId: mealId)
            dishes    = rows.map { $0.toDish() }
            mealAdvice = try? await MealRepository.shared.fetchAdvice(mealId: mealId)
        } catch {
            print("⚠️ Phase 2 fetch failed: \(error)")
        }

        newTrophies = await TrophyRepository.shared.checkForNewTrophies()
        state = .complete
    }

    // MARK: - Retry

    func retry(with image: UIImage) async {
        reset()
        await analyzeFood(from: image)
    }

    // MARK: - Reset

    func reset() {
        state         = .idle
        dishes        = []
        mealAdvice    = nil
        newTrophies   = []
        currentMealId = nil
    }
}

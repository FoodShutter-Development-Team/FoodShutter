//
//  AnalysisContainerView.swift
//  FoodShutter
//

import SwiftUI

struct AnalysisResultView: View {
    let capturedImage: UIImage
    @EnvironmentObject var viewModel: FoodAnalysisViewModel

    var body: some View {
        ZStack {
            Color.backGround

            switch viewModel.state {

            case .idle, .uploading, .awaitingDishes:
                loadingView(message: viewModel.state.loadingMessage)

            case .dishesReady, .computingNutrition, .complete:
                DishListView(capturedImage: capturedImage)

            case .failed(let message):
                ErrorView(error: AnalysisError(message: message)) {
                    Task { await viewModel.analyzeFood(from: capturedImage) }
                }
            }
        }
        .ignoresSafeArea()
        .task {
            await viewModel.analyzeFood(from: capturedImage)
        }
    }

    private func loadingView(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundStyle(.mainText)
                .font(.system(.largeTitle, design: .serif, weight: .heavy))
                .padding()
                .multilineTextAlignment(.center)
            TypingAnimationText()
                .frame(height: 20)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Bridging Error Type

struct AnalysisError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

#Preview {
    @Previewable @StateObject var viewModel = FoodAnalysisViewModel()
    AnalysisResultView(capturedImage: UIImage())
        .environmentObject(viewModel)
}

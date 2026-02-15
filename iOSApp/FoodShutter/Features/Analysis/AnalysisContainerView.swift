//
//  AnalysisContainerView.swift
//  FoodShutter
//
//  Main container for food analysis results with loading state
//

import SwiftUI

struct AnalysisResultView: View {
    let capturedImage: UIImage
    @EnvironmentObject var viewModel: FoodAnalysisViewModel

    var body: some View {
        ZStack {
            Color.backGround

            switch viewModel.state {
            case .idle, .uploadingImage, .analyzingFood, .transformingData:
                // Loading view
                VStack {
                    Spacer()
                    Text("Relax a Bit :)")
                        .foregroundStyle(.mainText)
                        .font(.system(.largeTitle, design: .serif, weight: .heavy))
                        .padding()
                    TypingAnimationText()
                        .frame(height: 20)
                    Spacer()
                }
                .padding()

            case .fetchingAdvice, .completed:
                // Show dish list (advice loading in background)
                DishListView()

            case .failed(let error):
                // Error view with retry
                ErrorView(error: error) {
                    Task {
                        await viewModel.analyzeFood(from: capturedImage)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .task {
            await viewModel.analyzeFood(from: capturedImage)
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = FoodAnalysisViewModel()

    AnalysisResultView(capturedImage: UIImage())
        .environmentObject(viewModel)
}

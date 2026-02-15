//
//  DishListView.swift
//  FoodShutter
//
//  菜品列表视图 - 显示所有菜品并支持导航到详情
//

import SwiftUI

struct DishListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: FoodAnalysisViewModel
    @State private var animatedDishes:     [Dish]   = []
    @State private var showSuggestion:     Bool     = false
    @State private var selectedDish:       Dish?    = nil
    @State private var isSaving:           Bool     = false
    @Namespace private var heroAnimationNamespace

    // Trophy popup state
    @State private var earnedTrophies:    [Trophy] = []
    @State private var showTrophyPopup:   Bool     = false
    @State private var currentTrophyIndex: Int     = 0

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
    }

    var body: some View {
        ZStack {
            if selectedDish == nil {
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)

                        NutritionSummaryView(
                            ingredients: allIngredients,
                            title: "All Dishes"
                        )
                        .padding(.horizontal, 10)

                        VStack(spacing: 10) {
                            ForEach(Array(animatedDishes.enumerated()), id: \.element.id) { index, dish in
                                DishCardView(dish: dish, namespace: heroAnimationNamespace)
                                    .padding(.vertical, 10)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            selectedDish = dish
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)

                        if showSuggestion {
                            if viewModel.dietaryAdvice != nil {
                                SuggestionView()
                            } else {
                                analyzingFooter
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
            }

            if let dish = selectedDish {
                DishDetailView(
                    dish: dish,
                    namespace: heroAnimationNamespace,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            selectedDish = nil
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .onChange(of: viewModel.dishes) { _, newDishes in
            animateDishesAppearing(newDishes)
        }
        .onAppear {
            if animatedDishes.isEmpty && !viewModel.dishes.isEmpty {
                animateDishesAppearing(viewModel.dishes)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedDish == nil {
                Button {
                    Task { await saveAndContinue() }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.mainEnable)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(.title2, design: .serif, weight: .bold))
                                .foregroundStyle(.mainEnable)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .glassEffect(.regular.interactive(), in: Circle())
                }
                .padding(30)
                .disabled(isSaving)
            }
        }
        .overlay {
            if showTrophyPopup, currentTrophyIndex < earnedTrophies.count {
                TrophyPopupView(
                    trophy: earnedTrophies[currentTrophyIndex],
                    onDismiss: {
                        if currentTrophyIndex < earnedTrophies.count - 1 {
                            currentTrophyIndex += 1
                        } else {
                            showTrophyPopup    = false
                            earnedTrophies     = []
                            currentTrophyIndex = 0
                            dismiss()
                        }
                    }
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Save Action

    private func saveAndContinue() async {
        isSaving = true
        defer { isSaving = false }

        let newTrophies = await viewModel.saveMealIfNeeded()
        if !newTrophies.isEmpty {
            earnedTrophies    = newTrophies
            currentTrophyIndex = 0
            showTrophyPopup   = true
        } else {
            dismiss()
        }
    }

    // MARK: - Helpers

    private var analyzingFooter: some View {
        TypingAnimationText(fullText: "Analyzing...")
            .frame(height: 20)
            .padding(.bottom, 12)
    }

    private var allIngredients: [FoodIngredient] {
        animatedDishes.flatMap { $0.ingredients }
    }

    private func animateDishesAppearing(_ dishes: [Dish]) {
        if isPreview {
            animatedDishes = dishes
            showSuggestion = true
            return
        }

        animatedDishes = []
        for (index, dish) in dishes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    animatedDishes.append(dish)
                }
            }
        }

        let delay = Double(dishes.count) * 0.2 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation { showSuggestion = true }
        }
    }
}

#Preview {
    DishListPreviewWrapper()
}

private struct DishListPreviewWrapper: View {
    @StateObject private var viewModel: FoodAnalysisViewModel

    init() {
        let vm = FoodAnalysisViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        Task { @MainActor in
            vm.dishes = Dish.sampleData
            vm.state  = .completed
            vm.dietaryAdvice = .sample
        }
    }

    var body: some View {
        DishListView().environmentObject(viewModel)
    }
}

fileprivate extension DietaryAdviceResult {
    static var sample: DietaryAdviceResult {
        let analysis = NutritionAnalysis(
            summary: "Overall balanced meal with room to boost fiber.",
            nutritionStatus: "balanced",
            pros: ["Good protein coverage"],
            cons: ["Fiber is lower than daily target"]
        )
        let recommendation = NextMealRecommendation(
            recommendedDish: RecommendedMealDish(
                dishName: "Grilled Salmon with Quinoa",
                icon: "🥗", weight: 320,
                proteinPercent: 28, fatPercent: 15, carbohydratePercent: 40
            ),
            reason: "Balances previous meal by adding fiber.",
            nutrientsFocus: ["Increase dietary fiber", "Maintain lean protein"]
        )
        return DietaryAdviceResult(analysis: analysis, nextMealRecommendation: recommendation)
    }
}

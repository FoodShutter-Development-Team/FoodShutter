//
//  DishListView.swift
//  FoodShutter
//
//  菜品列表视图 - Phase 1 先展示菜名，Phase 2 补充营养数据
//

import SwiftUI

struct DishListView: View {
    let capturedImage: UIImage

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: FoodAnalysisViewModel
    @State private var animatedDishes:     [Dish]   = []
    @State private var showSuggestion:     Bool     = false
    @State private var selectedDish:       Dish?    = nil
    @Namespace private var heroAnimationNamespace

    @State private var currentTrophyIndex: Int  = 0
    @State private var showTrophyPopup:    Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)

                        NutritionSummaryView(
                            ingredients: allIngredients,
                            title: "All Dishes"
                        )
                        .padding(.horizontal, 10)

                        VStack(spacing: 10) {
                            ForEach(Array(animatedDishes.enumerated()), id: \.element.id) { _, dish in
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
                            SuggestionView()
                        }

                        if !animatedDishes.isEmpty {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(.mainText)
                                    .frame(height: 3)
                                HStack {
                                    Text("Photo")
                                    Spacer()
                                    Image(systemName: "photo")
                                }
                                .font(.system(.title2, design: .serif, weight: .semibold))
                                .foregroundStyle(.mainText)
                                .padding(.bottom, 10)

                                FoodAnnotationView(image: capturedImage, dishes: animatedDishes)
                                    .aspectRatio(
                                        capturedImage.size.width / max(capturedImage.size.height, 1),
                                        contentMode: .fit
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .transition(.opacity.animation(.easeIn(duration: 0.4)))
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        }
                    }
                }
                .scrollIndicators(.never)
                .opacity(selectedDish == nil ? 1 : 0)
                .allowsHitTesting(selectedDish == nil)

            if let dish = selectedDish {
                DishDetailView(
                    dish: dish,
                    namespace: heroAnimationNamespace,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.4)) { selectedDish = nil }
                    }
                )
                .transition(.opacity)
            }
        }
        .onChange(of: viewModel.dishes) { _, newDishes in
            animateDishesAppearing(newDishes)
        }
        .onChange(of: viewModel.newTrophies) { _, trophies in
            if !trophies.isEmpty {
                currentTrophyIndex = 0
                showTrophyPopup    = true
            }
        }
        .onAppear {
            if animatedDishes.isEmpty && !viewModel.dishes.isEmpty {
                animateDishesAppearing(viewModel.dishes)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedDish == nil && viewModel.state == .complete {
                Button {
                    if !viewModel.newTrophies.isEmpty {
                        currentTrophyIndex = 0
                        showTrophyPopup    = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(.mainEnable)
                        .frame(width: 40, height: 40)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .padding(30)
            }
        }
        .overlay {
            if showTrophyPopup && currentTrophyIndex < viewModel.newTrophies.count {
                TrophyPopupView(
                    trophy: viewModel.newTrophies[currentTrophyIndex],
                    onDismiss: {
                        if currentTrophyIndex < viewModel.newTrophies.count - 1 {
                            currentTrophyIndex += 1
                        } else {
                            showTrophyPopup = false
                            dismiss()
                        }
                    }
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private var allIngredients: [FoodIngredient] {
        animatedDishes.flatMap { $0.ingredients }
    }

    private func animateDishesAppearing(_ dishes: [Dish]) {
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil
        if isPreview {
            animatedDishes = dishes
            showSuggestion = true
            return
        }

        animatedDishes = []
        for (index, dish) in dishes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.easeOut(duration: 0.3)) { animatedDishes.append(dish) }
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
            vm.state  = .complete
        }
    }

    var body: some View {
        DishListView(capturedImage: UIImage()).environmentObject(viewModel)
    }
}

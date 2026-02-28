//
//  HistoryDishListView.swift
//  FoodShutter
//
//  历史餐食详情视图（Supabase 云端版）
//

import SwiftUI

struct HistoryDishListView: View {
    let meal: MealRow
    let onDismiss: () -> Void
    @State private var showContent = false
    @State private var selectedDish: Dish?
    @Namespace private var heroAnimationNamespace

    private var dishes: [Dish] {
        meal.toDishes()
    }

    private var allIngredients: [FoodIngredient] {
        dishes.flatMap { $0.ingredients }
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.backGround)

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
                            ForEach(dishes) { dish in
                                DishCardView(dish: dish, namespace: heroAnimationNamespace)
                                    .padding(.vertical, 10)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            selectedDish = dish
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)

                        if let advice = meal.dietaryAdvice {
                            HistorySuggestionView(advice: advice)
                        }
                    }
                }
                .scrollIndicators(.never)
                .opacity(showContent ? 1 : 0)
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
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                showContent = true
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedDish == nil && showContent {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.mainEnable)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .padding(30)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    // Preview 使用空 MealRow 无法静态构建，跳过
    Text("HistoryDishListView Preview")
        .foregroundStyle(.mainText)
}

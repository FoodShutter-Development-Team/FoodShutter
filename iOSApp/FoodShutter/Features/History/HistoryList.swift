//
//  HistoryList.swift
//  FoodShutter
//
//  餐食历史列表（Supabase 云端版）
//

import SwiftUI

struct HistoryList: View {
    @State private var meals: [MealRow] = []
    @Binding var selectedMeal: MealRow?

    var body: some View {
        Group {
            if meals.isEmpty {
                VStack(spacing: 20) {
                    Text("No meal history yet")
                        .font(.system(.title3, design: .serif, weight: .medium))
                        .foregroundStyle(.mainText.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
                .listRowBackground(Color.clear)
            } else {
                List {
                    ForEach(meals) { meal in
                        Button {
                            selectedMeal = meal
                        } label: {
                            HistoryRow(
                                protein:    meal.totalProtein,
                                fat:        meal.totalFat,
                                carbon:     meal.totalCarbohydrate,
                                timestamp:  meal.timestamp,
                                dishIcons:  meal.dishes.compactMap { $0.icon }
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.backGround)
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Rectangle().fill(.backGround))
        .ignoresSafeArea()
        .task {
            await loadMeals()
        }
        .refreshable {
            await loadMeals()
        }
    }

    private func loadMeals() async {
        meals = (try? await MealRepository.shared.fetchRecentMeals(limit: 50)) ?? []
        print("✓ Loaded \(meals.count) meals from Supabase")
    }
}

#Preview {
    HistoryList(selectedMeal: .constant(nil))
}

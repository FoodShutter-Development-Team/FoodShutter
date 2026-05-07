//
//  NextMealRecommendationView.swift
//  FoodShutter
//

import SwiftUI

struct NextMealRecommendationView: View {
    @EnvironmentObject var viewModel: FoodAnalysisViewModel

    var body: some View {
        VStack {
            Rectangle()
                .fill(.mainText)
                .frame(height: 3)

            HStack {
                Text("Next Meal Recommendation")
                    .lineLimit(1)
                Spacer()
                Image(systemName: "sparkles.2")
            }
            .font(.system(.title2, design: .serif, weight: .semibold))
            .foregroundStyle(.mainText)

            if viewModel.state == .computingNutrition {
                VStack(spacing: 10) {
                    TypingAnimationText()
                }
                .frame(height: 150)
                .transition(.opacity)
            } else if let rec = viewModel.mealAdvice?.nextMealRecommendation {
                let dish = rec.recommendedDish
                let food = FoodIngredient(
                    name: dish.dishName,
                    icon: dish.icon,
                    weightGrams: dish.weight,
                    calories: 0,
                    proteinG: dish.proteinPercent,
                    fatG: dish.fatPercent,
                    carbG: dish.carbohydratePercent
                )

                FoodIngredientSuggestionView(food: food)
                    .padding(.bottom, 5)
                    .transition(.opacity)

                VStack(alignment: .leading, spacing: 12) {
                    Text(rec.reason)
                        .font(.system(size: 18))
                        .fontDesign(.serif)
                        .foregroundStyle(.mainText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !rec.nutrientsFocus.isEmpty {
                        Text("Nutrients Focus:")
                            .font(.system(.title3, design: .serif, weight: .regular))
                            .foregroundStyle(.mainText)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(rec.nutrientsFocus, id: \.self) { item in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(Color.mainEnable)
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    Text(item)
                                        .font(.system(size: 18))
                                        .fontDesign(.serif)
                                        .foregroundStyle(.mainText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .animation(.easeIn(duration: 0.5), value: viewModel.state)
        .animation(.easeIn(duration: 0.5), value: viewModel.mealAdvice != nil)
    }
}

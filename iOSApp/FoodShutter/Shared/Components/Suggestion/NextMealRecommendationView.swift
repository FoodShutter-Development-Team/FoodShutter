//
//  SuggestionAddView.swift
//  FoodShutter
//
//  View for suggesting additional food items to add to the meal
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
                HStack(spacing: 8) {
                    Text("Next Meal Recommendation")
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "sparkles.2")
            }
            .font(.system(.title2, design: .serif, weight: .semibold))
            .foregroundStyle(.mainText)

            if viewModel.state == .fetchingAdvice {
                // Loading state while fetching advice
                VStack(spacing: 10) {
                    TypingAnimationText()
                }
                .frame(height: 150)
                .transition(.opacity)

            } else if let advice = viewModel.dietaryAdvice {
                // Show real recommendation from Gemini
                let recommended = advice.nextMealRecommendation.recommendedDish
                let food = FoodIngredient(
                    name: recommended.dishName,
                    icon: recommended.icon,
                    weight: recommended.weight,
                    proteinPercent: recommended.proteinPercent,
                    fatPercent: recommended.fatPercent,
                    carbohydratePercent: recommended.carbohydratePercent
                )

                FoodIngredientSuggestionView(food: food)
                    .padding(.bottom, 5)
                    .transition(.opacity)

                VStack(alignment: .leading, spacing: 12) {
                    // Recommendation reason
                    Text(advice.nextMealRecommendation.reason)
                        .font(.system(size: 18))
                        .fontDesign(.serif)
                        .foregroundStyle(.mainText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)

                    // Nutrients focus bullets
                    if !advice.nextMealRecommendation.nutrientsFocus.isEmpty {
                        HStack(spacing: 8) {
                            Text("Nutrients Focus:")
                        }
                        .font(.system(.title3, design: .serif, weight: .regular))
                        .foregroundStyle(.mainText)

                        BulletListView(
                            items: advice.nextMealRecommendation.nutrientsFocus,
                            bulletColor: .userEnable
                        )
                        .font(.system(size: 18))
                        .fontDesign(.serif)
                        .foregroundStyle(.mainText)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity)
            }
        }
        .animation(.easeIn(duration: 0.5), value: viewModel.state)
        .animation(.easeIn(duration: 0.5), value: viewModel.dietaryAdvice != nil)
    }
}

//
//  HistorySuggestionView.swift
//  FoodShutter
//
//  Displays dietary advice for historical meals without ViewModel dependency
//

import SwiftUI

struct HistorySuggestionView: View {
    let advice: DietaryAdviceResult

    var body: some View {
        ZStack {
            Color.backGround
            VStack {
                // Next Meal Recommendation Section
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

                    // Recommended dish card
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
                }
                .padding(.bottom)

                // Summary Section
                VStack {
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 3)

                    HStack {
                        Text("Summary")
                        Spacer()
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(.mainText)

                    VStack(alignment: .leading, spacing: 14) {
                        Text(advice.analysis.summary)
                            .font(.system(size: 18))
                            .fontDesign(.serif)
                            .foregroundStyle(.mainText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(nil)
                            .padding(.top, 5)

                        if !advice.analysis.pros.isEmpty {
                            BulletListView(items: advice.analysis.pros, bulletColor: .userEnable)
                        }
                        if !advice.analysis.cons.isEmpty {
                            BulletListView(items: advice.analysis.cons, bulletColor: .mainEnable)
                        }
                    }
                    .font(.system(size: 18))
                    .fontDesign(.serif)
                    .foregroundStyle(.mainText)
                }

                Rectangle()
                    .fill(.mainText)
                    .frame(height: 3)
                    .padding(.top)
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    let analysis = NutritionAnalysis(
        summary: "Overall balanced meal with room to boost fiber and control sodium.",
        nutritionStatus: "balanced",
        pros: [
            "Good protein coverage for recovery",
            "Healthy fats in a reasonable range"
        ],
        cons: [
            "Fiber is lower than daily target",
            "Sodium likely high from sauces"
        ]
    )

    let recommendation = NextMealRecommendation(
        recommendedDish: RecommendedMealDish(
            dishName: "Grilled Salmon with Quinoa & Greens",
            icon: "🥗",
            weight: 320,
            proteinPercent: 28,
            fatPercent: 15,
            carbohydratePercent: 40
        ),
        reason: "Balances previous meal by adding fiber-rich grains and leafy greens while keeping protein steady.",
        nutrientsFocus: [
            "Increase dietary fiber",
            "Control sodium intake",
            "Maintain lean protein"
        ]
    )

    let advice = DietaryAdviceResult(
        analysis: analysis,
        nextMealRecommendation: recommendation
    )

    return HistorySuggestionView(advice: advice)
}

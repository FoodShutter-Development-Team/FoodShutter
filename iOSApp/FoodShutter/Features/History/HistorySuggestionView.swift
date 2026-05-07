//
//  HistorySuggestionView.swift
//  FoodShutter
//

import SwiftUI

struct HistorySuggestionView: View {
    let advice: MealAdviceRow

    var body: some View {
        ZStack {
            Color.backGround
            VStack {
                // Next Meal Recommendation
                if let rec = advice.nextMealRecommendation {
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

                                BulletListView(items: rec.nutrientsFocus, bulletColor: .mainEnable)
                                    .font(.system(size: 18))
                                    .fontDesign(.serif)
                                    .foregroundStyle(.mainText)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.bottom)
                }

                // Summary
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
                        Text(advice.summary)
                            .font(.system(size: 18))
                            .fontDesign(.serif)
                            .foregroundStyle(.mainText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(nil)
                            .padding(.top, 5)

                        if !advice.pros.isEmpty {
                            BulletListView(items: advice.pros, bulletColor: .userEnable)
                        }
                        if !advice.cons.isEmpty {
                            BulletListView(items: advice.cons, bulletColor: .mainEnable)
                        }
                        if !advice.suggestions.isEmpty {
                            BulletListView(items: advice.suggestions, bulletColor: .mainText)
                        }
                    }
                    .font(.system(size: 18))
                    .fontDesign(.serif)
                    .foregroundStyle(.mainText)
                }

            }
            .padding()
        }
        .ignoresSafeArea()
    }
}

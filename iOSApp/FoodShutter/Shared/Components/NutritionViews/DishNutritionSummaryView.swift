//
//  DishNutritionSummaryView.swift
//  FoodShutter
//
//  Nutrition summary view for individual dish with title display
//

import SwiftUI

/// 营养总结视图
struct DishNutritionSummaryView: View {
    let ingredients: [FoodIngredient]
    let title: String
    let dishId: UUID
    let namespace: Namespace.ID

    private var summaryData: NutritionSummaryData {
        NutritionSummaryData(ingredients: ingredients)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack{
                Text(title)
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .foregroundStyle(.mainText)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
                    .frame(height: 150, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading,5)
                NutritionRingView(data: summaryData)
                    .frame(width: 150, height: 150)
                    .padding()
            }

            // 统计信息
            HStack(spacing: 30) {
                VStack(alignment: .leading,spacing: 4) {
                    Text(String(format: "%.0f g", summaryData.totalWeight))
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundStyle(.mainText)
                    Text("Total")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(.mainText.opacity(0.7))
                }
                .frame(width: 60,alignment: .leading)
                .padding(.leading)


                Rectangle()
                    .fill(.mainText.opacity(0.5))
                    .frame(width: 2,height: 36)

                HStack{
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f g", summaryData.totalProtein))
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(.protein)
                        Text("Protein")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundStyle(.mainText.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(width: 60)
                    .padding(.leading)


                    VStack(spacing: 4) {
                        Text(String(format: "%.0f g", summaryData.totalFat))
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(.fat)
                        Text("Fat")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundStyle(.mainText.opacity(0.7))
                    }
                    .frame(width: 60)
                    .frame(maxWidth: .infinity)



                    VStack(spacing: 4) {
                        Text(String(format: "%.0f g", summaryData.totalCarbohydrate))
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(.carbohydrate)
                        Text("Carbs")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundStyle(.mainText.opacity(0.7))
                    }
                    .padding(.trailing)
                    .frame(width: 60)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

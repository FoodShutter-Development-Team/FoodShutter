//
//  NutritionSummaryView.swift
//  FoodShutter
//
//  Summary view for aggregated nutrition data
//

import SwiftUI

/// 营养总结视图
struct NutritionSummaryView: View {
    let ingredients: [FoodIngredient]
    let title: String

    private var summaryData: NutritionSummaryData {
        NutritionSummaryData(ingredients: ingredients)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack{
                NutritionRingView(data: summaryData)
                    .frame(width: 150, height: 150)
                    .padding()
                    .padding(.bottom)
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
                    .padding(.leading)


                    VStack(spacing: 4) {
                        Text(String(format: "%.0f g", summaryData.totalFat))
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(.fat)
                        Text("Fat")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundStyle(.mainText.opacity(0.7))
                    }
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
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.backGround
        NutritionSummaryView(
            ingredients: FoodIngredient.sampleData,
            title: "Guizhou\nSour\nSoup\nFish"
        )
    }
    .ignoresSafeArea()
}

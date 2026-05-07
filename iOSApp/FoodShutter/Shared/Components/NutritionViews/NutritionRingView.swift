//
//  NutritionRingView.swift
//  FoodShutter
//
//  Circular progress ring showing nutrition proportions
//

import SwiftUI

/// Circular ring view showing nutrition proportions
struct NutritionRingView: View {
    let data: NutritionSummaryData
    let lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            // Protein ring
            Circle()
                .trim(from: 0, to: data.proteinPercent / 100)
                .stroke(
                    Color.protein,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Fat ring
            Circle()
                .trim(
                    from: data.proteinPercent / 100,
                    to: (data.proteinPercent + data.fatPercent) / 100
                )
                .stroke(
                    Color.fat,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Carbohydrate ring
            Circle()
                .trim(
                    from: (data.proteinPercent + data.fatPercent) / 100,
                    to: 1
                )
                .stroke(
                    Color.carbohydrate,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 0) {
                Text(String(format: "%.0f", data.totalCalories))
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(.mainText)
                Text("kcal")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(.mainText.opacity(0.7))
            }
            .offset(y: 3)
        }
    }
}

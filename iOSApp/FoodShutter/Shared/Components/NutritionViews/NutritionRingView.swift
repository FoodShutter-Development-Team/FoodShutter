//
//  NutritionRingView.swift
//  FoodShutter
//
//  Circular progress ring showing nutrition proportions
//

import SwiftUI

/// 营养成分圆环视图
struct NutritionRingView: View {
    let data: NutritionSummaryData
    let lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            // 蛋白质圆环
            Circle()
                .trim(from: 0, to: data.proteinPercent / 100)
                .stroke(
                    Color.protein,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // 脂肪圆环
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

            // 碳水化合物圆环
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

            // 中心文字
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

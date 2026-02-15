//
//  DishCardView.swift
//  FoodShutter
//
//  最终修复版：移除内容几何匹配，只保留背景匹配，解决拉伸变形 Bug
//

import SwiftUI

struct DishCardView: View {
    let dish: Dish
    let namespace: Namespace.ID

    var body: some View {
        HStack(alignment: .center) {
            // 图标
            Text(dish.icon)
                .font(.system(size: 30))

            VStack(spacing: 0) {
                HStack {
                    // 标题
                    Text(dish.name)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 热量
                    Text(String(format: "%.0f kcal", dish.totalCalories))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 20, design: .serif))
                .foregroundStyle(.mainText)

                // 进度条
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(.protein)
                            .frame(width: (dish.proteinPercent / dish.available) * proxy.size.width)
                        Rectangle()
                            .fill(.fat)
                            .frame(width: (dish.fatPercent / dish.available) * proxy.size.width)
                        Rectangle()
                            .fill(.carbohydrate)
                    }
                    .clipShape(Capsule())
                }
                .padding(.vertical, 2)
                .frame(height: 12)
            }
        }
        // [关键修复] 移除了 .matchedGeometryEffect(id: ...-content)
        // 任何形式的内容强制匹配都会导致“长条变圆”的扭曲 Bug。
        // 移除后，内容会跟随背景淡出，视觉上更干净。
        .padding(15)
        .background(
            // 背景匹配保留：这是实现“上移展开”视觉核心动力的关键
            RoundedRectangle(cornerRadius: 15)
                .fill(.backGroundDark)
                .matchedGeometryEffect(id: "\(dish.id)-background", in: namespace)
        )
    }
}

#Preview {
    @Previewable @Namespace var namespace
    DishCardView(dish: Dish.sampleData[0], namespace: namespace)
        .padding()
}

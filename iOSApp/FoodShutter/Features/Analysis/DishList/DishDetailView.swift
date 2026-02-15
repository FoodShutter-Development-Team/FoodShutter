//
//  DishDetailView.swift
//  FoodShutter
//
//  最终修复版：移除内容几何匹配，使用自然过渡
//

import SwiftUI

struct DishDetailView: View {
    let dish: Dish
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    @State var isOffset:Bool = true

    var body: some View {
        ZStack {
            // 1. 背景层：保留匹配，负责撑开动画
            RoundedRectangle(cornerRadius: 15)
                .fill(.backGround)
                .matchedGeometryEffect(id: "\(dish.id)-background", in: namespace)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 60)

                    // 2. 头部信息视图
                    DishNutritionSummaryView(
                        ingredients: dish.ingredients,
                        title: dish.name,
                        dishId: dish.id,
                        namespace: namespace
                    )
                    .padding(.horizontal, 20)
                    // [关键修复] 移除了 .matchedGeometryEffect
                    // 改为使用 opacity 过渡，实现“渐变显现”
                    // 配合背景的展开，视觉上就是“移上来并变出来的”
                    .transition(.opacity.animation(.easeInOut(duration: 0.3).delay(0.1)))

                    // Ingredients list
                    VStack(spacing: 10) {
                        ForEach(Array(dish.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                            FoodIngredientView(food: ingredient)
                                .padding(.vertical, 10)
                                // 列表项逐个飞入，增加层次感
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 100)
                }
                .offset(y: isOffset ? 50 : 0)
            }
            .scrollIndicators(.never)

        }
        .overlay(alignment: .bottomLeading) {
            Button{
                withAnimation {
                    isOffset = true
                }
                onDismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .frame(width: 40,height: 40)
                    .foregroundStyle(.mainText)
                    .glassEffect(.regular.interactive(),in: Circle())
            }
            .padding(30)
        }
        .ignoresSafeArea()
        .onAppear{
            withAnimation {
                isOffset = false
            }
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    DishDetailView(
        dish: Dish.sampleData[0],
        namespace: namespace,
        onDismiss: {}
    )
}

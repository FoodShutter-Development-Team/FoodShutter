//
//  DishDetailView.swift
//  FoodShutter
//
//  Final fix: removed content geometry matching in favour of natural transitions
//

import SwiftUI

struct DishDetailView: View {
    let dish: Dish
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    @State var isOffset:Bool = true

    var body: some View {
        ZStack {
            // 1. Background layer: keeps the geometry match to drive the expand animation
            RoundedRectangle(cornerRadius: 15)
                .fill(.backGround)
                .matchedGeometryEffect(id: "\(dish.id)-background", in: namespace)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 60)

                    // 2. Header info view
                    DishNutritionSummaryView(
                        ingredients: dish.ingredients,
                        title: dish.name,
                        dishId: dish.id,
                        namespace: namespace
                    )
                    .padding(.horizontal, 20)
                    // [Key fix] Removed .matchedGeometryEffect
                    // Using opacity transition instead for a fade-in effect
                    // Combined with the background expansion, it visually “slides up and fades in”
                    .transition(.opacity.animation(.easeInOut(duration: 0.3).delay(0.1)))

                    // Ingredients list
                    VStack(spacing: 10) {
                        ForEach(Array(dish.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                            FoodIngredientView(food: ingredient)
                                .padding(.vertical, 10)
                                // List items fly in one by one for a layered feel
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

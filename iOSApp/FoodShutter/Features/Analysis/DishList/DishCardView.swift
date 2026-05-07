//
//  DishCardView.swift
//  FoodShutter
//
//  Final fix: removed content geometry matching, keeping only background matching to fix the stretch/distortion bug
//

import SwiftUI

struct DishCardView: View {
    let dish: Dish
    let namespace: Namespace.ID

    var body: some View {
        HStack(alignment: .center) {
            // Icon
            Text(String(dish.icon.prefix(1)))
                .font(.system(size: 30))

            VStack(spacing: 0) {
                HStack {
                    // Title
                    Text(dish.name)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Calories
                    Text(String(format: "%.0f kcal", dish.totalCalories))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 20, design: .serif))
                .foregroundStyle(.mainText)

                // Progress bar
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(.protein)
                            .frame(width: (dish.proteinPercent / 100) * proxy.size.width)
                        Rectangle()
                            .fill(.fat)
                            .frame(width: (dish.fatPercent / 100) * proxy.size.width)
                        Rectangle()
                            .fill(.carbohydrate)
                    }
                    .clipShape(Capsule())
                }
                .padding(.vertical, 2)
                .frame(height: 12)
            }
        }
        // [Key fix] Removed .matchedGeometryEffect(id: ...-content)
        // Any forced content geometry matching causes a “long rectangle morphing into a circle” distortion bug.
        // Without it, content fades alongside the background for a cleaner visual.
        .padding(15)
        .background(
            // Background match is kept: it is the visual core that drives the “slide-up and expand” effect
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

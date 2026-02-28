//
//  FoodIngredientView.swift
//  FoodShutter
//
//  Reusable component for displaying individual food ingredient
//

import SwiftUI

struct FoodIngredientView: View {
    let food: FoodIngredient
    var body: some View {

        HStack(alignment: .bottom){
            Text(food.icon)
                .font(.system(size: 25))
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 10).fill(.backGroundDark))
            VStack(spacing: 0){
                HStack{
                    Text(food.name)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.f kcal",food.calories))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 20,design: .serif))
                .foregroundStyle(.mainText)

                GeometryReader{ proxy in
                    HStack(spacing:0){
                        Rectangle()
                            .fill(.protein)
                            .frame(width:(food.proteinPercent/food.available)*proxy.size.width)
                        Rectangle()
                            .fill(.fat)
                            .frame(width:(food.fatPercent/food.available)*proxy.size.width)
                        Rectangle()
                            .fill(.carbohydrate)
                    }
                    .clipShape(Capsule())
                }
                .padding(.vertical,2)
                .frame(height: 12)

            }

        }

    }
}

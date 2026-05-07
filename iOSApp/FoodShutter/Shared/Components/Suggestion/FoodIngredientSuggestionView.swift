//
//  FoodIngredientSuggestionView.swift
//  FoodShutter
//
//  Card view for suggested food ingredients
//

import SwiftUI

struct FoodIngredientSuggestionView: View {
    let food: FoodIngredient
    var body: some View {

        HStack(alignment: .center){
            Text(String(food.icon.prefix(1)))
                .font(.system(size: 25))

            VStack(spacing: 0){
                HStack{
                    Text(food.name)
                        .fontWeight(.bold)
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "%.f g",food.weight))
                        .fontWeight(.semibold)
                }
                .font(.system(size: 20,design: .serif))
                .foregroundStyle(.mainText)

                GeometryReader{ proxy in
                    HStack(spacing:0){
                        Rectangle()
                            .fill(.protein)
                            .frame(width:(food.proteinPercent/100)*proxy.size.width)
                        Rectangle()
                            .fill(.fat)
                            .frame(width:(food.fatPercent/100)*proxy.size.width)
                        Rectangle()
                            .fill(.carbohydrate)
                    }
                    .clipShape(Capsule())
                }
                .padding(.vertical,2)
                .frame(height: 12)

            }

        }
        .padding(15)
        .background(RoundedRectangle(cornerRadius: 15).fill(.backGroundDark))

    }
}

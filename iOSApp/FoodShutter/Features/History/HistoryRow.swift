//
//  HistoryRow.swift
//  FoodShutter
//
//  Created by Cosmos on 27/12/2025.
//

import SwiftUI

struct HistoryRow: View {
    var protein: CGFloat
    var fat: CGFloat
    var carbon: CGFloat
    var timestamp: Date
    var dishIcons: [String]

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }

    private var emojiText: String {
        dishIcons.joined()
    }

    var body: some View {
        HStack{
            VStack(spacing: 0){
                HStack {
                    Text(timeString)
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .foregroundStyle(.mainText)
                    Spacer()
                    if emojiText.count > 6 {
                        Text(emojiText.suffix(6))
                            .font(.system(size: 25))
                            .lineLimit(1)
                            .foregroundStyle(.mainText)

                        Circle()
                            .fill(.fat)
                            .frame(width: 8,height: 8)
                        Circle()
                            .fill(.protein)
                            .frame(width: 8,height: 8)
                        Circle()
                            .fill(.carbohydrate)
                            .frame(width: 8,height: 8)

                    } else {
                        Text(emojiText)
                            .font(.system(size: 25))
                            .lineLimit(1)
                            .foregroundStyle(.mainText)
                    }


                }
                HStack{
                    Text(dateString)
                        .font(.system(size: 20, weight: .black, design: .serif))
                        .foregroundStyle(.mainText)
                        
               
                    GeometryReader{ proxy in
                        HStack(spacing:0){
                            Rectangle()
                                .fill(.protein)
                                .frame(width:(protein/(protein+fat+carbon))*proxy.size.width)
                            Rectangle()
                                .fill(.fat)
                                .frame(width:(fat/(protein+fat+carbon))*proxy.size.width)
                            Rectangle()
                                .fill(.carbohydrate)
                        }
                        .clipShape(Capsule())
                    }
                    .padding(.vertical,2)
                    .frame(height: 15)
                }
                .padding(2)
                .padding(.horizontal,3)
                .background(RoundedRectangle(cornerRadius: 6).fill(.backGroundDark))
                
            }
        }


    }
}

#Preview {
    ZStack{
        Rectangle().fill(.backGround)

        HistoryRow(
            protein: 20.0,
            fat: 10.0,
            carbon: 10.0,
            timestamp: Date(),
            dishIcons: ["🍏", "🧈", "🍗"]
        )
        .padding()
    }
}

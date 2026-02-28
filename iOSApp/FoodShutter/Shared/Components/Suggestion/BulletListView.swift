//
//  BulletListView.swift
//  FoodShutter
//
//  Simple colored bullet list for suggestion sections
//

import SwiftUI

struct BulletListView: View {
    let items: [String]
    let bulletColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(bulletColor)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    Text(item)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

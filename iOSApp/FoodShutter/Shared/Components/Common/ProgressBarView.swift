//
//  ProgressBarView.swift
//  FoodShutter
//
//  Reusable progress bar component
//

import SwiftUI

struct ProgressBarView: View {
    let mainColor: Color
    let v: CGFloat
    let total: CGFloat
    var body: some View {
        GeometryReader{ proxy in
            ZStack(alignment: .leading){
                Rectangle()
                    .fill(mainColor.opacity(0.5))
                Rectangle()
                    .fill(mainColor)
                    .frame(width: proxy.size.width*v/total)
            }
        }
        .clipShape( Capsule() )
    }
}

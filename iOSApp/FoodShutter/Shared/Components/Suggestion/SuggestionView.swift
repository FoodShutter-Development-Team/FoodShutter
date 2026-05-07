//
//  SuggestionView.swift
//  FoodShutter
//

import SwiftUI

struct SuggestionView: View {
    @EnvironmentObject var viewModel: FoodAnalysisViewModel

    var body: some View {
        ZStack {
            Color.backGround
            VStack {
                NextMealRecommendationView()
                    .padding(.bottom)
                SuggestionSummaryView()
            }
            .padding()
        }
        .ignoresSafeArea()
    }
}

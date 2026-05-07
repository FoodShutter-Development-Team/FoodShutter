//
//  SuggestionSummaryView.swift
//  FoodShutter
//

import SwiftUI

struct SuggestionSummaryView: View {
    @EnvironmentObject var viewModel: FoodAnalysisViewModel

    var body: some View {
        VStack {
            Rectangle()
                .fill(.mainText)
                .frame(height: 3)

            HStack {
                Text("Summary")
                Spacer()
                Image(systemName: "arrow.counterclockwise")
            }
            .font(.system(.title2, design: .serif, weight: .semibold))
            .foregroundStyle(.mainText)

            if let advice = viewModel.mealAdvice {
                VStack(alignment: .leading, spacing: 14) {
                    Text(advice.summary)
                        .font(.system(size: 18))
                        .fontDesign(.serif)
                        .foregroundStyle(.mainText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                        .padding(.top, 5)

                    if !advice.pros.isEmpty {
                        BulletListView(items: advice.pros, bulletColor: .userEnable)
                    }
                    if !advice.cons.isEmpty {
                        BulletListView(items: advice.cons, bulletColor: .mainEnable)
                    }
                    if !advice.suggestions.isEmpty {
                        BulletListView(items: advice.suggestions, bulletColor: .mainText)
                    }
                }
                .font(.system(size: 18))
                .fontDesign(.serif)
                .foregroundStyle(.mainText)
                .transition(.opacity)
            } else {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.mainEnable)
                    Text("Loading analysis...")
                        .font(.system(size: 16, design: .serif))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 100)
                .transition(.opacity)
            }
        }
        .animation(.easeIn(duration: 0.5), value: viewModel.mealAdvice != nil)
    }
}

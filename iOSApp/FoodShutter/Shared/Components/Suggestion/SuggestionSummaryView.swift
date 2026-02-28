//
//  SuggestionSummaryView.swift
//  FoodShutter
//
//  Daily nutrition review and next meal guidelines
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

            if let advice = viewModel.dietaryAdvice {
                VStack(alignment: .leading, spacing: 14) {

                    Text(advice.analysis.summary)
                        .font(.system(size: 18))
                        .fontDesign(.serif)
                        .foregroundStyle(.mainText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                        .padding(.top, 5)

                    if !advice.analysis.pros.isEmpty {
                        BulletListView(items: advice.analysis.pros, bulletColor: .userEnable)
                    }
                    if !advice.analysis.cons.isEmpty {
                        BulletListView(items: advice.analysis.cons, bulletColor: .mainEnable)
                    }
                }
                .font(.system(size: 18))
                .fontDesign(.serif)
                .foregroundStyle(.mainText)
                .transition(.opacity)

            } else {
                // Loading placeholder
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
        .animation(.easeIn(duration: 0.5), value: viewModel.dietaryAdvice != nil)
    }
}

//
//  TrophyHistoryView.swift
//  FoodShutter
//
//  奖杯收藏视图（Supabase 云端版）
//

import SwiftUI

struct TrophyHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var trophies: [Trophy] = []

    var body: some View {
        ZStack {
            Color.backGround

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                VStack(alignment: .leading) {
                    Text("Trophy Collection")
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(.mainText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(trophies.count) Trophies Earned")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(.mainText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)

                if trophies.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Text("🏅")
                            .font(.system(size: 60))
                        Text("No trophies yet")
                            .font(.system(.title2, design: .serif, weight: .bold))
                            .foregroundStyle(.mainText)
                        Text("Keep hitting your nutrition goals to earn achievements!")
                            .font(.system(.body, design: .serif, weight: .semibold))
                            .foregroundStyle(.mainText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                    Spacer().frame(height: 80)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(trophies) { trophy in
                                TrophyRowView(trophy: trophy)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                    }
                    .ignoresSafeArea()
                }
            }

            Button("Back", systemImage: "chevron.left") {
                dismiss()
            }
            .font(.system(.title2, design: .serif, weight: .bold))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .foregroundStyle(.userEnable)
            .buttonStyle(.glass)
            .padding(40)
        }
        .ignoresSafeArea()
        .task {
            await loadTrophies()
        }
    }

    private func loadTrophies() async {
        trophies = (try? await TrophyRepository.shared.fetchAllTrophies()) ?? []
    }
}

// MARK: - Trophy Row View

struct TrophyRowView: View {
    let trophy: Trophy

    var body: some View {
        HStack(spacing: 15) {
            Text(trophy.type.icon)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 5) {
                Text(trophy.type.title)
                    .font(.system(.headline, design: .serif, weight: .bold))
                    .foregroundStyle(.mainText)

                Text(trophy.earnedDate, style: .date)
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.mainText.opacity(0.6))

                if trophy.streakDays > 1 {
                    Text("\(trophy.streakDays)-day streak")
                        .font(.system(.caption, design: .serif, weight: .semibold))
                        .foregroundStyle(.userEnable)
                }
            }

            Spacer()
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.mainText.opacity(0.2), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.backGroundDark)
                )
        )
    }
}

#Preview {
    TrophyHistoryView()
}

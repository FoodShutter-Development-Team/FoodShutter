//
//  TrophyPopupView.swift
//  FoodShutter
//
//  Animated modal popup displayed when trophy is earned
//

import SwiftUI

struct TrophyPopupView: View {
    let trophy: Trophy
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = -180
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Background dimmer
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Trophy card
            VStack(spacing: 20) {
                // Trophy icon with animation
                Text(trophy.type.icon)
                    .font(.system(size: 80))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .opacity(opacity)

                // Title
                Text(trophy.type.title)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(.mainText)
                    .opacity(opacity)

                // Description
                Text(trophy.type.description)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.mainText.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .opacity(opacity)

                // Stats summary
                VStack(spacing: 8) {
                    HStack {
                        Text("Calories:")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                        Spacer()
                        Text("\(Int(trophy.calories)) kcal")
                            .font(.system(.subheadline, design: .serif))
                    }
                    .foregroundStyle(.mainText)

                    HStack {
                        Text("Protein:")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(.protein)
                        Spacer()
                        Text("\(Int(trophy.protein))g")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.protein)
                    }

                    HStack {
                        Text("Fat:")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(.fat)
                        Spacer()
                        Text("\(Int(trophy.fat))g")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.fat)
                    }

                    HStack {
                        Text("Carbs:")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(.carbohydrate)
                        Spacer()
                        Text("\(Int(trophy.carbohydrate))g")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.carbohydrate)
                    }
                }
                .padding(.horizontal, 30)
                .opacity(opacity)

                // Dismiss button
                Button {
                    dismissWithAnimation()
                } label: {
                    Text("Great!")
                        .font(.system(.body, design: .serif, weight: .bold))
                        .foregroundStyle(.userEnable)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 40)
                }
                .buttonStyle(.glass)
                .opacity(opacity)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.backGround)
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Staggered animation - trophy entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
                opacity = 1.0
            }
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

#Preview {
    TrophyPopupView(
        trophy: Trophy(
            id: UUID(),
            type: .singleDay,
            earnedDate: Date(),
            streakDays: 1,
            calories: 2000,
            protein: 150,
            fat: 60,
            carbohydrate: 200
        ),
        onDismiss: {}
    )
}

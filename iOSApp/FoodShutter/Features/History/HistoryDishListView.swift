//
//  HistoryDishListView.swift
//  FoodShutter
//

import SwiftUI

struct HistoryDishListView: View {
    let meal: MealRow
    let onDismiss: () -> Void
    @State private var showContent = false
    @State private var selectedDish: Dish?
    @State private var advice: MealAdviceRow?
    @State private var mealImage: UIImage?
    @Namespace private var heroAnimationNamespace

    private var dishes: [Dish] { meal.toDishes() }
    private var allIngredients: [FoodIngredient] { dishes.flatMap { $0.ingredients } }

    var body: some View {
        ZStack {
            Rectangle().fill(.backGround)

            ScrollView {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)

                        NutritionSummaryView(
                            ingredients: allIngredients,
                            title: "All Dishes"
                        )
                        .padding(.horizontal, 10)

                        VStack(spacing: 10) {
                            ForEach(dishes) { dish in
                                DishCardView(dish: dish, namespace: heroAnimationNamespace)
                                    .padding(.vertical, 10)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            selectedDish = dish
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)

                        if let advice {
                            HistorySuggestionView(advice: advice)
                        }

                        if meal.photoUrl != nil {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(.mainText)
                                    .frame(height: 3)
                                HStack {
                                    Text("Photo")
                                    Spacer()
                                    Image(systemName: "photo")
                                }
                                .font(.system(.title2, design: .serif, weight: .semibold))
                                .foregroundStyle(.mainText)
                                .padding(.bottom, 10)

                                if let img = mealImage {
                                    FoodAnnotationView(image: img, dishes: dishes)
                                        .aspectRatio(
                                            img.size.width / max(img.size.height, 1),
                                            contentMode: .fit
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .transition(.opacity.animation(.easeIn(duration: 0.4)))
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.backGroundDark)
                                        .aspectRatio(4/3, contentMode: .fit)
                                        .overlay {
                                            ProgressView().tint(.mainText)
                                        }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        }
                    }
                }
                .scrollIndicators(.never)
                .opacity(showContent && selectedDish == nil ? 1 : 0)
                .allowsHitTesting(selectedDish == nil)

            if let dish = selectedDish {
                DishDetailView(
                    dish: dish,
                    namespace: heroAnimationNamespace,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.4)) { selectedDish = nil }
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { showContent = true }
        }
        .task {
            advice = try? await MealRepository.shared.fetchAdvice(mealId: meal.id)
        }
        .task {
            guard let path = meal.photoUrl,
                  let url = try? await MealRepository.shared.getMealPhotoURL(path: path),
                  let (data, _) = try? await URLSession.shared.data(from: url)
            else { return }
            mealImage = UIImage(data: data)
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedDish == nil && showContent {
                Button { onDismiss() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.mainEnable)
                        .glassEffect(.regular.interactive(), in: Circle())
                }
                .padding(30)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    Text("HistoryDishListView Preview")
        .foregroundStyle(.mainText)
}

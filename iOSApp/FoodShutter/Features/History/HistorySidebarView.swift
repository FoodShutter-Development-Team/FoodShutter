//
//  HistorySidebarView.swift
//  FoodShutter
//
//  左滑抽屉式历史记录面板（Supabase 云端版）
//

import SwiftUI

struct HistorySidebarView: View {
    @Binding var isPresented: Bool
    @State private var selectedMeal: MealRow?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let screenWidth  = geometry.size.width
            let sidebarWidth = screenWidth * 0.85

            ZStack(alignment: .leading) {
                // Layer 1: 详情视图
                if let meal = selectedMeal {
                    HistoryDishListView(
                        meal: meal,
                        onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedMeal = nil
                            }
                        }
                    )
                    .frame(width: screenWidth, height: geometry.size.height)
                    .offset(x: detailViewOffset(hasDetailView: true, screenWidth: screenWidth))
                    .transition(.move(edge: .leading))
                }

                // Layer 2: 侧边栏主体
                VStack(alignment: .leading, spacing: 0) {
                    Text("Meal History")
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(.mainText)
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 20)

                    HistoryList(selectedMeal: $selectedMeal)
                }
                .frame(width: sidebarWidth, height: geometry.size.height)
                .background(Color.backGround)
                .offset(x: sidebarOffset(
                    isPresented: isPresented,
                    hasDetailView: selectedMeal != nil,
                    screenWidth: screenWidth,
                    sidebarWidth: sidebarWidth,
                    dragOffset: dragOffset
                ))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if selectedMeal == nil && value.translation.width < 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if selectedMeal == nil {
                                if -value.translation.width > sidebarWidth * 0.3 {
                                    withAnimation(.spring(response: 0.3)) { isPresented = false }
                                } else {
                                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                                }
                            }
                        }
                )
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedMeal != nil)
            .animation(.spring(response: 0.3), value: dragOffset)
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    dragOffset   = 0
                    selectedMeal = nil
                } else {
                    selectedMeal = nil
                }
            }
        }
        .ignoresSafeArea()
    }

    private func detailViewOffset(hasDetailView: Bool, screenWidth: CGFloat) -> CGFloat {
        hasDetailView ? 0 : -screenWidth
    }

    private func sidebarOffset(
        isPresented: Bool,
        hasDetailView: Bool,
        screenWidth: CGFloat,
        sidebarWidth: CGFloat,
        dragOffset: CGFloat
    ) -> CGFloat {
        if !isPresented       { return -sidebarWidth }
        if hasDetailView      { return screenWidth }
        return dragOffset
    }
}

#Preview {
    HistorySidebarView(isPresented: .constant(true))
}

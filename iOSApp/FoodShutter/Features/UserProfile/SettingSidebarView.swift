//
//  SettingSidebarView.swift
//  FoodShutter
//
//  Custom left-sliding sidebar for settings with layered detail view
//

import SwiftUI

enum SettingDetailPage {
    case profile
}

struct SettingSidebarView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var selectedPage: SettingDetailPage?
    @State private var dragOffset: CGFloat = 0
    @State private var cachedProfile: UserNutritionProfile?

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let sidebarWidth = screenWidth * 0.85

            ZStack(alignment: .leading) {
                // Layer 1: Detail View (covers entire screen when shown)
                if let page = selectedPage {
                    Group {
                        switch page {
                        case .profile:
                            InfoView(
                                initialName: cachedProfile?.name,
                                profile: cachedProfile,
                                onFinished: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedPage = nil
                                    }
                                },
                                showResetButton: true
                            )
                        }
                    }
                    .frame(width: screenWidth, height: geometry.size.height)
                    .offset(x: detailViewOffset(
                        hasDetailView: true,
                        screenWidth: screenWidth
                    ))
                    .transition(.move(edge: .trailing))
                }

                // Layer 2: Sidebar (Settings List)
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("Settings")
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(.mainText)
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 20)

                    // Settings list
                    SettingsListContent(selectedPage: $selectedPage)
                }
                .frame(width: sidebarWidth, height: geometry.size.height)
                .background(Color.backGround)
                .offset(x: sidebarOffset(
                    isPresented: isPresented,
                    hasDetailView: selectedPage != nil,
                    screenWidth: screenWidth,
                    sidebarWidth: sidebarWidth,
                    dragOffset: dragOffset
                ))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow dragging to the right when no detail view
                            if selectedPage == nil && value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if selectedPage == nil {
                                // Dismiss sidebar if dragged more than 30% of width
                                if value.translation.width > sidebarWidth * 0.3 {
                                    withAnimation(.spring(response: 0.3)) {
                                        isPresented = false
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                        }
                )
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedPage != nil)
            .animation(.spring(response: 0.3), value: dragOffset)
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    // Reset states when opening
                    dragOffset = 0
                    selectedPage = nil
                } else {
                    // Close detail view when closing sidebar
                    selectedPage = nil
                }
            }
        }
        .ignoresSafeArea()
        .task {
            cachedProfile = try? await ProfileRepository.shared.getProfile()?.toUserNutritionProfile()
        }
    }

    // Calculate detail view offset (slides in from the right, covers the entire screen)
    private func detailViewOffset(hasDetailView: Bool, screenWidth: CGFloat) -> CGFloat {
        if hasDetailView {
            return 0  // Fully visible
        } else {
            return screenWidth  // Hidden off the right edge of the screen
        }
    }

    // Calculate sidebar offset (slides in from the right to the screen's right side)
    private func sidebarOffset(
        isPresented: Bool,
        hasDetailView: Bool,
        screenWidth: CGFloat,
        sidebarWidth: CGFloat,
        dragOffset: CGFloat
    ) -> CGFloat {
        if !isPresented {
            // Sidebar is fully hidden off the right edge of the screen
            return screenWidth
        } else if hasDetailView {
            // When the detail page is visible, move the sidebar off the left edge
            return -sidebarWidth
        } else {
            // Sidebar visible, docked to the right side of the screen
            // Calculated from the left edge: offset by (screenWidth - sidebarWidth) to align right
            return screenWidth - sidebarWidth + dragOffset
        }
    }
}

// MARK: - Settings List Content

struct SettingsListContent: View {
    @Binding var selectedPage: SettingDetailPage?
    @EnvironmentObject var appState: AppState
    @State private var showSignOutConfirm  = false
    @State private var showDeleteConfirm   = false
    @State private var isLoading           = false

    var body: some View {
        List {
            // Profile
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedPage = .profile
                }
            } label: {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.backGround)

            // Sign Out
            Button {
                showSignOutConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                    Spacer()
                }
                .foregroundStyle(.userEnable)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.backGround)

            // Delete Account
            Button {
                showDeleteConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                    Spacer()
                }
                .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.backGround)
        }
        .listStyle(.plain)
        .font(.title2)
        .fontDesign(.serif)
        .fontWeight(.bold)
        .foregroundStyle(.mainText)
        .overlay {
            if isLoading {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView().tint(.mainEnable)
            }
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again.")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All your data will be permanently deleted. This action cannot be undone.")
        }
    }

    private func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthManager.shared.signOut()
            await MainActor.run { appState.onSignedOut() }
        } catch {
            print("⚠️ Sign out error: \(error.localizedDescription)")
        }
    }

    private func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthManager.shared.deleteAccount()
            await MainActor.run { appState.onSignedOut() }
        } catch {
            print("⚠️ Delete account error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingSidebarView(isPresented: .constant(true))
}

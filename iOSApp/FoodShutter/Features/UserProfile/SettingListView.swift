//
//  SettingListView.swift
//  FoodShutter
//
//  设置列表（含用户账户卡片 + 登出 + 删除账户）
//

import SwiftUI

struct SettingListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSignOutConfirm   = false
    @State private var showDeleteConfirm    = false
    @State private var isLoading            = false
    @State private var cachedProfile: UserNutritionProfile? = nil

    private var userEmail: String {
        AuthManager.shared.userEmail ?? "—"
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 账户信息区块
                Section {
                    // 邮箱显示
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.mainText.opacity(0.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cachedProfile?.name.isEmpty == false ? cachedProfile!.name : "User")
                                .font(.system(.headline, design: .serif, weight: .bold))
                                .foregroundStyle(.mainText)
                            Text(userEmail)
                                .font(.system(.caption, design: .serif))
                                .foregroundStyle(.mainText.opacity(0.5))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.backGround)
                    .padding(.vertical, 4)
                }

                // MARK: - 功能导航
                Section {
                    // 修改资料
                    NavigationLink {
                        InfoView(
                            profile:         cachedProfile,
                            showResetButton: false
                        )
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Profile")
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.backGround)

                }

                // MARK: - 账户操作
                Section {
                    // 登出
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
                    .listRowBackground(Color.backGround)

                    // 删除账户（App Store 要求）
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
                    .listRowBackground(Color.backGround)
                }
            }
            .listStyle(.plain)
            .font(.title2)
            .fontDesign(.serif)
            .fontWeight(.bold)
            .foregroundStyle(.mainText)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView().tint(.mainEnable)
                }
            }
        }
        .task {
            loadProfile()
        }
        // 登出确认
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again.")
        }
        // 删除账户确认
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All your data will be permanently deleted. This action cannot be undone.")
        }
    }

    // MARK: - Private Actions

    private func loadProfile() {
        Task {
            cachedProfile = try? await ProfileRepository.shared.getProfile()?.toUserNutritionProfile()
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
    SettingListView()
        .environmentObject(AppState())
}

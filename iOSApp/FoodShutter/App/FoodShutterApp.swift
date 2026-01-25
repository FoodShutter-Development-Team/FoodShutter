//
//  FoodShutterApp.swift
//  FoodShutter
//
//  App 入口 & 路由管理（Supabase 云端版）
//

import SwiftUI
import Combine

// MARK: - Auth State

enum AuthState {
    case loading        // 启动时检查 session
    case authenticated  // 已登录
    case unauthenticated // 未登录，显示 AuthView
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var hasProfile: Bool = false
    @Published private var analysisViewModel: FoodAnalysisViewModel?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 启动 Auth 监听（唯一入口，处理 initialSession + 后续事件）
        AuthManager.shared.startListening()

        // 等待初始 session 解析完成后，设置 auth 状态
        AuthManager.shared.$initialSessionResolved
            .filter { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.checkAuthState() }
            }
            .store(in: &cancellables)

        // 持续观察 currentUser 变化（登录/登出均触发路由切换）
        AuthManager.shared.$currentUser
            .dropFirst() // 跳过初始 nil
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                if user != nil && self.authState != .authenticated {
                    Task { await self.onSignedIn() }
                } else if user == nil && self.authState != .unauthenticated {
                    self.onSignedOut()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Auth State Check

    func checkAuthState() async {
        if AuthManager.shared.currentUser != nil {
            let profileExists = (try? await ProfileRepository.shared.hasProfile()) ?? false
            hasProfile = profileExists
            authState  = .authenticated

            if profileExists {
                await ensureNutritionTargets()
                await checkTrophiesOnStartup()
            }
        } else {
            authState = .unauthenticated
        }
    }

    func onSignedIn() async {
        let profileExists = (try? await ProfileRepository.shared.hasProfile()) ?? false
        hasProfile = profileExists
        authState  = .authenticated
    }

    func onSignedOut() {
        hasProfile        = false
        authState         = .unauthenticated
        analysisViewModel = nil
    }

    func onProfileSaved() async {
        hasProfile = true
        await ensureNutritionTargets()
    }

    // MARK: - ViewModel

    func getOrCreateViewModel() -> FoodAnalysisViewModel {
        if let existing = analysisViewModel { return existing }
        let vm = FoodAnalysisViewModel()
        analysisViewModel = vm
        return vm
    }

    func resetViewModel() {
        analysisViewModel = nil
    }

    // MARK: - Private Startup Tasks

    private func ensureNutritionTargets() async {
        guard (try? await ProfileRepository.shared.getNutritionTargets()) == nil else { return }
        do {
            try await ProfileRepository.shared.generateNutritionTargets()
            print("✓ Nutrition targets generated")
        } catch {
            print("⚠️ Failed to generate nutrition targets: \(error.localizedDescription)")
        }
    }

    private func checkTrophiesOnStartup() async {
        let newTrophies = await TrophyRepository.shared.checkForNewTrophies()
        if !newTrophies.isEmpty {
            print("🏆 \(newTrophies.count) trophy(ies) earned on startup")
        }
    }
}

// MARK: - App Entry Point

@main
struct FoodShutterApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                switch appState.authState {
                case .loading:
                    ZStack {
                        Color.backGround.ignoresSafeArea()
                        VStack(spacing: 16) {
                            Text("FoodShutter")
                                .font(.system(.title, design: .serif, weight: .bold))
                                .foregroundStyle(.mainText)
                            ProgressView()
                                .tint(.mainEnable)
                        }
                    }

                case .unauthenticated:
                    AuthView()
                        .environmentObject(appState)

                case .authenticated:
                    if !appState.hasProfile {
                        OnboardingFlowView {
                            Task { await appState.onProfileSaved() }
                        }
                    } else {
                        CameraView()
                            .environmentObject(appState)
                            .environmentObject(appState.getOrCreateViewModel())
                    }
                }
            }
            .preferredColorScheme(.light)
        }
    }
}

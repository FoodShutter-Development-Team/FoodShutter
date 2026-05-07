//
//  FoodShutterApp.swift
//  FoodShutter
//
//  App entry point & routing (Supabase cloud version)
//

import SwiftUI
import Combine
import Supabase

// MARK: - Auth State

enum AuthState {
    case loading        // Checking session at startup
    case authenticated  // Signed in
    case unauthenticated // Not signed in; shows AuthView
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var authState: AuthState = .loading
    @Published var hasProfile: Bool = false
    private var analysisViewModel: FoodAnalysisViewModel?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Start auth listener (single entry point, handles initialSession + subsequent events)
        AuthManager.shared.startListening()

        // Once the initial session is resolved, set the auth state
        AuthManager.shared.$initialSessionResolved
            .filter { $0 }
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.checkAuthState() }
            }
            .store(in: &cancellables)

        // Continuously observe currentUser changes (sign-in/sign-out both trigger routing)
        AuthManager.shared.$currentUser
            .dropFirst() // Skip initial nil
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
        guard AuthManager.shared.currentUser != nil else {
            authState = .unauthenticated
            return
        }
        // Validate the session is still live on the server (catches deleted-user scenario)
        guard (try? await supabase.auth.user()) != nil else {
            try? await AuthManager.shared.signOut()
            authState = .unauthenticated
            return
        }
        do {
            let profileExists = try await ProfileRepository.shared.hasProfile()
            hasProfile = profileExists
            authState  = .authenticated
            if profileExists {
                await checkTrophiesOnStartup()
            }
        } catch {
            try? await AuthManager.shared.signOut()
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

    private func checkTrophiesOnStartup() async {
        await TrophyRepository.shared.seedDemoTrophiesIfNeeded()
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
            .onOpenURL { url in
                Task {
                    try? await supabase.auth.session(from: url)
                }
            }
        }
    }
}

//
//  AuthViewModel.swift
//  FoodShutter
//
//  邮箱登录 / 注册 + Apple Sign-In ViewModel
//

import AuthenticationServices
import Combine
import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email:        String = ""
    @Published var password:     String = ""
    @Published var isLoading:    Bool   = false
    @Published var errorMessage: String? = nil
    @Published var isSignUp:     Bool   = false

    /// Apple Sign-In 用的 nonce
    var currentNonce: String?

    // MARK: - Email Auth

    func submit() async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if isSignUp {
                try await AuthManager.shared.signUp(email: email, password: password)
            } else {
                try await AuthManager.shared.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = localizedMessage(for: error)
        }
    }

    func toggleMode() {
        isSignUp.toggle()
        errorMessage = nil
    }

    // MARK: - Apple Sign-In

    /// 返回 hashed nonce 用于 Apple request.nonce，同时保存 raw nonce
    func prepareAppleSignIn() -> String {
        let raw = AuthManager.shared.generateRawNonce()
        currentNonce = raw  // 保存原始 nonce，后续传给 Supabase
        return AuthManager.shared.sha256(raw)  // 返回 hash 给 Apple
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unexpected Apple credential type"
                return
            }
            guard let rawNonce = currentNonce else {
                errorMessage = "Missing nonce for Apple Sign-In"
                return
            }
            do {
                try await AuthManager.shared.signInWithApple(credential: credential, rawNonce: rawNonce)
                print("✓ Apple Sign-In succeeded")
            } catch {
                print("⚠️ Apple Sign-In failed: \(error)")
                errorMessage = localizedMessage(for: error)
            }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = localizedMessage(for: error)
        }
    }

    // MARK: - Private

    private func validate() -> Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your email address"
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        return true
    }

    private func localizedMessage(for error: Error) -> String {
        let description = error.localizedDescription.lowercased()
        if description.contains("invalid login") || description.contains("invalid credentials") {
            return "Incorrect email or password"
        } else if description.contains("already registered") || description.contains("already exists") {
            return "This email is already registered. Please sign in."
        } else if description.contains("network") || description.contains("connection") {
            return "Network error. Please check your connection."
        }
        return error.localizedDescription
    }
}

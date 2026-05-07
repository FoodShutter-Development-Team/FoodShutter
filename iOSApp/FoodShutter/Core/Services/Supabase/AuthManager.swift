//
//  AuthManager.swift
//  FoodShutter
//
//  Supabase authentication state management (Email + Apple Sign-In)
//

import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import Supabase

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUser: User? = nil

    /// Whether the initial session has been resolved (used by AppState to wait for startup completion)
    @Published var initialSessionResolved = false

    private init() {}

    // MARK: - Auth Lifecycle

    /// Start listening for auth state changes (single entry point, handles initialSession + subsequent events)
    func startListening() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let session, !session.isExpired {
                        self.currentUser = session.user
                    } else {
                        self.currentUser = nil
                    }
                    self.initialSessionResolved = true

                case .signedIn, .tokenRefreshed, .userUpdated:
                    if let session, !session.isExpired {
                        self.currentUser = session.user
                    }

                case .signedOut:
                    self.currentUser = nil

                default:
                    break
                }
            }
        }
    }

    // MARK: - Email Auth

    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(email: email, password: password)
        currentUser = response.user
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUser = session.user
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        currentUser = nil
    }

    /// Send a password reset email
    func sendPasswordReset(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    /// Send a magic link to the given email (OTP sign-in)
    func sendMagicLink(email: String) async throws {
        try await supabase.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "foodshutter://auth-callback")
        )
    }

    // MARK: - Apple Sign-In

    /// Generate a random nonce string (raw value)
    func generateRawNonce() -> String {
        // 32 bytes of random data, encoded as hex
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// SHA256-hash the raw nonce for use as Apple's request.nonce
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Sign in to Supabase using an Apple credential and the raw nonce
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, rawNonce: String) async throws {
        guard let identityTokenData = credential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.missingAppleToken
        }

        // Pass rawNonce to Supabase; Supabase will hash it and compare against the nonce in the id_token
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: rawNonce)
        )
        currentUser = session.user
    }

    // MARK: - Account Management

    /// Delete account: removes the profiles record (cascading all data), then signs out
    func deleteAccount() async throws {
        guard let userId = currentUser?.id else { return }
        try await supabase
            .from("profiles")
            .delete()
            .eq("id", value: userId)
            .execute()
        try await signOut()
    }

    // MARK: - Helpers

    var userEmail: String? {
        currentUser?.email
    }

    var userId: UUID? {
        currentUser?.id
    }

    var isAppleUser: Bool {
        currentUser?.appMetadata["provider"]?.stringValue == "apple"
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case missingAppleToken

    var errorDescription: String? {
        switch self {
        case .missingAppleToken:
            return "Failed to get identity token from Apple"
        }
    }
}

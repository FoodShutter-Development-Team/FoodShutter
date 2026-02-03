//
//  AuthManager.swift
//  FoodShutter
//
//  Supabase 认证状态管理（Email + Apple Sign-In）
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

    /// 初始 session 是否已解析（用于 AppState 等待启动完成）
    @Published var initialSessionResolved = false

    private init() {}

    // MARK: - Auth Lifecycle

    /// 启动监听（唯一入口，处理 initialSession + 后续事件）
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

    /// 发送密码重置邮件
    func sendPasswordReset(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    // MARK: - Apple Sign-In

    /// 生成随机 nonce 字符串（原始值）
    func generateRawNonce() -> String {
        // 32 字节随机数据，编码为 hex
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// 对原始 nonce 做 SHA256，用于 Apple 的 request.nonce
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// 使用 Apple credential + 原始 nonce 登录 Supabase
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, rawNonce: String) async throws {
        guard let identityTokenData = credential.identityToken,
              let idToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.missingAppleToken
        }

        // 传 rawNonce 给 Supabase，Supabase 会自行 hash 后与 id_token 中的 nonce 比对
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: rawNonce)
        )
        currentUser = session.user
    }

    // MARK: - Account Management

    /// 删除账户：先删除 profiles 记录（级联删除所有数据），再登出
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

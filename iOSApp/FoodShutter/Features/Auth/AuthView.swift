//
//  AuthView.swift
//  FoodShutter
//
//  登录 / 注册界面（Email + Apple Sign-In）
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @FocusState  private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ZStack {
            Color.backGround.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 100)

                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.isSignUp ? "Create\nAccount" : "Welcome\nBack")
                            .font(.system(.largeTitle, design: .serif, weight: .heavy))
                            .foregroundStyle(.mainText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(viewModel.isSignUp
                            ? "Sign up to start tracking your nutrition"
                            : "Sign in to continue your journey")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(.mainText.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)

                    // MARK: - Divider
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 2)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    // MARK: - Apple Sign-In
                    SignInWithAppleButton(.continue) { request in
                        let nonce = viewModel.prepareAppleSignIn()
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = nonce
                    } onCompletion: { result in
                        Task { await viewModel.handleAppleSignIn(result: result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
                    .fixedSize(horizontal: false, vertical: true)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    // MARK: - "or" divider
                    HStack {
                        Rectangle().fill(.mainText.opacity(0.2)).frame(height: 1)
                        Text("or")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(.mainText.opacity(0.4))
                        Rectangle().fill(.mainText.opacity(0.2)).frame(height: 1)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    // MARK: - Email Form
                    VStack(spacing: 28) {
                        AuthInputField(
                            title:       "Email",
                            placeholder: "your@email.com",
                            text:        $viewModel.email,
                            isSecure:    false
                        )
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                        AuthInputField(
                            title:       "Password",
                            placeholder: "at least 6 characters",
                            text:        $viewModel.password,
                            isSecure:    true
                        )
                        .focused($focusedField, equals: .password)
                        .textContentType(viewModel.isSignUp ? .newPassword : .password)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    // MARK: - Error Message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(.caption, design: .serif, weight: .semibold))
                            .foregroundStyle(.mainEnable)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    Spacer().frame(height: 32)

                    // MARK: - Email Submit Button
                    Button {
                        focusedField = nil
                        Task { await viewModel.submit() }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.mainEnable)
                            } else {
                                Text(viewModel.isSignUp ? "Sign Up" : "Sign In")
                                    .font(.system(.title3, design: .serif, weight: .bold))
                                    .foregroundStyle(.mainEnable)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }
                    .buttonStyle(.glass)
                    .padding(.horizontal, 24)
                    .disabled(viewModel.isLoading)

                    Spacer().frame(height: 20)

                    // MARK: - Toggle Mode
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.toggleMode()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(.mainText.opacity(0.6))
                            Text(viewModel.isSignUp ? "Sign In" : "Sign Up")
                                .foregroundStyle(.userEnable)
                        }
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                    }
                    .buttonStyle(.plain)

                    Spacer().frame(height: 60)
                }
            }
            .scrollIndicators(.never)
        }
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
    }
}

// MARK: - AuthInputField

private struct AuthInputField: View {
    let title:       String
    let placeholder: String
    @Binding var text: String
    let isSecure:    Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.subheadline, design: .serif, weight: .bold))
                .foregroundStyle(.mainText)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(.body, design: .serif))
            .foregroundStyle(.mainText)
            .padding(.vertical, 6)

            Rectangle()
                .fill(.mainText.opacity(0.3))
                .frame(height: 1.5)
        }
    }
}

#Preview {
    AuthView()
}

//
//  AuthView.swift
//  FoodShutter
//
//  登录 / 注册界面（Email + Apple Sign-In + Magic Link）
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            Color.backGround.ignoresSafeArea()

            if viewModel.magicLinkMode {
                MagicLinkView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal:   .move(edge: .trailing)
                    ))
            } else {
                EmailPasswordView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal:   .move(edge: .leading)
                    ))
            }
        }
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.35), value: viewModel.magicLinkMode)
        .animation(.easeInOut(duration: 0.3),  value: viewModel.errorMessage)
    }
}

// MARK: - Email / Password View

private struct EmailPasswordView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Header
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

                Rectangle()
                    .fill(.mainText)
                    .frame(height: 2)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                // Apple Sign-In
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

                orDivider

                Spacer().frame(height: 20)

                // Email Form
                VStack(spacing: 28) {
                    AuthInputField(
                        title:       "Email",
                        placeholder: "your@email.com",
                        text:        $viewModel.email,
                        isSecure:    false
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                    AuthInputField(
                        title:       "Password",
                        placeholder: "at least 6 characters",
                        text:        $viewModel.password,
                        isSecure:    true
                    )
                    .textContentType(viewModel.isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(.caption, design: .serif, weight: .semibold))
                        .foregroundStyle(.mainEnable)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }

                Spacer().frame(height: 32)

                // Submit button
                Button {
                    Task { await viewModel.submit() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.mainEnable)
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

                // Toggle sign-in / sign-up
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { viewModel.toggleMode() }
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

                Spacer().frame(height: 16)

                // Magic link entry
                Button {
                    withAnimation { viewModel.enterMagicLinkMode() }
                } label: {
                    Text("Send a Magic Link instead")
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(.mainText.opacity(0.45))
                }
                .buttonStyle(.plain)

                Spacer().frame(height: 60)
            }
        }
        .scrollIndicators(.never)
    }

    private var orDivider: some View {
        HStack {
            Rectangle().fill(.mainText.opacity(0.2)).frame(height: 1)
            Text("or")
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(.mainText.opacity(0.4))
            Rectangle().fill(.mainText.opacity(0.2)).frame(height: 1)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Magic Link View

private struct MagicLinkView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 100)

                // Back button
                Button {
                    withAnimation { viewModel.exitMagicLinkMode() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(.mainText.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Magic\nLink")
                        .font(.system(.largeTitle, design: .serif, weight: .heavy))
                        .foregroundStyle(.mainText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("We'll email you a sign-in link — no password needed")
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(.mainText.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 40)

                Rectangle()
                    .fill(.mainText)
                    .frame(height: 2)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                if viewModel.magicLinkSent {
                    // Confirmation state
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.checkmark")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.mainText)

                        Text("Check your inbox")
                            .font(.system(.title3, design: .serif, weight: .bold))
                            .foregroundStyle(.mainText)

                        Text("A sign-in link was sent to\n\(viewModel.email)")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(.mainText.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    // Email input + send button
                    AuthInputField(
                        title:       "Email",
                        placeholder: "your@email.com",
                        text:        $viewModel.email,
                        isSecure:    false
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(.caption, design: .serif, weight: .semibold))
                            .foregroundStyle(.mainEnable)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    Spacer().frame(height: 32)

                    Button {
                        Task { await viewModel.sendMagicLink() }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.mainEnable)
                            } else {
                                Text("Send Magic Link")
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
                }

                Spacer().frame(height: 60)
            }
        }
        .scrollIndicators(.never)
        .animation(.easeInOut(duration: 0.3), value: viewModel.magicLinkSent)
    }
}

// MARK: - Field enum (shared)
private enum Field { case email, password }

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

//
//  OnboardingFlowView.swift
//  FoodShutter
//
//  Guides new users through filling in their profile after first login (Supabase version)
//

import SwiftUI

private enum OnboardingStep {
    case welcome
    case info(name: String)
}

struct OnboardingFlowView: View {
    @State private var step: OnboardingStep = .welcome

    let onFinished: () -> Void

    var body: some View {
        VStack {
            switch step {
            case .welcome:
                WelcomeView { name in
                    step = .info(name: name)
                }

            case .info(let name):
                // New user has no existing profile; pass nil for profile and the name collected in WelcomeView
                InfoView(
                    initialName:     name,
                    profile:         nil,
                    onFinished:      { onFinished() },
                    showResetButton: false
                )
            }
        }
        .background(.backGround)
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingFlowView { }
}

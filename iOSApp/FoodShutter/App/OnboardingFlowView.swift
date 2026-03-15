//
//  OnboardingFlowView.swift
//  FoodShutter
//
//  首次登录后引导用户填写资料（Supabase 版）
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
                // 新用户无已有资料，profile 传 nil，initialName 传 WelcomeView 收集的姓名
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

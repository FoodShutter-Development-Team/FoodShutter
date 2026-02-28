//
//  TypingAnimationText.swift
//  FoodShutter
//
//  Reusable typing animation component for loading states
//

import SwiftUI

struct TypingAnimationText: View {
    @State private var displayedText = ""
    @State private var isTyping = true
    var fullText = "Analyzing..."

    var body: some View {
        Text(displayedText)
            .font(.system(.title2, design: .serif, weight: .bold))
            .foregroundStyle(.mainEnable)
            .onAppear {
                startTypingAnimation()
            }
    }

    private func startTypingAnimation() {
        typingCycle()
    }

    private func typingCycle() {
        // 打字阶段
        var currentIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if currentIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: currentIndex)
                displayedText = String(fullText[...index])
                currentIndex += 1
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    deleteText()
                }
            }
        }
    }

    private func deleteText() {
        // 删除阶段 - 更快速
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if !displayedText.isEmpty {
                displayedText.removeLast()
            } else {
                timer.invalidate()
                // 等待 0.3 秒后重新开始
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    typingCycle()
                }
            }
        }
    }
}

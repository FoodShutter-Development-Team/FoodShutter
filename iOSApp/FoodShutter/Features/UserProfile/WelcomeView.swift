//
//  WelcomeView.swift
//  FoodShutter
//
//  原先的欢迎页拆分为独立文件
//

import SwiftUI

struct WelcomeView: View {
    @State private var name: String = ""
    var onContinue: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 0){
            Spacer().frame(height: 40)
            Spacer()
            Text("Welcome!")
                .font(.largeTitle)
                .fontDesign(.serif)
                .fontWeight(.heavy)
                .foregroundStyle(.mainText)
            Spacer().frame(height: 40)

            TypewriterTextInput(text: "May I ask your name?", input: $name)
                .font(.title2)
            Spacer()

            Button{
                onContinue?(name)
            } label: {
                Text("Done")
                    .font(.title3)
                    .fontDesign(.serif)
                    .fontWeight(.bold)
                    .foregroundStyle(.mainEnable)
                    .padding(5)
                    .frame(width: 80)
            }
            .buttonStyle(.glass)
            .opacity(name.isEmpty ? 0.5 : 1.0)
            .disabled(name.isEmpty)
            Spacer().frame(height: 40)
        }
        .animation(.easeInOut, value: name.isEmpty)
    }
}

#Preview {
    WelcomeView()
}

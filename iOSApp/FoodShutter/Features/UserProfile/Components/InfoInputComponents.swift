//
//  InfoViewComponents.swift
//  FoodShutter
//
//  Created by Cosmos on 16/10/2025.
//

import SwiftUI

struct BMIInput: View {
    @Binding var weightValue: Int
    @Binding var heightValue: Int
    @Binding var BMI: Double
    
    var body: some View {
        VStack() {
            Rectangle()
                .frame(height: 3)
                .padding(.horizontal)
            
            Text("Your height and weight\nhelp us create the perfect plan for you.")
                .font(.subheadline)
                .fontDesign(.serif)
                .fontWeight(.heavy)
                .foregroundStyle(.mainText)
                .frame(maxWidth: .infinity,alignment: .leading)
                .padding(.horizontal)
            
            Rectangle()
                .frame(height: 2)
                .padding(.horizontal)
            
            HStack {
                VStack{
                    Text("Weight")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                    
                    Picker("Weight", selection: $weightValue) {
                        ForEach(10...200, id: \.self) { weight in
                            Text("\(weight) kg")
                                .foregroundStyle(.userEnable)
                                .tag(weight)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 160,height: 100)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                VStack{
                    Text("Height")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                    
                    Picker("Height", selection: $heightValue) {
                        ForEach(10...240, id: \.self) { height in
                            Text("\(height) cm")
                                .foregroundStyle(.userEnable)
                                .tag(height)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 160,height: 100)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
            }
            .onChange(of: weightValue) { oldValue, newValue in
                withAnimation {
                    BMI = CalculateBMI(weight: newValue, height: heightValue)
                }
            }
            .onChange(of: heightValue) { oldValue, newValue in
                withAnimation {
                    BMI = CalculateBMI(weight: weightValue, height: newValue)
                }
            }
            .onAppear {
                // Calculate BMI on appear to ensure it's never -1
                if BMI < 0 {
                    BMI = CalculateBMI(weight: weightValue, height: heightValue)
                }
            }

            HStack(alignment: .bottom){
                VStack(spacing: 0){
                    Rectangle()
                        .frame(height: 2)
                    HStack{
                        Text("BMI")
                            .font(.system(size: 25, weight: .heavy, design: .serif))
                        Text((BMI>0) ? String(format: "%.1f", BMI) :  " ")
                            .font(.system(size: 25, weight: .heavy, design: .serif))
                            .frame(maxWidth: .infinity)
                    }
                    Rectangle()
                        .frame(height: 2)
                    Text(BMISuggestion(BMI: BMI))
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .padding(.vertical,5)
                }
            }
            .padding(.horizontal)
            
            
        }
        .fontDesign(.serif)
        .foregroundStyle(.mainText)
    }
}

func BMISuggestion(BMI: Double) -> String {
    if BMI < 0.0 {
        return "Please input your infomation :)"
    } else if BMI < 18.5 {
        return "[Underweight] Consider gaining weight"
    } else if BMI >= 18.5 && BMI < 25.0 {
        return "[Normal weight] Great job!"
    } else if BMI >= 25.0 && BMI < 30.0 {
        return "[Overweight] Consider loosing weight"
    } else {
        return "[Obese] Consider loosing weight"
    }
}

struct TypewriterText: View {
    let text: String
    let interval: Double
    var offset: Double = 0
    var isUnderline: Bool = false
    var underlineColor: Color = .mainText
    var underlineWidth: Int = 11
    var ableCursur = true
    @State private var displayed = ""
    @State private var showCursor = true

    var body: some View {
        VStack(spacing: 0){
            HStack(alignment: .bottom,spacing: 0) {
                Text(displayed)
                if ableCursur && !(displayed.count==text.count){
                    Text("|")
                        .opacity(showCursor ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: showCursor)
                }
            }
            if isUnderline{
                Rectangle()
                    .fill(underlineColor)
                    .frame(width: CGFloat(displayed.count * underlineWidth),height: 2)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + offset){
                type()
                blinkCursor()
            }
        }
    }

    func type() {
        displayed = ""
        for (i, c) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                displayed.append(c)
            }
        }
    }

    func blinkCursor() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            showCursor.toggle()
        }
    }
}

struct TypewriterTextInput: View {
    let text: String
    var interval: Double = 0.05
    var font: Font = .title2
    var fontWeight: Font.Weight = .semibold
    var alignment: TextAlignment = .center
    @State private var displayed = ""
    @State private var showCursor = true
    @State private var measuredWidth: CGFloat = 16
    @Binding var input: String

    private var activeText: String {
        input.isEmpty ? displayed : input
    }

    private var underlineColor: Color {
        input.isEmpty ? .mainEnable : .mainText
    }

    private var zstackAlignment: Alignment {
        switch alignment {
        case .leading: return .bottomLeading
        case .trailing: return .bottomTrailing
        default: return .bottom
        }
    }

    private var vstackAlignment: HorizontalAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        default: return .center
        }
    }

    var body: some View {
        ZStack(alignment: zstackAlignment) {
            VStack(alignment: vstackAlignment, spacing: 4) {
                HStack(spacing: 0) {
                    Text(displayed)
                    if displayed.count != text.count {
                        Text("|")
                            .opacity(showCursor ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(), value: showCursor)
                    }
                }
                .foregroundStyle(.mainEnable)
                .fontDesign(.serif)
                .fontWeight(fontWeight)
                .font(font)
                .opacity(input.isEmpty ? 1 : 0)

                Rectangle()
                    .fill(underlineColor)
                    .frame(width: max(measuredWidth, 12), height: 2)
            }

            TextField("", text: $input)
                .multilineTextAlignment(alignment)
                .foregroundStyle(.mainText)
                .fontDesign(.serif)
                .fontWeight(fontWeight)
                .font(font)
                .tint(.mainText)
                .lineLimit(1)
        }
        .animation(.easeInOut, value: input.isEmpty)
        .background(
            HiddenWidthReader(
                text: activeText.isEmpty ? " " : activeText,
                font: font,
                weight: fontWeight
            ) { width in
                measuredWidth = width
            }
        )
        .onAppear {
            type()
            blinkCursor()
        }
        .onChange(of: text) { _, _ in
            displayed = ""
            type()
        }
    }

    func type() {
        displayed = ""
        for (i, c) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                displayed.append(c)
            }
        }
    }

    func blinkCursor() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            showCursor.toggle()
        }
    }
}

func CalculateBMI(weight: Int, height: Int) -> Double {
    return Double(weight) / pow(Double(height) / 100, 2)
}

// MARK: - Helpers

private struct HiddenWidthReader: View {
    let text: String
    let font: Font
    let weight: Font.Weight
    var onChange: (CGFloat) -> Void

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(weight)
            .fontDesign(.serif)
            .lineLimit(1)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: TextWidthPreferenceKey.self, value: proxy.size.width)
                }
            )
            .hidden()
            .onPreferenceChange(TextWidthPreferenceKey.self, perform: onChange)
    }
}

private struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    TypewriterText(text:"I need some information to work better for you.", interval: 0.05,isUnderline: false)
        .font(.title2)
        .fontDesign(.serif)
        .fontWeight(.heavy)
        .foregroundStyle(.mainText)
}

//
//  InfoView.swift
//  FoodShutter
//
//  Created by Cosmos on 14/10/2025.
//

import SwiftUI
import UIKit

// 纯输入页面（无 welcome、无后退）
struct InfoView: View {
    var initialName: String? = nil
    var profile: UserNutritionProfile? = nil
    var onFinished: (() -> Void)? = nil
    var showResetButton: Bool = false  // 已移至 SettingListView 账户操作区

    var body: some View {
        ZStack{
            Color.backGround
            InfoInputList(
                initialName: initialName,
                profile: profile,
                onFinished: onFinished,
                showResetButton: showResetButton
            )
                .padding(20)
        }
        .ignoresSafeArea()
    }
}

struct InfoInputList: View {
    @Environment(\.dismiss) private var dismiss
    @State var name: String = ""
    let initialName: String?
    let profile: UserNutritionProfile?
    let onFinished: (() -> Void)?
    let showResetButton: Bool
    
    // --- 原有状态 ---
    @State private var selected: [String] = []
    @State private var BMI: Double = -1
    @State private var weightValue: Int = 70
    @State private var heightValue: Int = 170

    // --- 新增状态 (New State Variables) ---
    @State private var age: Int = 25
    // Gender 使用 CGFloat 以便制作滑块动画 (0.0 = Male, 1.0 = Female)
    @State private var genderValue: CGFloat = 0.0
    @State private var activityLevelIndex: Int = 0
    @State private var dietPreference: String = ""
    @State private var otherNotes: String = ""
    @State private var keyboardHeight: CGFloat = 0

    // 原始目标列表
    let selectList: [String] = [
        "Build Muscle",
        "Lose Fat",
        "Maintain Weight",
        "Gain Weight",
        "Improve Endurance",
        "Increase Strength",
        "Improve Flexibility",
        "General Fitness",
        "Body Recomposition"
    ]
    
    // 活动水平选项 (更专业易懂的描述 - 精简版)
    struct ActivityOption: Hashable {
        let id: Int
        let title: String
        let desc: String
    }
    
    let activityOptionsData: [ActivityOption] = [
        ActivityOption(id: 0, title: "Sedentary", desc: "No exercise"),
        ActivityOption(id: 1, title: "Lightly Active", desc: "1-3 days/wk"),
        ActivityOption(id: 2, title: "Moderately Active", desc: "4-5 days/wk"),
        ActivityOption(id: 3, title: "Active", desc: "Daily or 3-4 intense"),
        ActivityOption(id: 4, title: "Very Active", desc: "6-7 intense days"),
        ActivityOption(id: 5, title: "Extra Active", desc: "Physical job/training")
    ]

    init(
        initialName: String? = nil,
        profile: UserNutritionProfile? = nil,
        onFinished: (() -> Void)? = nil,
        showResetButton: Bool = false
    ) {
        self.initialName     = initialName
        self.profile         = profile
        self.onFinished      = onFinished
        self.showResetButton = showResetButton

        // 使用传入的 profile，若无则使用默认值
        let resolvedWeight = profile?.weight ?? 70.0
        let resolvedHeight = profile?.height ?? 170.0
        let resolvedAge    = profile?.age    ?? 25

        let resolvedName: String
        if let n = initialName, !n.isEmpty {
            resolvedName = n
        } else {
            resolvedName = profile?.name ?? ""
        }

        _name             = State(initialValue: resolvedName)
        _selected         = State(initialValue: profile?.goals ?? [])
        _weightValue      = State(initialValue: Int(resolvedWeight))
        _heightValue      = State(initialValue: Int(resolvedHeight))
        _age              = State(initialValue: resolvedAge)
        _genderValue      = State(initialValue: (profile?.gender.lowercased() == "female") ? 1.0 : 0.0)
        _dietPreference   = State(initialValue: profile?.preference ?? "")
        _otherNotes       = State(initialValue: profile?.other ?? "")
        _BMI              = State(initialValue: CalculateBMI(weight: Int(resolvedWeight), height: Int(resolvedHeight)))

        if let al = profile?.activityLevel,
           let idx = activityOptionsData.firstIndex(where: { $0.title == al }) {
            _activityLevelIndex = State(initialValue: idx)
        }
    }

    var body: some View {
        VStack{
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 120)

                    // --- Header ---
                    VStack(alignment: .leading){
                        HStack(alignment: .bottom){
                            Text("Hi")
                            TypewriterTextInput(
                                text: name.isEmpty ? "" : name,
                                font: .largeTitle,
                                fontWeight: .heavy,
                                alignment: .leading,
                                input: $name
                            )
                            .offset(y:1)
                        }
                        Text("welcome !")
                    }
                    .font(.largeTitle)
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .foregroundStyle(.mainText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    

                    Spacer().frame(height: 30)

                    Text("I need some \ninformation to work better for you.")
                        .font(.subheadline)
                        .fontDesign(.serif)
                        .fontWeight(.heavy)
                        .foregroundStyle(.mainText)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity,alignment: .leading)
                        .padding(.horizontal)

                    
                    // --- Section 2: Age & Gender (Compact Style) ---
                    // 整体作为一个Block，用粗横线分割
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 3)
                            .padding(.horizontal)
                        
                        // Age Row (Smaller Stepper)
                        HStack {
                            Text("Age")
                                .font(.headline) // Smaller font
                                .fontWeight(.bold)
                                .fontDesign(.serif)
                                .foregroundStyle(.mainText)
                            
                            Spacer()
                            
                            HStack(spacing: 15) {
                                Button(action: { if age > 10 { age -= 1 } }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .bold)) // Smaller icon
                                        .frame(width: 28, height: 28) // Smaller button size
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(style: .init(lineWidth: 2))
                                        )
                                }
                                .foregroundStyle(.userEnable)
                                
                                Text("\(age)")
                                    .font(.system(size: 20, weight: .heavy, design: .serif))
                                    .foregroundStyle(.mainText)
                                    .frame(width: 40)
                                
                                Button(action: { if age < 100 { age += 1 } }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold)) // Smaller icon
                                        .frame(width: 28, height: 28) // Smaller button size
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(style: .init(lineWidth: 2))
                                        )
                                }
                                .foregroundStyle(.userEnable)
                            }
                        }
                        .padding(.vertical, 10) // Reduced padding
                        .padding(.horizontal)
                        
                        // Divider inside the block
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 2)
                            .padding(.horizontal)
                        
                        // Gender Row (Smaller Slider)
                        HStack {
                            Text("Gender")
                                .font(.headline) // Smaller font
                                .fontWeight(.bold)
                                .fontDesign(.serif)
                                .foregroundStyle(.mainText)
                            
                            Spacer()
                            
                            // Custom Slider (Compact)
                            HStack {
                                ZStack(alignment: .leading) {
                                    // Track
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(style: .init(lineWidth: 2))
                                        .foregroundStyle(.mainText)
                                    
                                    // Thumb
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(.userEnable)
                                        .frame(width: 78, height: 30 - 4)
                                        .padding(.leading,2)
                                        .offset(x: genderValue * 78, y: 0)
                                        .animation(.easeInOut(duration: 0.3), value: genderValue)
                                    
                                    HStack {
                                        Text("Male")
                                            .foregroundStyle(genderValue < 0.5 ? .backGround : .userEnable)
                                            .frame(maxWidth: .infinity)
                                        Text("Female")
                                            .foregroundStyle(genderValue > 0.5 ? .backGround : .userEnable)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .frame(width: 160)
                                    .font(.system(size: 14,weight: .bold ,design: .serif))
                                    .animation(.easeInOut(duration: 0.3), value: genderValue)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    genderValue = genderValue < 0.5 ? 1.0 : 0.0
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if value.location.x > 160 / 2 {
                                                genderValue = 1.0
                                            } else {
                                                genderValue = 0.0
                                            }
                                        }
                                )
                                .frame(width: 160,height: 30)
                            }
                        }
                        .padding(.top, 10) // Reduced padding
                        .padding(.horizontal)
                    }

                    // --- Section 3: BMI (Reordered: Now after Age/Gender) ---
                    // BMIInput has its own internal spacing/lines, fitting the style
                    BMIInput(weightValue: $weightValue, heightValue: $heightValue, BMI: $BMI)
                        .padding(.vertical, 10)

                    // --- Section 4: Activity Level (Reordered) ---
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 3)
                            .padding(.horizontal)
                        
                        Text("Daily Activity")
                            .font(.subheadline)
                            .fontDesign(.serif)
                            .fontWeight(.heavy)
                            .foregroundStyle(.mainText)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 2)
                            .padding(.horizontal)
                        
                        Picker("Activity Level", selection: $activityLevelIndex) {
                            ForEach(activityOptionsData, id: \.id) { option in
                                Text("\(option.title) (\(option.desc))")
                                    .font(.system(size: 16, design: .serif))
                                    .foregroundStyle(.userEnable)
                                    .tag(option.id)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 100) // Slightly more compact
                        .clipped()
                        .padding(.horizontal)
                    }
                    
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 3)
                        .padding(.horizontal)

                    // --- Section 1: Goals (Existing) ---
                    sectionTitle("Which goals interest you?")

                    LazyVGrid(columns: Array(repeatElement(GridItem(.flexible()), count: 3)),spacing: 0) {
                        ForEach(selectList, id: \.self){ option in
                            Button{
                                if let ind = selected.firstIndex(of: option) {
                                    selected.remove(at: ind)
                                } else {
                                    selected.append(option)
                                }
                            } label: {
                                SelectableButtonContent(text: option, isSelected: selected.contains(option))
                            }
                        }
                        .padding(10)
                    }
                    .padding(.horizontal)
                    
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 3)
                        .padding(.horizontal)
                        .padding(.top,10)

                    // --- Section 5: Diet & Notes (Reordered & Underline Style) ---
                    VStack(alignment: .leading, spacing: 10) {
                        CustomTextField(title: "Dietary Preference", placeholder: "e.g. Vegetarian", text: $dietPreference)
                        Rectangle()
                            .fill(.mainText)
                            .frame(height: 2)
                        CustomTextField(title: "Other Notes", placeholder: "Allergies, injuries...", text: $otherNotes)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    Rectangle()
                        .fill(.mainText)
                        .frame(height: 3)
                        .padding(.horizontal)
                        .padding(.top,10)
                    
                    Spacer().frame(height: 30)

                    Button{
                        saveProfile()
                    } label: {
                        Text("Done")
                            .fontDesign(.serif)
                            .fontWeight(.bold)
                            .foregroundStyle(.userEnable)
                            .padding(5)
                            .frame(width: 80)
                    }
                    .buttonStyle(.glass)
                    .disabled(BMI == -1 || name.isEmpty)

                    if showResetButton {
                        Button {
                            resetProfile()
                        } label: {
                            Text("Reset")
                                .fontDesign(.serif)
                                .fontWeight(.bold)
                                .foregroundStyle(.mainEnable)
                                .padding(5)
                                .frame(width: 80)
                        }
                        .buttonStyle(.glass)
                        .padding(.vertical, 5)

                        //Button {
                        //    generateTestData()
                        //} label: {
                        //    Text("Add Test Data")
                        //        .fontDesign(.serif)
                        //        .fontWeight(.bold)
                        //        .foregroundStyle(.userEnable)
                        //        .padding(5)
                        //        .frame(width: 140)
                        //}
                        //.buttonStyle(.glass)
                        //.padding(.vertical, 5)
                    }

                    Spacer().frame(height: 40)

                }
                .animation(.easeInOut(duration: 0.6), value: name.isEmpty)
            }
            .scrollIndicators(.never)
            .scrollDismissesKeyboard(.interactively)
            .padding(.bottom, keyboardHeight)
            .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = 0
                }
            }

        }
    }
    
    // Helper view for consistent button style
    struct SelectableButtonContent: View {
        let text: String
        let isSelected: Bool
        
        var body: some View {
            if isSelected {
                Text(text)
                    .font(.system(size: 15, design: .serif))
                    .fontWeight(.heavy)
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(style: .init(lineWidth: 2.5))
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.backGround)
                                    .shadow(radius: 3)
                            )
                    )
                    .foregroundStyle(.userEnable)
            } else {
                Text(text)
                    .font(.system(size: 15, design: .serif))
                    .fontWeight(.semibold)
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(style: .init(lineWidth: 2.5))
                    )
                    .foregroundStyle(.mainText)
            }
        }
    }
    
    // Helper for Section Titles
    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fontDesign(.serif)
            .fontWeight(.heavy)
            .foregroundStyle(.mainText)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.horizontal, 10)
            .padding(.top, 5)
    }

    private func selectedGender() -> String {
        genderValue < 0.5 ? "Male" : "Female"
    }

    private func selectedActivityTitle() -> String {
        if activityLevelIndex < activityOptionsData.count {
            return activityOptionsData[activityLevelIndex].title
        }
        return "Moderately Active"
    }

    private func saveProfile() {
        let updatedProfile = UserNutritionProfile(
            name:          name,
            weight:        Double(weightValue),
            height:        Double(heightValue),
            age:           age,
            gender:        selectedGender(),
            activityLevel: selectedActivityTitle(),
            goals:         selected,
            preference:    dietPreference,
            other:         otherNotes
        )

        Task {
            do {
                // 上传到 Supabase profiles 表
                try await ProfileRepository.shared.upsertProfile(updatedProfile)
                print("✓ Profile saved to Supabase")

                // 后台生成营养目标（不阻断用户流程）
                print("🔄 Generating nutrition targets...")
                try await ProfileRepository.shared.generateNutritionTargets()
                print("✓ Nutrition targets generated")
            } catch {
                print("⚠️ Failed to save profile: \(error.localizedDescription)")
            }
        }

        dismiss()
        onFinished?()
    }

    private func resetProfile() {
        name = ""
        weightValue = 70
        heightValue = 170
        age = 25
        genderValue = 0.0
        activityLevelIndex = 2
        selected = []
        dietPreference = ""
        otherNotes = ""
        BMI = -1
    }

    // MARK: - 已废弃（SwiftData 迁移至 Supabase）

    private func generateTestData() {
        print("🧪 Generating test data...")

        // 1. Create test user profile
        let testProfile = UserNutritionProfile(
            name: "Test User",
            weight: 70.0,
            height: 175.0,
            age: 28,
            gender: "Male",
            activityLevel: "Moderately Active",
            goals: ["Build Muscle", "General Fitness"],
            preference: "No restrictions",
            other: "Test user for demonstration"
        )
        _ = testProfile  // 废弃：原 UserProfileManager 已移除

        // Update UI fields to reflect test profile
        name = testProfile.name
        weightValue = Int(testProfile.weight)
        heightValue = Int(testProfile.height)
        age = testProfile.age
        genderValue = testProfile.gender.lowercased() == "female" ? 1.0 : 0.0
        if let idx = activityOptionsData.firstIndex(where: { $0.title == testProfile.activityLevel }) {
            activityLevelIndex = idx
        }
        selected = testProfile.goals
        dietPreference = testProfile.preference
        otherNotes = testProfile.other
        BMI = CalculateBMI(weight: Int(testProfile.weight), height: Int(testProfile.height))

        print("✓ Test data generation skipped (legacy SwiftData removed)")
    }
}

// Custom styled text field
struct CustomTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline)
                .fontDesign(.serif)
                .fontWeight(.bold)
                .foregroundStyle(.mainText)
            
            // 使用下划线风格 (Typewriter style aesthetic)
            VStack(spacing: 0) {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, design: .serif))
                    .padding(.vertical, 8)
                    .foregroundStyle(.userEnable)
            }
        }
    }
}

#Preview {
    InfoView()
}

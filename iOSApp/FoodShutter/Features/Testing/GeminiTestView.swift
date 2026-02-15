//
//  GeminiTestView.swift
//  FoodShutter
//
//  Test page for backend AI services
//

import SwiftUI
import PhotosUI

struct GeminiTestView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Info banner
                Text("Using backend API (no local API key needed)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGroupedBackground))

                // Tab Selector
                Picker("测试功能", selection: $selectedTab) {
                    Text("📸 食物识别").tag(0)
                    Text("🧠 营养建议").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    FoodImageTestView()
                        .tag(0)

                    DietaryAdviceTestView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("AI 测试")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Food Image Analysis Test

struct FoodImageTestView: View {
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isAnalyzing = false
    @State private var result: FoodAnalysisResult?
    @State private var errorMessage: String?
    @State private var logMessages: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image Selection
                VStack(spacing: 12) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("选择食物图片")
                                        .foregroundColor(.gray)
                                }
                            )
                    }

                    Button(action: { showImagePicker = true }) {
                        Label("选择图片", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAnalyzing)

                    Button(action: analyzeImage) {
                        if isAnalyzing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("开始分析", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImage == nil || isAnalyzing)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // Log Messages
                if !logMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("日志")
                            .font(.headline)

                        ForEach(logMessages, id: \.self) { message in
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }

                // Result Display
                if let result = result {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("分析结果")
                            .font(.headline)

                        Text("识别到 \(result.dishNum) 道菜品")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ForEach(Array(result.dishes.enumerated()), id: \.offset) { index, dish in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(dish.icon)
                                        .font(.title2)
                                    Text("\(index + 1). \(dish.dishName)")
                                        .font(.headline)
                                    Spacer()
                                }

                                ForEach(Array(dish.ingredients.enumerated()), id: \.offset) { _, ingredient in
                                    HStack {
                                        Text(ingredient.icon)
                                        Text(ingredient.name)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(Int(ingredient.weight))g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    HStack(spacing: 12) {
                                        NutrientBadge(
                                            label: "蛋白质",
                                            value: ingredient.proteinPercent,
                                            color: .blue
                                        )
                                        NutrientBadge(
                                            label: "脂肪",
                                            value: ingredient.fatPercent,
                                            color: .orange
                                        )
                                        NutrientBadge(
                                            label: "碳水",
                                            value: ingredient.carbohydratePercent,
                                            color: .green
                                        )
                                    }
                                    .font(.caption)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }

    private func analyzeImage() {
        guard let image = selectedImage else { return }

        isAnalyzing = true
        errorMessage = nil
        result = nil
        logMessages = []

        Task {
            do {
                // Save image to temp file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_food.jpg")
                if let data = image.jpegData(compressionQuality: 0.8) {
                    try data.write(to: tempURL)
                }

                addLog("开始分析图片...")
                let analyzer = GeminiFoodImageAnalyzer()
                let analysisResult = try await analyzer.analyzeFoodImage(imageURL: tempURL)

                await MainActor.run {
                    result = analysisResult
                    addLog("✅ 分析完成！")
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "分析失败: \(error.localizedDescription)"
                    addLog("❌ \(error.localizedDescription)")
                    isAnalyzing = false
                }
            }
        }
    }

    private func addLog(_ message: String) {
        logMessages.append("[\(Date().formatted(date: .omitted, time: .standard))] \(message)")
    }
}

// MARK: - Dietary Advice Test

struct DietaryAdviceTestView: View {
    @State private var isAnalyzing = false
    @State private var result: DietaryAdviceResult?
    @State private var errorMessage: String?
    @State private var logMessages: [String] = []
    @State private var includeHistory: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Test Button
                VStack(spacing: 12) {
                    Text("使用模拟数据测试营养建议")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Toggle("Include nutrition history", isOn: $includeHistory)
                        .font(.caption)
                        .padding(.horizontal)

                    Button(action: testDietaryAdvice) {
                        if isAnalyzing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("获取营养建议", systemImage: "brain.head.profile")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAnalyzing)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // Mock Data Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("模拟场景")
                        .font(.headline)
                    Text("• 午餐：酸汤鱼 + 白米饭 (950 kcal)")
                    Text("• 用户：28岁男性，80kg，久坐，目标减重")
                    Text("• 3天平均：2800 kcal/天 (超标)")
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Log Messages
                if !logMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("日志")
                            .font(.headline)

                        ForEach(logMessages, id: \.self) { message in
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }

                // Result Display
                if let result = result {
                    VStack(alignment: .leading, spacing: 16) {
                        // Analysis
                        VStack(alignment: .leading, spacing: 12) {
                            Text("营养分析")
                                .font(.headline)

                            Text(result.analysis.summary)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)

                            HStack {
                                Text("状态:")
                                    .fontWeight(.semibold)
                                Text(result.analysis.nutritionStatus)
                                    .foregroundColor(.orange)
                            }

                            if !result.analysis.pros.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("✅ 优点")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    ForEach(result.analysis.pros, id: \.self) { pro in
                                        Text("• \(pro)")
                                            .font(.caption)
                                    }
                                }
                            }

                            if !result.analysis.cons.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("⚠️ 缺点")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    ForEach(result.analysis.cons, id: \.self) { con in
                                        Text("• \(con)")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)

                        // Next Meal Recommendation
                        VStack(alignment: .leading, spacing: 12) {
                            Text("下一餐建议")
                                .font(.headline)

                            HStack {
                                Text(result.nextMealRecommendation.recommendedDish.icon)
                                    .font(.system(size: 40))

                                VStack(alignment: .leading) {
                                    Text(result.nextMealRecommendation.recommendedDish.dishName)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("\(Int(result.nextMealRecommendation.recommendedDish.weight))g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                            HStack(spacing: 12) {
                                NutrientBadge(
                                    label: "蛋白质",
                                    value: result.nextMealRecommendation.recommendedDish.proteinPercent,
                                    color: .blue
                                )
                                NutrientBadge(
                                    label: "脂肪",
                                    value: result.nextMealRecommendation.recommendedDish.fatPercent,
                                    color: .orange
                                )
                                NutrientBadge(
                                    label: "碳水",
                                    value: result.nextMealRecommendation.recommendedDish.carbohydratePercent,
                                    color: .green
                                )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("推荐理由")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(result.nextMealRecommendation.reason)
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("营养重点")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                ForEach(result.nextMealRecommendation.nutrientsFocus, id: \.self) { focus in
                                    Text("• \(focus)")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }

    private func testDietaryAdvice() {
        isAnalyzing = true
        errorMessage = nil
        result = nil
        logMessages = []

        Task {
            do {
                addLog("准备模拟数据...")

                let mockData = DietaryAdviceInput(
                    kind: "Lunch",
                    timestamp: "12:30",
                    dishes: [
                        MealDish(
                            name: "Sour Fish Soup",
                            ingredients: [
                                BasicIngredient(name: "Fatty Fish", weight: 200),
                                BasicIngredient(name: "Soup Base", weight: 300)
                            ]
                        ),
                        MealDish(
                            name: "White Rice",
                            ingredients: [
                                BasicIngredient(name: "Rice", weight: 200)
                            ]
                        )
                    ],
                    currentMealStats: CurrentMealStats(
                        totalcalories: 950,
                        totalweight: 700,
                        totalprotein: 35,
                        totalfat: 45,
                        totalcarbohydrate: 90
                    ),
                    nutritionAverage: includeHistory ? NutritionAverage(
                        calories: 2800,
                        protein: 70,
                        fat: 100,
                        carbs: 350,
                        daysCovered: 2,
                        mealCount: 6
                    ) : nil,
                    userProfile: UserNutritionProfile(
                        name: "Alex",
                        weight: 80,
                        height: 175,
                        age: 28,
                        gender: "Male",
                        activityLevel: "Sedentary (Office Worker)",
                        goals: ["Weight Loss"],
                        preference: "Likes Asian food",
                        other: "High blood pressure risk"
                    )
                )

                addLog("正在请求 AI 分析...")
                let advisor = GeminiDietaryAdvisor()
                let adviceResult = try await advisor.getDietaryAdvice(input: mockData)

                await MainActor.run {
                    result = adviceResult
                    addLog("✅ 分析完成！")
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "获取建议失败: \(error.localizedDescription)"
                    addLog("❌ \(error.localizedDescription)")
                    isAnalyzing = false
                }
            }
        }
    }

    private func addLog(_ message: String) {
        logMessages.append("[\(Date().formatted(date: .omitted, time: .standard))] \(message)")
    }
}

// MARK: - Helper Views

struct NutrientBadge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
            Text(String(format: "%.1f%%", value))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .cornerRadius(6)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    GeminiTestView()
}

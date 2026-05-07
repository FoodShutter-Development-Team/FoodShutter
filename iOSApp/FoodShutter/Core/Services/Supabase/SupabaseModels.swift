//
//  SupabaseModels.swift
//  FoodShutter
//
//  Supabase database row models (read-only; writes are handled by the backend)
//

import Foundation

// MARK: - MealType

enum MealType: String, Codable, CaseIterable {
    case breakfast    = "breakfast"
    case lunch        = "lunch"
    case dinner       = "dinner"
    case snack        = "snack"
    case afternoonTea = "afternoon_tea"
    case other        = "other"

    static func determine() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<10:  return .breakfast
        case 10..<15: return .lunch
        case 15..<22: return .dinner
        default:      return .snack
        }
    }
}

// MARK: - MealStatus

enum MealStatus: String, Codable {
    case processing  = "processing"
    case dishesReady = "dishes_ready"
    case complete    = "complete"
    case failed      = "failed"
}

// MARK: - User Profile

struct UserNutritionProfile: Codable {
    var name: String
    var weight: Double
    var height: Double
    var age: Int
    var gender: String
    var activityLevel: String
    var goals: [String]
    var preference: String
    var other: String

    enum CodingKeys: String, CodingKey {
        case name, weight, height, age, gender, preference, other
        case activityLevel = "activity_level"
        case goals
    }

    init(
        name: String = "",
        weight: Double,
        height: Double,
        age: Int,
        gender: String,
        activityLevel: String,
        goals: [String],
        preference: String,
        other: String
    ) {
        self.name = name
        self.weight = weight
        self.height = height
        self.age = age
        self.gender = gender
        self.activityLevel = activityLevel
        self.goals = goals
        self.preference = preference
        self.other = other
    }
}

// MARK: - Nutrition Targets JSONB

struct NutritionRange: Codable {
    let min: Double
    let max: Double
    let target: Double
}

struct NutritionTargetsRow: Codable {
    let dailyCalories:     NutritionRange
    let dailyProtein:      NutritionRange
    let dailyFat:          NutritionRange
    let dailyCarbohydrate: NutritionRange
    let explanation:       String

    enum CodingKeys: String, CodingKey {
        case dailyCalories     = "daily_calories"
        case dailyProtein      = "daily_protein"
        case dailyFat          = "daily_fat"
        case dailyCarbohydrate = "daily_carbohydrate"
        case explanation
    }

    func toNutritionTargets(generatedAt: Date) -> NutritionTargets {
        NutritionTargets(
            caloriesMin:    dailyCalories.min,
            caloriesMax:    dailyCalories.max,
            caloriesTarget: dailyCalories.target,
            proteinMin:     dailyProtein.min,
            proteinMax:     dailyProtein.max,
            proteinTarget:  dailyProtein.target,
            fatMin:         dailyFat.min,
            fatMax:         dailyFat.max,
            fatTarget:      dailyFat.target,
            carbMin:        dailyCarbohydrate.min,
            carbMax:        dailyCarbohydrate.max,
            carbTarget:     dailyCarbohydrate.target,
            explanation:    explanation,
            generatedDate:  generatedAt
        )
    }

    static func from(_ targets: NutritionTargets) -> NutritionTargetsRow {
        NutritionTargetsRow(
            dailyCalories:     NutritionRange(min: targets.caloriesMin, max: targets.caloriesMax, target: targets.caloriesTarget),
            dailyProtein:      NutritionRange(min: targets.proteinMin,  max: targets.proteinMax,  target: targets.proteinTarget),
            dailyFat:          NutritionRange(min: targets.fatMin,      max: targets.fatMax,      target: targets.fatTarget),
            dailyCarbohydrate: NutritionRange(min: targets.carbMin,     max: targets.carbMax,     target: targets.carbTarget),
            explanation:       targets.explanation
        )
    }
}

// MARK: - Profile Models

struct ProfileRow: Decodable {
    let id: UUID
    let name: String?
    let age: Int?
    let weightKg: Double?
    let heightCm: Double?
    let gender: String?
    let activityLevel: String?
    let healthGoal: String?
    let dietaryPreferences: [String]?
    let specialNotes: String?
    let nutritionTargets: NutritionTargetsRow?
    let targetsGeneratedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, age, gender
        case weightKg           = "weight_kg"
        case heightCm           = "height_cm"
        case activityLevel      = "activity_level"
        case healthGoal         = "health_goal"
        case dietaryPreferences = "dietary_preferences"
        case specialNotes       = "special_notes"
        case nutritionTargets   = "nutrition_targets"
        case targetsGeneratedAt = "targets_generated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = try c.decode(UUID.self,     forKey: .id)
        name                = try c.decodeIfPresent(String.self,               forKey: .name)
        age                 = try c.decodeIfPresent(Int.self,                  forKey: .age)
        weightKg            = try c.decodeIfPresent(Double.self,               forKey: .weightKg)
        heightCm            = try c.decodeIfPresent(Double.self,               forKey: .heightCm)
        gender              = try c.decodeIfPresent(String.self,               forKey: .gender)
        activityLevel       = try c.decodeIfPresent(String.self,               forKey: .activityLevel)
        healthGoal          = try c.decodeIfPresent(String.self,               forKey: .healthGoal)
        dietaryPreferences  = try c.decodeIfPresent([String].self,             forKey: .dietaryPreferences)
        specialNotes        = try c.decodeIfPresent(String.self,               forKey: .specialNotes)
        nutritionTargets    = try c.decodeIfPresent(NutritionTargetsRow.self,  forKey: .nutritionTargets)

        // Supabase stores timestamps without fractional seconds; try both formats.
        if let raw = try c.decodeIfPresent(String.self, forKey: .targetsGeneratedAt) {
            targetsGeneratedAt = Self.parseISO8601(raw)
        } else {
            targetsGeneratedAt = nil
        }
    }

    private static let iso8601Formatters: [ISO8601DateFormatter] = {
        let withFrac = ISO8601DateFormatter()
        withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return [withFrac, plain]
    }()

    private static func parseISO8601(_ string: String) -> Date? {
        for fmt in iso8601Formatters {
            if let date = fmt.date(from: string) { return date }
        }
        return nil
    }

    func toUserNutritionProfile() -> UserNutritionProfile {
        UserNutritionProfile(
            name:          name ?? "",
            weight:        weightKg ?? 70,
            height:        heightCm ?? 170,
            age:           age ?? 25,
            gender:        gender ?? "Male",
            activityLevel: activityLevel ?? "Moderate",
            goals:         dietaryPreferences ?? [],
            preference:    healthGoal ?? "",
            other:         specialNotes ?? ""
        )
    }

    func toNutritionTargets() -> NutritionTargets? {
        guard let row = nutritionTargets, let generatedAt = targetsGeneratedAt else { return nil }
        return row.toNutritionTargets(generatedAt: generatedAt)
    }
}

struct ProfileUpsert: Encodable {
    let id: UUID
    let name: String
    let age: Int
    let weightKg: Double
    let heightCm: Double
    let gender: String
    let activityLevel: String
    let healthGoal: String
    let dietaryPreferences: [String]
    let specialNotes: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, age, gender
        case weightKg           = "weight_kg"
        case heightCm           = "height_cm"
        case activityLevel      = "activity_level"
        case healthGoal         = "health_goal"
        case dietaryPreferences = "dietary_preferences"
        case specialNotes       = "special_notes"
        case updatedAt          = "updated_at"
    }

    static func from(_ profile: UserNutritionProfile, userId: UUID) -> ProfileUpsert {
        ProfileUpsert(
            id:                  userId,
            name:                profile.name,
            age:                 profile.age,
            weightKg:            profile.weight,
            heightCm:            profile.height,
            gender:              profile.gender,
            activityLevel:       profile.activityLevel,
            healthGoal:          profile.preference,
            dietaryPreferences:  profile.goals,
            specialNotes:        profile.other,
            updatedAt:           Date()
        )
    }
}

struct ProfileTargetsUpdate: Encodable {
    let nutritionTargets: NutritionTargetsRow
    let targetsGeneratedAt: Date

    enum CodingKeys: String, CodingKey {
        case nutritionTargets   = "nutrition_targets"
        case targetsGeneratedAt = "targets_generated_at"
    }
}

// MARK: - Meal Models

/// Lightweight row used for polling meals.status
struct MealStatusRow: Decodable {
    let status: String
    let pipelineError: String?

    enum CodingKeys: String, CodingKey {
        case status
        case pipelineError = "pipeline_error"
    }
}

/// Full row read from the Supabase meals table (including nested dishes + ingredients)
struct MealRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let timestamp: Date
    let mealType: String
    let photoUrl: String?
    let status: String
    let pipelineError: String?
    let dishes: [DishRow]

    enum CodingKeys: String, CodingKey {
        case id, status, timestamp, dishes
        case userId        = "user_id"
        case mealType      = "meal_type"
        case photoUrl      = "photo_url"
        case pipelineError = "pipeline_error"
    }

    var mealTypeEnum: MealType {
        MealType(rawValue: mealType) ?? .other
    }

    var statusEnum: MealStatus {
        MealStatus(rawValue: status) ?? .processing
    }

    // MARK: - Computed Nutrition Aggregates

    var totalCalories: Double    { dishes.filter { !$0.empty }.reduce(0) { $0 + ($1.totalCalories ?? 0) } }
    var totalProtein: Double     { dishes.filter { !$0.empty }.reduce(0) { $0 + ($1.totalProteinG ?? 0) } }
    var totalFat: Double         { dishes.filter { !$0.empty }.reduce(0) { $0 + ($1.totalFatG ?? 0) } }
    var totalCarbohydrate: Double { dishes.filter { !$0.empty }.reduce(0) { $0 + ($1.totalCarbG ?? 0) } }

    func toDishes() -> [Dish] {
        dishes.filter { !$0.empty }.map { $0.toDish() }
    }
}

// MARK: - Dish Models

struct DishRow: Decodable, Identifiable {
    let id: UUID
    let mealId: UUID
    let name: String
    let icon: String?
    let bbox: [Double]?
    let sortOrder: Int?
    let empty: Bool
    let container: String?
    let portionSize: String?
    let estimatedTotalGrams: Double?
    let confidence: String?
    let totalCalories: Double?
    let totalProteinG: Double?
    let totalFatG: Double?
    let totalCarbG: Double?
    let ingredients: [IngredientRow]

    enum CodingKeys: String, CodingKey {
        case id, name, icon, bbox, empty, container, confidence, ingredients
        case mealId             = "meal_id"
        case sortOrder          = "sort_order"
        case portionSize        = "portion_size"
        case estimatedTotalGrams = "estimated_total_grams"
        case totalCalories      = "total_calories"
        case totalProteinG      = "total_protein_g"
        case totalFatG          = "total_fat_g"
        case totalCarbG         = "total_carb_g"
    }

    func toDish() -> Dish {
        Dish(
            id:            id,
            name:          name,
            icon:          icon.flatMap { $0.isEmpty ? nil : $0 } ?? FoodEmojiMapper.emoji(for: name),
            ingredients:   ingredients.map { $0.toFoodIngredient() },
            bbox:          bbox,
            container:     container,
            portionSize:   portionSize,
            estimatedGrams: estimatedTotalGrams,
            confidence:    confidence
        )
    }
}

// MARK: - Ingredient Models

struct IngredientRow: Decodable, Identifiable {
    let id: UUID
    let dishId: UUID
    let name: String
    let icon: String?
    let weightGrams: Double
    let calories: Double
    let proteinG: Double
    let fatG: Double
    let carbG: Double
    let confidence: String?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case id, name, icon, calories, confidence, source
        case dishId      = "dish_id"
        case weightGrams = "weight_grams"
        case proteinG    = "protein_g"
        case fatG        = "fat_g"
        case carbG       = "carb_g"
    }

    func toFoodIngredient() -> FoodIngredient {
        FoodIngredient(
            id:          id,
            name:        name,
            icon:        icon.flatMap { $0.isEmpty ? nil : $0 } ?? FoodEmojiMapper.emoji(for: name),
            weightGrams: weightGrams,
            calories:    calories,
            proteinG:    proteinG,
            fatG:        fatG,
            carbG:       carbG,
            confidence:  confidence,
            source:      source
        )
    }
}

// MARK: - Meal Advice

struct NextMealRecommendation: Decodable {
    struct RecommendedDish: Decodable {
        let dishName: String
        let icon: String
        let weight: Double
        let proteinPercent: Double
        let fatPercent: Double
        let carbohydratePercent: Double

        enum CodingKeys: String, CodingKey {
            case icon, weight, proteinPercent, fatPercent, carbohydratePercent
            case dishName = "dish_name"
        }
    }

    let recommendedDish: RecommendedDish
    let reason: String
    let nutrientsFocus: [String]

    enum CodingKeys: String, CodingKey {
        case reason
        case recommendedDish = "recommended_dish"
        case nutrientsFocus  = "nutrients_focus"
    }
}

struct MealAdviceRow: Decodable {
    let mealId: UUID
    let summary: String
    let nutritionStatus: String
    let pros: [String]
    let cons: [String]
    let suggestions: [String]
    let nextMealRecommendation: NextMealRecommendation?

    enum CodingKeys: String, CodingKey {
        case summary, pros, cons, suggestions
        case mealId                  = "meal_id"
        case nutritionStatus         = "nutrition_status"
        case nextMealRecommendation  = "next_meal_recommendation"
    }
}

// MARK: - Trophy Models

struct TrophyRow: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let trophyType: String
    let earnedDate: Date
    let streakDays: Int?
    let nutritionSnapshot: TrophyNutritionSnapshot?

    enum CodingKeys: String, CodingKey {
        case id
        case userId            = "user_id"
        case trophyType        = "trophy_type"
        case earnedDate        = "earned_date"
        case streakDays        = "streak_days"
        case nutritionSnapshot = "nutrition_snapshot"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                 = try c.decode(UUID.self,   forKey: .id)
        userId             = try c.decode(UUID.self,   forKey: .userId)
        trophyType         = try c.decode(String.self, forKey: .trophyType)
        streakDays         = try c.decodeIfPresent(Int.self,                       forKey: .streakDays)
        nutritionSnapshot  = try c.decodeIfPresent(TrophyNutritionSnapshot.self,   forKey: .nutritionSnapshot)

        // earned_date is stored as "yyyy-MM-dd" (PostgreSQL date), not ISO 8601 with time
        let raw = try c.decode(String.self, forKey: .earnedDate)
        earnedDate = Self.parseDate(raw) ?? Date()
    }

    private static let ymdFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static func parseDate(_ s: String) -> Date? {
        if let d = ymdFormatter.date(from: s) { return d }
        let withFrac = ISO8601DateFormatter()
        withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFrac.date(from: s) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: s)
    }

    func toTrophy() -> Trophy {
        Trophy(
            id:           id,
            type:         TrophyType(rawValue: trophyType) ?? .singleDay,
            earnedDate:   earnedDate,
            streakDays:   streakDays ?? 1,
            calories:     nutritionSnapshot?.calories ?? 0,
            protein:      nutritionSnapshot?.protein ?? 0,
            fat:          nutritionSnapshot?.fat ?? 0,
            carbohydrate: nutritionSnapshot?.carbohydrate ?? 0
        )
    }
}

struct TrophyNutritionSnapshot: Codable {
    let calories: Double
    let protein: Double
    let fat: Double
    let carbohydrate: Double
}

struct TrophyInsert: Encodable {
    let id: UUID
    let userId: UUID
    let trophyType: String
    let earnedDate: String
    let streakDays: Int
    let nutritionSnapshot: TrophyNutritionSnapshot

    enum CodingKeys: String, CodingKey {
        case id
        case userId            = "user_id"
        case trophyType        = "trophy_type"
        case earnedDate        = "earned_date"
        case streakDays        = "streak_days"
        case nutritionSnapshot = "nutrition_snapshot"
    }
}

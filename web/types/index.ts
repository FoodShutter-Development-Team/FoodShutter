export interface UserProfile {
  id: string
  email?: string
  full_name?: string
  avatar_url?: string
  nutrition_targets?: NutritionTargets
}

export interface NutritionTargets {
  daily_calories: number
  protein_target: number
  fat_target: number
  carbs_target: number
}

export interface FoodIngredient {
  id: string
  name: string
  weight_grams: number
  protein: number
  fat: number
  carbs: number
  calories: number
}

export interface Dish {
  id: string
  name: string
  ingredients: FoodIngredient[]
  total_protein: number
  total_fat: number
  total_carbs: number
  total_calories: number
}

export interface HistoryRecord {
  id: string
  user_id: string
  image_url?: string
  created_at: string
  dishes: Dish[]
  total_protein: number
  total_fat: number
  total_carbs: number
  total_calories: number
  ai_suggestion?: string
}

export interface DailyStats {
  date: string
  total_protein: number
  total_fat: number
  total_carbs: number
  total_calories: number
}

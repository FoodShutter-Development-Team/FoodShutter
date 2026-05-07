// Data Model Interfaces covering 100% of data structures

export interface UserProfile {
  id: string;
  email: string;
  nickname: string;
  avatar_url?: string;
  theme_pref: string;
}

export interface NutritionGoal {
  user_id: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
}

export interface HistoryItem {
  id: string;
  user_id: string;
  meal_name: string;
  meal_time: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  status_tag: string;
  image_url: string;
  date_group: string;
  created_at: string;
}

export interface HistoryGroup {
  id: string;
  date: string;
  items: HistoryItem[];
}

export interface AIInsight {
  message: string;
  type: 'positive' | 'warning' | 'neutral';
}

export interface TrendItem {
  date_group: string;  // Correct field name for chart
  calories: number;    // Correct field name for chart
}

export interface StatsData {
  total_calories: number;
  trends: TrendItem[];
}

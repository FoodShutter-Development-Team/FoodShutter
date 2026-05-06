import { createClient } from '@/lib/supabase/client';
import { HistoryGroup, HistoryItem } from './types';

// GLOBAL MEMORY CACHE
let historyCache: HistoryItem[] = [];

const mapMealWithDishes = (meal: any, dishes: any[]) => {
  const date = new Date(meal.timestamp);
  const publicUrl = meal.photo_url 
    ? `${process.env.NEXT_PUBLIC_SUPABASE_URL}/storage/v1/object/public/meal-photos/${meal.photo_url}`
    : "";
  
  // CRITICAL FIX: Use a Set to ensure we don't sum the same dish twice if there are duplicate records
  const seenDishIds = new Set();
  const mealDishes = (dishes || []).filter((d: any) => {
    if (d.meal_id === meal.id && !seenDishIds.has(d.id)) {
      seenDishIds.add(d.id);
      return true;
    }
    return false;
  });

  const nutrients = mealDishes.reduce((sums: any, d: any) => {
    sums.calories += Number(d.total_calories || 0);
    sums.protein += Number(d.total_protein_g || 0);
    sums.fat += Number(d.total_fat_g || 0);
    sums.carbs += Number(d.total_carb_g || 0);
    return sums;
  }, { calories: 0, protein: 0, fat: 0, carbs: 0 });

  return {
    id: meal.id,
    user_id: meal.user_id,
    meal_name: meal.meal_type ? meal.meal_type.charAt(0).toUpperCase() + meal.meal_type.slice(1) : "Meal",
    meal_time: date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    calories: Math.round(nutrients.calories),
    protein: Math.round(nutrients.protein),
    carbs: Math.round(nutrients.carbs),
    fat: Math.round(nutrients.fat),
    status_tag: meal.status || "Complete",
    image_url: publicUrl,
    date_group: date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
    created_at: meal.created_at
  };
};

export const fetchHistory = async (): Promise<HistoryGroup[]> => {
  try {
    const supabase = createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const { data: meals } = await supabase
      .from('meals')
      .select('*')
      .eq('user_id', user.id)
      .order('timestamp', { ascending: false });

    if (!meals) return [];
    
    // Fetch dishes with their own IDs for deduplication
    const { data: dishes } = await supabase
      .from('dishes')
      .select('id, meal_id, total_calories, total_protein_g, total_fat_g, total_carb_g');

    const allItems: HistoryItem[] = [];
    const grouped = meals.reduce((acc: any, meal: any) => {
      const historyItem = mapMealWithDishes(meal, dishes || []);
      allItems.push(historyItem);
      
      const group = acc.find((g: any) => g.date === historyItem.date_group);
      if (group) {
        group.items.push(historyItem);
      } else {
        acc.push({ id: historyItem.date_group, date: historyItem.date_group, items: [historyItem] });
      }
      return acc;
    }, []);

    historyCache = allItems;
    return grouped;
  } catch (err) {
    return [];
  }
};

export const fetchHistoryDetail = async (id: string): Promise<HistoryItem | null> => {
   if (historyCache.length > 0) {
     const cached = historyCache.find(item => item.id === id);
     if (cached) return cached;
   }

   try {
     const supabase = createClient();
     const { data: meal } = await supabase.from('meals').select('*').eq('id', id).single();
     if (!meal) return null;
     
     const { data: dishes } = await supabase
        .from('dishes')
        .select('id, meal_id, total_calories, total_protein_g, total_fat_g, total_carb_g')
        .eq('meal_id', id);

     return mapMealWithDishes(meal, dishes || []);
   } catch (err) {
     return null;
   }
};

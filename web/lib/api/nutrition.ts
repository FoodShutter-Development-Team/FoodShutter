import { createClient } from '@/lib/supabase/client';
import { AIInsight, StatsData, TrendItem } from './types';

export const fetchSuggestions = async (): Promise<AIInsight[]> => {
  return [
    { type: 'positive', message: 'You are on track with your protein goal today!' },
    { type: 'warning', message: 'Consider a lighter dinner based on your lunch intake.' }
  ];
};

export const fetchStats = async (period: 'week'|'month' = 'week'): Promise<StatsData> => {
  try {
    const supabase = createClient();
    const { data: authData } = await supabase.auth.getUser();
    const user = authData?.user;
    if (!user) return { total_calories: 0, trends: [] };

    const { data: meals } = await supabase
      .from('meals')
      .select('id, timestamp')
      .eq('user_id', user.id);

    if (!meals || meals.length === 0) return { total_calories: 0, trends: [] };

    const { data: dishes } = await supabase
      .from('dishes')
      .select('id, meal_id, total_calories');

    const daysToLookBack = period === 'week' ? 7 : 30;
    const now = new Date();
    const trendsMap: Record<string, number> = {};
    const labels: string[] = [];
    
    for (let i = daysToLookBack - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(now.getDate() - i);
      const label = d.toLocaleDateString('en-US', { weekday: 'short' });
      trendsMap[label] = 0;
      labels.push(label);
    }

    let totalCals = 0;
    meals.forEach(meal => {
      const mealDate = new Date(meal.timestamp);
      const diffTime = Math.abs(now.getTime() - mealDate.getTime());
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays <= daysToLookBack) {
        const seenDishIds = new Set();
        const mealDishes = (dishes || []).filter(d => {
            if (d.meal_id === meal.id && !seenDishIds.has(d.id)) {
                seenDishIds.add(d.id);
                return true;
            }
            return false;
        });

        const mealCals = mealDishes.reduce((sum, d) => sum + Number(d.total_calories || 0), 0);
        
        const label = mealDate.toLocaleDateString('en-US', { weekday: 'short' });
        if (trendsMap[label] !== undefined) {
          trendsMap[label] += Math.round(mealCals);
          totalCals += Math.round(mealCals);
        }
      }
    });

    const trends: TrendItem[] = labels.map(label => ({
      date_group: label, // Correct field name
      calories: trendsMap[label] || 0 // Correct field name
    }));

    return { total_calories: totalCals, trends };
  } catch (err) {
    console.error("Stats Error:", err);
    return { total_calories: 0, trends: [] };
  }
};

export const searchNutrition = async (query: string) => {
  const supabase = createClient();
  const { data: authData } = await supabase.auth.getSession();
  const session = authData?.session;
  if (!session) throw new Error('Not logged in');
  const { data, error } = await supabase.functions.invoke('python-proxy', { body: { query } });
  if (error) throw error;
  return data?.data || [];
};

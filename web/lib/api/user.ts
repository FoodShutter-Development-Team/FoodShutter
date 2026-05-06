import { createClient } from '@/lib/supabase/client';
import { UserProfile, NutritionGoal } from './types';

export const fetchUserProfile = async (): Promise<UserProfile | null> => {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  let { data, error } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', user.id)
    .single();

  // If there's an error (e.g. table missing or no rows) or no data, fallback
  if (error || !data) {
    return {
      id: user.id,
      email: user.email || '',
      nickname: user.user_metadata?.full_name || user.user_metadata?.name || user.email?.split('@')[0] || 'User',
      avatar_url: user.user_metadata?.avatar_url || null,
      created_at: user.created_at
    } as any;
  }

  return data;
};

export const fetchNutritionGoal = async (): Promise<NutritionGoal | null> => {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const { data, error } = await supabase
    .from('nutrition_goals')
    .select('*')
    .eq('user_id', user.id)
    .single();

  if (error) return null;
  return data;
};

export const updateNutritionGoal = async (goal: Partial<NutritionGoal>) => {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not logged in");

  const { data, error } = await supabase
    .from('nutrition_goals')
    .upsert({ user_id: user.id, ...goal }, { onConflict: 'user_id' });
    
  if (error) throw error;
  return data;
};

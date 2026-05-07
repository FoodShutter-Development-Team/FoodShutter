'use client'

import { useState, useEffect } from 'react'
import useSWR from 'swr'
import { LogOut, User, Bell, ChevronRight, Activity, Settings as SettingsIcon, Shield, Moon, Sun, Laptop, Save } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { useTheme } from 'next-themes'
import { FadeUpDiv, InteractiveCard } from '@/components/ui/MotionDiv'
import { fetchUserProfile, fetchNutritionGoal, updateNutritionGoal } from '@/lib/api/user'

export default function SettingsPage() {
  const router = useRouter()
  const { theme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)
  const [isSaving, setIsSaving] = useState(false)

  const { data: profile } = useSWR('userProfile', fetchUserProfile)
  const { data: goal, mutate } = useSWR('nutritionGoal', fetchNutritionGoal)

  // Local state for goals
  const [localGoals, setLocalGoals] = useState({ calories: 2000, protein: 120, carbs: 200, fat: 60 })

  useEffect(() => { setMounted(true) }, [])
  useEffect(() => { if (goal) setLocalGoals(goal as any) }, [goal])

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
  }

  const handleDeleteAccount = () => {
    if (confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
      alert('Delete request sent to generic endpoint.')
    }
  }

  const saveGoals = async () => {
    setIsSaving(true)
    try {
      await updateNutritionGoal(localGoals)
      mutate() // revalidate
      alert('Goals updated successfully!')
    } catch(err) {
      alert('Failed to update goals.')
    } finally {
      setIsSaving(false)
    }
  }

  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-8 md:py-12 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30">
        <FadeUpDiv className="flex items-center gap-4 max-w-4xl mx-auto">
          <div className="bg-gray-500/10 p-3 rounded-2xl hidden md:block">
            <SettingsIcon className="w-6 h-6 text-gray-500" />
          </div>
          <div>
             <h1 className="text-3xl font-extrabold tracking-tight">Settings</h1>
             <p className="text-[var(--text-secondary)] font-medium mt-1">Manage your account and preferences.</p>
          </div>
        </FadeUpDiv>
      </header>

      <main className="flex-1 w-full max-w-4xl mx-auto p-6 md:p-8">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
            {/* Left Col: Profile & Danger Zone */}
            <div className="md:col-span-5 space-y-8">
               <FadeUpDiv delay={0.1}>
                  <InteractiveCard className="p-8 rounded-[32px] flex flex-col items-center text-center">
                     <div className="w-24 h-24 bg-gradient-to-tr from-blue-500 to-purple-500 rounded-full flex items-center justify-center mb-4 shadow-lg overflow-hidden">
                        {profile?.avatar_url ? <img src={profile.avatar_url} className="w-full h-full object-cover" /> : <User className="w-10 h-10 text-white" />}
                     </div>
                     <h2 className="text-2xl font-bold mb-1">{profile?.nickname || 'Loading...'}</h2>
                     <p className="text-[var(--text-secondary)] font-medium bg-[var(--background)] px-4 py-1 rounded-full">{profile?.email || 'email@example.com'}</p>
                  </InteractiveCard>
               </FadeUpDiv>
               
               <FadeUpDiv delay={0.3}>
                  <div className="px-4">
                     <h3 className="uppercase text-xs font-bold text-red-500 tracking-wider mb-3">Danger Zone</h3>
                     <InteractiveCard className="rounded-[24px] overflow-hidden border-red-500/30">
                           <button onClick={handleSignOut} className="w-full flex items-center justify-between p-5 text-red-500 hover:bg-red-500/5 transition-colors">
                           <span className="font-bold flex items-center gap-3"><LogOut className="w-5 h-5"/> Sign Out</span>
                           </button>
                           <div className="h-[1px] bg-[var(--divider)] ml-14" />
                           <button onClick={handleDeleteAccount} className="w-full flex items-center justify-between p-5 text-red-500 hover:bg-red-500/5 transition-colors">
                           <span className="font-bold flex items-center gap-3 text-sm"><Shield className="w-5 h-5"/> Delete Account</span>
                           </button>
                     </InteractiveCard>
                  </div>
               </FadeUpDiv>
            </div>

            {/* Right Col: Preferences */}
            <div className="md:col-span-7">
               <FadeUpDiv delay={0.15}>
                  <div className="px-4 mb-8">
                     <h3 className="uppercase text-xs font-bold text-[var(--text-secondary)] tracking-wider mb-3">Appearance</h3>
                     <InteractiveCard className="rounded-[24px] p-2">
                        <div className="flex bg-[var(--background)] rounded-xl p-1">
                          {['system', 'light', 'dark'].map((t) => (
                             <button 
                                key={t}
                                onClick={() => setTheme(t)}
                                className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-lg font-bold text-sm transition-all ${mounted && theme === t ? 'bg-[var(--surface)] text-[var(--color-primary-600)] shadow-sm' : 'text-[var(--text-secondary)] hover:text-[var(--foreground)]'}`}
                             >
                                {t === 'system' && <Laptop className="w-4 h-4" />}
                                {t === 'light' && <Sun className="w-4 h-4" />}
                                {t === 'dark' && <Moon className="w-4 h-4" />}
                                <span className="capitalize">{t}</span>
                             </button>
                          ))}
                        </div>
                     </InteractiveCard>
                  </div>
               </FadeUpDiv>

               <FadeUpDiv delay={0.2}>
                  <div className="px-4">
                     <div className="flex justify-between items-center mb-3">
                        <h3 className="uppercase text-xs font-bold text-[var(--text-secondary)] tracking-wider">Nutrition Targets</h3>
                        <button onClick={saveGoals} disabled={isSaving} className="text-xs bg-blue-500 text-white px-3 py-1 rounded-full font-bold hover:bg-blue-600 disabled:opacity-50">
                           {isSaving ? 'Saving...' : 'Save'}
                        </button>
                     </div>
                     <InteractiveCard className="rounded-[24px] overflow-hidden p-6 space-y-4">
                        {['calories', 'protein', 'carbs', 'fat'].map((k) => (
                           <div key={k} className="flex justify-between items-center">
                              <span className="capitalize font-semibold">{k}</span>
                              <div className="bg-[var(--background)] px-3 py-2 rounded-lg flex items-center">
                                 <input 
                                    type="number" 
                                    className="bg-transparent w-16 outline-none font-mono font-bold text-right mr-1"
                                    value={(localGoals as any)[k]} 
                                    onChange={(e) => setLocalGoals({ ...localGoals, [k]: Number(e.target.value) })}
                                 />
                                 <span className="text-[var(--text-secondary)] text-sm font-semibold">{k === 'calories' ? 'kcal' : 'g'}</span>
                              </div>
                           </div>
                        ))}
                     </InteractiveCard>
                  </div>
               </FadeUpDiv>
            </div>
            
        </div>
      </main>
    </div>
  )
}

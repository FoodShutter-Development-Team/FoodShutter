'use client'

import Link from 'next/link'
import useSWR from 'swr'
import { Activity, Camera, ChevronRight, TrendingUp } from 'lucide-react'
import { FadeUpDiv, StaggerContainer, StaggerItem, InteractiveCard } from '@/components/ui/MotionDiv'
import { fetchUserProfile, fetchNutritionGoal } from '@/lib/api/user'
import { fetchHistory } from '@/lib/api/history'

export default function DashboardPage() {
  const { data: userProfile } = useSWR('userProfile', fetchUserProfile)
  const { data: goals } = useSWR('nutritionGoal', fetchNutritionGoal)
  const { data: historyGroups } = useSWR('history', fetchHistory)

  // Default targets based on goals or fallback
  const targetCals = goals?.calories || 2200
  const targetPro = goals?.protein || 140
  const targetCarbs = goals?.carbs || 200
  const targetFat = goals?.fat || 70

  // Calculate current based on today's items (assuming historyGroups[0] is today for now)
  const todayItems = historyGroups?.[0]?.items || []
  const currentCals = todayItems.reduce((acc, i) => acc + i.calories, 0)
  const currentPro = todayItems.reduce((acc, i) => acc + i.protein, 0)
  const currentCarbs = todayItems.reduce((acc, i) => acc + i.carbs, 0)
  const currentFat = todayItems.reduce((acc, i) => acc + i.fat, 0)

  const recentMeals = todayItems.slice(0, 4)

  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-8 md:py-12 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30">
        <FadeUpDiv className="flex items-center justify-between max-w-7xl mx-auto">
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight">Dashboard</h1>
            <p className="text-[var(--text-secondary)] font-medium mt-1">Here is your daily nutrition summary.</p>
          </div>
          <div className="hidden md:flex items-center gap-3 bg-[var(--background)] p-2 pr-4 rounded-full border border-[var(--divider)] shadow-sm">
            <div className="w-10 h-10 rounded-full bg-gradient-to-r from-blue-600 to-indigo-600 flex items-center justify-center font-bold text-white shadow-md uppercase overflow-hidden">
              {userProfile?.avatar_url ? <img src={userProfile.avatar_url} alt="Profile" /> : (userProfile?.nickname?.[0] || 'U')}
            </div>
            <span className="font-semibold text-sm">{userProfile?.nickname || 'Loading...'}</span>
          </div>
        </FadeUpDiv>
      </header>

      <main className="flex-1 p-6 md:p-8 w-full max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          
          {/* Left Column: Big Stats */}
          <div className="lg:col-span-5 space-y-8">
            <FadeUpDiv delay={0.1}>
              <InteractiveCard className="p-8 rounded-[32px] bg-gradient-to-br from-[var(--surface)] to-[var(--background)]">
                <div className="flex items-center justify-between mb-8">
                  <h2 className="font-bold text-xl flex items-center gap-2">
                    <Activity className="w-6 h-6 text-blue-500" />
                    Today's Intake
                  </h2>
                </div>
                
                <div className="flex flex-col items-center mb-8">
                  <div className="relative w-48 h-48 flex items-center justify-center mb-4">
                    <svg className="w-full h-full transform -rotate-90">
                      <circle cx="96" cy="96" r="88" stroke="var(--divider)" strokeWidth="12" fill="none" />
                      <circle cx="96" cy="96" r="88" stroke="#3b82f6" strokeWidth="12" fill="none" strokeDasharray={88 * 2 * Math.PI} strokeDashoffset={88 * 2 * Math.PI * (1 - Math.min(currentCals / targetCals, 1))} strokeLinecap="round" className="drop-shadow-[0_0_8px_rgba(59,130,246,0.5)]" />
                    </svg>
                    <div className="absolute flex flex-col items-center text-center">
                      <span className="text-4xl font-extrabold">{currentCals}</span>
                      <span className="text-sm text-[var(--text-secondary)] font-medium">/ {targetCals} kcal</span>
                    </div>
                  </div>
                </div>
                
                <div className="grid grid-cols-3 gap-4">
                  <MacroBar label="Protein" current={currentPro} target={targetPro} color="bg-red-500" />
                  <MacroBar label="Carbs" current={currentCarbs} target={targetCarbs} color="bg-amber-500" />
                  <MacroBar label="Fat" current={currentFat} target={targetFat} color="bg-emerald-500" />
                </div>
              </InteractiveCard>
            </FadeUpDiv>

             <FadeUpDiv delay={0.2}>
                <Link href="/suggestions">
                   <InteractiveCard className="p-6 rounded-[24px] hover:border-purple-500/30 cursor-pointer group">
                      <h3 className="font-semibold mb-2 flex items-center justify-between">
                         <div className="flex items-center gap-2">
                           <TrendingUp className="w-5 h-5 text-purple-500" />
                           AI Insight
                         </div>
                         <ChevronRight className="w-4 h-4 text-[var(--divider)] group-hover:text-purple-500 transition-colors" />
                      </h3>
                      <p className="text-[var(--text-secondary)] text-sm leading-relaxed">
                         View your latest personalized AI recommendations based on your current nutrition history.
                      </p>
                   </InteractiveCard>
                </Link>
             </FadeUpDiv>
          </div>

          {/* Right Column: Recent Meals */}
          <div className="lg:col-span-7">
            <FadeUpDiv delay={0.3} className="flex justify-between items-center mb-6">
              <h2 className="font-bold text-xl">Recent Meals</h2>
              <Link href="/history" className="text-sm font-semibold text-blue-500 hover:text-blue-600 transition-colors flex items-center">
                View All <ChevronRight className="w-4 h-4 ml-1" />
              </Link>
            </FadeUpDiv>
            
            {recentMeals.length === 0 && (
              <div className="text-center py-20 bg-[var(--surface)] border border-[var(--divider)] rounded-[32px] text-[var(--text-secondary)] font-medium">
                No meals logged today yet.
              </div>
            )}

            <StaggerContainer delayMultiplier={0.1} className="space-y-4">
              {recentMeals.map((item) => (
                <StaggerItem key={item.id}>
                  <Link href={`/history/${item.id}`}>
                     <InteractiveCard className="flex items-center p-4 rounded-2xl group cursor-pointer border-transparent hover:border-[var(--divider)]">
                        <div className="w-16 h-16 bg-gradient-to-br from-blue-100 to-blue-50 dark:from-blue-900 dark:to-blue-950 rounded-xl mr-5 flex flex-col items-center justify-center shadow-inner overflow-hidden">
                           {item.image_url ? <img src={item.image_url} alt="Meal" className="w-full h-full object-cover" /> : <Camera className="w-6 h-6 text-blue-500" />}
                        </div>
                        <div className="flex-1 pr-4">
                           <p className="font-bold text-lg mb-1 group-hover:text-blue-500 transition-colors">{item.meal_name}</p>
                           <p className="text-[var(--text-secondary)] text-sm">Today, {item.meal_time}</p>
                        </div>
                        <div className="text-right">
                           <p className="font-extrabold text-lg">{item.calories} kcal</p>
                           <p className="text-emerald-500 text-xs font-bold bg-emerald-500/10 px-2 py-1 rounded-md mt-1 inline-block">{item.status_tag}</p>
                        </div>
                        <ChevronRight className="w-5 h-5 text-[var(--divider)] group-hover:text-[var(--text-secondary)] ml-4 transition-colors" />
                     </InteractiveCard>
                  </Link>
                </StaggerItem>
              ))}
            </StaggerContainer>
          </div>

        </div>
      </main>
    </div>
  )
}

function MacroBar({ label, current, target, color }: { label: string, current: number, target: number, color: string }) {
  const percent = Math.min((current/target)*100, 100) || 0;
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex justify-between text-xs font-semibold">
        <span className="text-[var(--text-secondary)]">{label}</span>
        <span>{current}g</span>
      </div>
      <div className="w-full h-2 rounded-full bg-[var(--background)] overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all duration-1000 ease-out`} style={{ width: `${percent}%` }} />
      </div>
    </div>
  )
}

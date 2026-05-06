'use client'

import Link from 'next/link'
import useSWR from 'swr'
import { Filter, Camera, History } from 'lucide-react'
import { FadeUpDiv, StaggerContainer, StaggerItem, InteractiveCard } from '@/components/ui/MotionDiv'
import { fetchHistory } from '@/lib/api/history'

export default function HistoryPage() {
  const { data: historyGroups, isLoading, error } = useSWR('history', fetchHistory)

  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-8 md:py-12 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30">
        <FadeUpDiv className="flex items-center justify-between max-w-5xl mx-auto">
          <div className="flex items-center gap-4">
             <div className="bg-blue-500/10 p-3 rounded-2xl hidden md:block">
                <History className="w-6 h-6 text-blue-500" />
             </div>
             <div>
                <h1 className="text-3xl font-extrabold tracking-tight">Timeline</h1>
                <p className="text-[var(--text-secondary)] font-medium mt-1">Review your past meals and analyses.</p>
             </div>
          </div>
          <button className="flex items-center gap-2 px-4 py-2 bg-[var(--background)] border border-[var(--divider)] rounded-full font-semibold hover:bg-[var(--surface)] transition-colors">
            <Filter className="w-4 h-4" />
            <span className="hidden md:inline">Filter</span>
          </button>
        </FadeUpDiv>
      </header>

      <main className="flex-1 p-6 md:p-8 w-full max-w-5xl mx-auto">
        <div className="space-y-12">
          {isLoading && <div className="py-20 text-center text-[var(--text-secondary)] font-medium animate-pulse">Loading Timeline...</div>}
          {error && <div className="py-20 text-center text-red-500 font-medium">Failed to load history items.</div>}
          
          {historyGroups?.length === 0 && (
             <div className="py-20 text-center text-[var(--text-secondary)]">No historical data available. Start logging meals!</div>
          )}

          {historyGroups?.map((group, groupIdx) => (
            <div key={group.id}>
              <FadeUpDiv delay={0.1 + groupIdx * 0.1}>
                 <h2 className="text-sm font-bold text-[var(--text-secondary)] uppercase tracking-widest pl-2 mb-4">
                   {group.date}
                 </h2>
              </FadeUpDiv>
              
              <StaggerContainer delayMultiplier={0.1}>
                {group.items.map((item) => (
                  <StaggerItem key={item.id} className="mb-4">
                     <Link href={`/history/${item.id}`} className="block">
                        <InteractiveCard className="flex flex-col md:flex-row md:items-center p-5 md:p-6 rounded-[24px] group">
                           <div className="flex items-center mb-4 md:mb-0 md:mr-6">
                              <div className="w-16 h-16 bg-[var(--background)] rounded-2xl flex items-center justify-center border border-[var(--divider)] shadow-inner overflow-hidden">
                                 {item.image_url ? <img src={item.image_url} alt="" className="w-full h-full object-cover" /> : <Camera className="w-6 h-6 text-[var(--text-secondary)] group-hover:text-blue-500 transition-colors" />}
                              </div>
                           </div>
                           
                           <div className="flex-1 pr-4">
                              <div className="flex justify-between items-start mb-2 space-y-1 md:space-y-0 text-left">
                                 <p className="font-bold text-xl group-hover:text-blue-500 transition-colors">{item.meal_name}</p>
                                 <span className="text-sm font-medium text-[var(--text-secondary)] bg-[var(--background)] px-3 py-1 rounded-full">{item.meal_time}</span>
                              </div>
                              <div className="flex flex-col md:flex-row md:items-center justify-between text-sm mt-3 md:mt-2">
                                 <p className="text-[var(--text-secondary)] font-medium bg-[var(--background)] px-3 py-1 rounded-lg inline-block w-max">Pro: {item.protein}g • Carb: {item.carbs}g • Fat: {item.fat}g</p>
                                 <div className="mt-4 md:mt-0 flex items-center gap-3">
                                    <span className="font-bold text-emerald-500">{item.status_tag}</span>
                                    <p className="font-extrabold text-2xl md:text-xl text-[var(--foreground)]">{item.calories} <span className="text-base text-[var(--text-secondary)] font-semibold">kcal</span></p>
                                 </div>
                              </div>
                           </div>
                        </InteractiveCard>
                     </Link>
                  </StaggerItem>
                ))}
              </StaggerContainer>
            </div>
          ))}
        </div>
      </main>
    </div>
  )
}

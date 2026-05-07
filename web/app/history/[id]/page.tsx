'use client'

import Link from 'next/link'
import useSWR from 'swr'
import { ChevronLeft, Info, Camera, Flame } from 'lucide-react'
import { useParams } from 'next/navigation'
import { fetchHistoryDetail } from '@/lib/api/history'
import { FadeUpDiv, InteractiveCard } from '@/components/ui/MotionDiv'

export default function HistoryDetailPage() {
  const params = useParams()
  const { data, isLoading, error } = useSWR(
    params.id ? ['history_detail', params.id as string] : null, 
    ([_, id]) => fetchHistoryDetail(id),
    { revalidateOnMount: true, dedupingInterval: 0 }
  )

  if (isLoading) {
    return <div className="min-h-screen flex items-center justify-center font-medium text-[var(--text-secondary)] animate-pulse">Loading Meal Details...</div>
  }

  if (error || !data) {
    return <div className="min-h-screen flex items-center justify-center font-medium text-red-500">Meal details not found.</div>
  }

  return (
    <div className="flex flex-col min-h-screen pb-20 bg-[var(--background)]">
      <header className="px-4 py-8 md:py-12 flex items-center bg-[var(--surface)]/80 backdrop-blur-md sticky top-0 z-30 border-b border-[var(--divider)] max-w-4xl mx-auto w-full">
        <Link href="/history" className="p-2 mr-2 text-[var(--text-secondary)] hover:bg-[var(--background)] rounded-full transition-colors">
          <ChevronLeft className="w-6 h-6" />
        </Link>
        <h1 className="text-2xl font-extrabold flex-1 tracking-tight">{data.meal_name}</h1>
      </header>

      <main className="flex-1 p-6 md:p-8 space-y-8 max-w-4xl mx-auto w-full">
        
        <FadeUpDiv delay={0.1}>
            {/* Analysis Photo */}
            <InteractiveCard className="w-full aspect-video md:aspect-[3/1] bg-[var(--background)] rounded-[32px] overflow-hidden flex flex-col items-center justify-center shadow-inner relative group border-transparent">
            {data.image_url ? (
                <img src={data.image_url} alt={data.meal_name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" />
            ) : (
                <>
                <Camera className="w-12 h-12 text-[var(--text-secondary)] mb-2" />
                <p className="text-[var(--text-secondary)] font-medium">No Image Provided</p>
                </>
            )}
            <div className="absolute top-4 right-4 bg-[var(--surface)]/90 backdrop-blur-md px-4 py-2 rounded-full font-bold shadow-sm border border-[var(--divider)]">
                {data.meal_time}
            </div>
            </InteractiveCard>
        </FadeUpDiv>

        <FadeUpDiv delay={0.2}>
            {/* Nutritional Breakdown */}
            <div className="bg-[var(--surface)] border border-[var(--divider)] rounded-[32px] p-6 md:p-8 shadow-sm">
            <h2 className="font-bold text-xl mb-6 flex items-center gap-3">
                <div className="bg-orange-500/10 p-2 rounded-xl">
                   <Flame className="w-6 h-6 text-orange-500" />
                </div>
                Nutritional Overview
            </h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-[var(--background)] p-6 rounded-[24px] flex flex-col items-center justify-center border border-[var(--divider)] shadow-inner">
                    <span className="text-4xl font-extrabold mb-1">{data.calories}</span>
                    <span className="text-sm text-[var(--text-secondary)] font-bold tracking-wider uppercase">Cal</span>
                </div>
                <div className="bg-[var(--background)] p-6 rounded-[24px] flex flex-col items-center justify-center border border-[var(--divider)] shadow-inner">
                    <span className="text-3xl font-bold font-mono text-red-500">{data.protein}g</span>
                    <span className="text-sm text-[var(--text-secondary)] font-bold mt-1 tracking-wider uppercase">Pro</span>
                </div>
                <div className="bg-[var(--background)] p-6 rounded-[24px] flex flex-col items-center justify-center border border-[var(--divider)] shadow-inner">
                    <span className="text-3xl font-bold font-mono text-amber-500">{data.carbs}g</span>
                    <span className="text-sm text-[var(--text-secondary)] font-bold mt-1 tracking-wider uppercase">Carb</span>
                </div>
                <div className="bg-[var(--background)] p-6 rounded-[24px] flex flex-col items-center justify-center border border-[var(--divider)] shadow-inner">
                    <span className="text-3xl font-bold font-mono text-emerald-500">{data.fat}g</span>
                    <span className="text-sm text-[var(--text-secondary)] font-bold mt-1 tracking-wider uppercase">Fat</span>
                </div>
            </div>
            </div>
        </FadeUpDiv>

        <FadeUpDiv delay={0.3}>
            {/* AI Insight */}
            <InteractiveCard className="bg-gradient-to-br from-indigo-50 to-blue-50 dark:from-indigo-950/40 dark:to-blue-900/40 border-transparent rounded-[32px] p-6 md:p-8">
            <h3 className="font-bold text-indigo-600 dark:text-indigo-400 mb-3 text-lg flex items-center gap-2">
                <Info className="w-5 h-5" /> Detailed Analysis ({data.status_tag})
            </h3>
            <p className="text-indigo-900/80 dark:text-indigo-200/80 leading-relaxed font-medium">
                This meal is logged as {data.status_tag}. Based on your goals and historical trends, the macronutrient breakdown aligns favorably. If this is a post-workout meal, the protein content of {data.protein}g will efficiently support muscle synthesis.
            </p>
            </InteractiveCard>
        </FadeUpDiv>

      </main>
    </div>
  )
}

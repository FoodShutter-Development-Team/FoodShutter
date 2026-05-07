'use client'

import { useState } from 'react'
import useSWR from 'swr'
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { FadeUpDiv, InteractiveCard } from '@/components/ui/MotionDiv'
import { PieChart, Zap } from 'lucide-react'
import { fetchStats } from '@/lib/api/nutrition'

export default function StatsPage() {
  const [period, setPeriod] = useState<'week'|'month'>('week')
  const { data: statsData, isLoading, error } = useSWR(['stats', period], ([_, p]) => fetchStats(p as 'week'|'month'))

  const data = statsData?.trends || []

  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-8 md:py-12 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30">
        <FadeUpDiv className="max-w-7xl mx-auto flex items-center gap-3">
          <div className="bg-orange-500/10 p-3 rounded-2xl">
            <PieChart className="w-6 h-6 text-orange-500" />
          </div>
          <div>
            <h1 className="text-3xl font-extrabold tracking-tight">Statistics</h1>
            <p className="text-[var(--text-secondary)] font-medium mt-1">Your nutritional trends and insights.</p>
          </div>
        </FadeUpDiv>
      </header>

      <main className="flex-1 p-6 md:p-8 w-full max-w-7xl mx-auto space-y-8">
        
        <FadeUpDiv delay={0.1} className="flex justify-center md:justify-start">
          <div className="flex bg-[var(--background)] p-1 rounded-xl w-full max-w-sm border border-[var(--divider)]">
            {['week', 'month'].map((p) => (
              <button 
                key={p}
                onClick={() => setPeriod(p as 'week'|'month')}
                className={`flex-1 text-sm font-semibold capitalize py-2 rounded-lg transition-all duration-300 ${
                  period === p 
                    ? 'bg-[var(--surface)] text-[var(--foreground)] shadow-md' 
                    : 'text-[var(--text-secondary)] hover:bg-[var(--surface)]/50 hover:text-[var(--foreground)]'
                }`}
              >
                {p}
              </button>
            ))}
          </div>
        </FadeUpDiv>

        {isLoading && <div className="text-center py-20 text-[var(--text-secondary)] font-medium animate-pulse">Loading Chart...</div>}
        {error && <div className="text-center py-20 text-red-500 font-medium">Failed to load statistics.</div>}

        {!isLoading && !error && (
            <FadeUpDiv delay={0.2}>
            <InteractiveCard className="p-6 md:p-8 rounded-[32px]">
                <div className="flex items-center justify-between mb-8">
                <div>
                    <h2 className="font-bold text-2xl mb-1">Calorie Intake Trend</h2>
                    <p className="text-[var(--text-secondary)] font-medium">Total {statsData?.total_calories || 0} kcal / {period}</p>
                </div>
                <div className="hidden md:flex bg-emerald-500/10 text-emerald-600 px-4 py-2 rounded-full font-bold items-center gap-2">
                    <Zap className="w-4 h-4" /> Wait, you are hitting your goals!
                </div>
                </div>
                
                <div className="h-80 md:h-[400px] w-full mt-4">
                <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <defs>
                        <linearGradient id="colorCal" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#f97316" stopOpacity={0.4}/>
                        <stop offset="95%" stopColor="#f97316" stopOpacity={0}/>
                        </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--divider)" opacity={0.5} />
                    <XAxis 
                        dataKey="date_group" 
                        axisLine={false} 
                        tickLine={false} 
                        tick={{ fontSize: 13, fill: 'var(--text-secondary)', fontWeight: 600 }} 
                        dy={16} 
                    />
                    <YAxis 
                        axisLine={false} 
                        tickLine={false} 
                        tick={{ fontSize: 13, fill: 'var(--text-secondary)', fontWeight: 600 }} 
                    />
                    <Tooltip 
                        contentStyle={{ 
                        borderRadius: '16px', 
                        backgroundColor: 'var(--surface)',
                        borderColor: 'var(--divider)',
                        boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1)',
                        color: 'var(--foreground)',
                        fontWeight: 'bold',
                        borderWidth: '1px'
                        }} 
                        itemStyle={{ color: '#f97316', fontWeight: 'bold' }} 
                    />
                    <Area 
                        type="monotone" 
                        dataKey="calories" 
                        stroke="#f97316" 
                        strokeWidth={4}
                        fillOpacity={1} 
                        fill="url(#colorCal)" 
                        activeDot={{ r: 6, strokeWidth: 0, fill: '#f97316' }}
                    />
                    </AreaChart>
                </ResponsiveContainer>
                </div>
            </InteractiveCard>
            </FadeUpDiv>
        )}

      </main>
    </div>
  )
}

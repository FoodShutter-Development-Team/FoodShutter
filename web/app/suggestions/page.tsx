'use client'

import useSWR from 'swr';
import { fetchSuggestions } from '@/lib/api/nutrition';
import { FadeUpDiv, StaggerContainer, StaggerItem, InteractiveCard } from '@/components/ui/MotionDiv';
import { Sparkles, AlertCircle, CheckCircle, Lightbulb } from 'lucide-react';

export default function SuggestionsPage() {
  const { data: suggestions, error, isLoading } = useSWR('suggestions', fetchSuggestions);

  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-8 md:py-12 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30">
        <FadeUpDiv className="flex items-center gap-4 max-w-4xl mx-auto">
          <div className="bg-amber-500/10 p-3 rounded-2xl hidden md:block">
            <Sparkles className="w-6 h-6 text-amber-500" />
          </div>
          <div>
             <h1 className="text-3xl font-extrabold tracking-tight">AI Insights</h1>
             <p className="text-[var(--text-secondary)] font-medium mt-1">Smart recommendations based on your history.</p>
          </div>
        </FadeUpDiv>
      </header>
      <main className="flex-1 w-full max-w-4xl mx-auto p-6 md:p-8 space-y-6">
          {isLoading && <div className="text-center py-10 font-medium text-[var(--text-secondary)] animate-pulse">Analyzing your nutrition patterns...</div>}
          {error && <div className="text-center py-10 text-red-500">Failed to load insights.</div>}
          
          {suggestions && (
              <StaggerContainer delayMultiplier={0.1}>
                 {suggestions.map((insight, idx) => (
                     <StaggerItem key={idx} className="mb-4">
                        <InteractiveCard className="p-6 rounded-[24px] flex gap-4 items-start">
                           {insight.type === 'positive' && <CheckCircle className="w-8 h-8 text-emerald-500 shrink-0" />}
                           {insight.type === 'warning' && <AlertCircle className="w-8 h-8 text-rose-500 shrink-0" />}
                           {insight.type === 'neutral' && <Lightbulb className="w-8 h-8 text-blue-500 shrink-0" />}
                           <div>
                              <p className="text-[var(--foreground)] font-medium text-lg">{insight.message}</p>
                           </div>
                        </InteractiveCard>
                     </StaggerItem>
                 ))}
              </StaggerContainer>
          )}
      </main>
    </div>
  )
}

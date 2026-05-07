'use client'

import { FadeUpDiv, InteractiveCard } from '@/components/ui/MotionDiv'
import { Info, Heart, Shield } from 'lucide-react'

export default function AboutPage() {
  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-8 md:py-12 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30">
        <FadeUpDiv className="flex items-center gap-4 max-w-4xl mx-auto">
          <div className="bg-purple-500/10 p-3 rounded-2xl hidden md:block">
            <Info className="w-6 h-6 text-purple-500" />
          </div>
          <div>
             <h1 className="text-3xl font-extrabold tracking-tight">About Dietelligence</h1>
             <p className="text-[var(--text-secondary)] font-medium mt-1">Our mission and open source details.</p>
          </div>
        </FadeUpDiv>
      </header>
      <main className="flex-1 w-full max-w-4xl mx-auto p-6 md:p-8 space-y-6">
         <FadeUpDiv delay={0.1}>
            <InteractiveCard className="p-8 rounded-[32px] flex items-center justify-center bg-gradient-to-tr from-indigo-50 to-purple-50 dark:from-indigo-950 dark:to-purple-950">
               <div className="text-center">
                  <Heart className="w-16 h-16 text-purple-500 mx-auto mb-4" />
                  <h2 className="text-2xl font-bold mb-2">Build Better Habits</h2>
                  <p className="text-[var(--text-secondary)] max-w-md mx-auto">
                    Dietelligence acts as your personal AI nutritionist, empowering you to make smarter food choices every single day.
                  </p>
               </div>
            </InteractiveCard>
         </FadeUpDiv>
         <FadeUpDiv delay={0.2}>
             <InteractiveCard className="p-6 rounded-[24px]">
                 <div className="flex items-center gap-4 mb-4">
                    <Shield className="w-6 h-6 text-emerald-500" />
                    <h3 className="font-bold text-lg">Privacy First</h3>
                 </div>
                 <p className="text-sm text-[var(--text-secondary)]">Your dietary data is securely stored and exclusively processed for your personal analytics. We never share your history with external parties without consent.</p>
             </InteractiveCard>
         </FadeUpDiv>
      </main>
    </div>
  )
}

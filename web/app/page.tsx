'use client'

import Link from 'next/link'
import { ArrowRight, Activity, Camera, PieChart, Sparkles } from 'lucide-react'
import { FadeUpDiv, StaggerContainer, StaggerItem, InteractiveCard } from '@/components/ui/MotionDiv'
import { motion } from 'framer-motion'
import { ThemeToggle } from '@/components/ui/ThemeToggle'
import { AuroraBackground } from '@/components/ui/AuroraBackground'
import { GlowingCard } from '@/components/ui/GlowingCard'

export default function LandingPage() {
  return (
    <AuroraBackground>

      <header className="absolute top-0 left-0 right-0 px-8 py-6 flex items-center justify-between z-20">
        <div className="text-2xl font-bold tracking-tighter flex items-center gap-2 text-[var(--foreground)]">
          <Camera className="w-6 h-6" />
          Foodshutter
        </div>
        <div className="flex items-center gap-4">
          <ThemeToggle />
          <Link 
            href="/login" 
            className="px-6 py-2 rounded-full text-sm font-medium bg-[var(--foreground)]/10 text-[var(--foreground)] hover:bg-[var(--foreground)]/20 backdrop-blur-md transition-colors border border-[var(--divider)]"
          >
            Sign In
          </Link>
        </div>
      </header>

      <main className="relative flex min-h-screen flex-col items-center justify-center p-6 text-center z-10 pt-20">
        
        <FadeUpDiv delay={0.2} className="mb-6 inline-flex items-center gap-2 px-4 py-2 rounded-full border border-[var(--divider)] bg-[var(--surface)] shadow-sm">
          <Sparkles className="w-4 h-4 text-[var(--color-primary-600)]" />
          <span className="text-sm font-medium text-[var(--text-secondary)]">AI-Powered Nutrition Analysis</span>
        </FadeUpDiv>

        <FadeUpDiv delay={0.3}>
          <h1 className="text-5xl md:text-7xl lg:text-8xl font-black tracking-tighter mb-6 bg-clip-text text-transparent bg-gradient-to-b from-[var(--foreground)] to-[var(--text-secondary)] leading-tight">
            Smarter eating <br className="hidden md:block"/> decisions.
          </h1>
        </FadeUpDiv>
        
        <FadeUpDiv delay={0.4} className="max-w-2xl mx-auto mb-10">
          <p className="text-lg md:text-xl text-[var(--text-secondary)] font-medium">
            Track your nutrition instantly. Snap a photo of your meal and let Foodshutter analyze the ingredients and macros for you within seconds.
          </p>
        </FadeUpDiv>

        <FadeUpDiv delay={0.5} className="flex flex-col sm:flex-row gap-4 mb-24">
          <Link
            href="/login"
            className="group relative inline-flex items-center justify-center gap-2 overflow-hidden rounded-full bg-[var(--foreground)] text-[var(--background)] px-8 py-4 font-bold text-lg hover:opacity-90 transition-opacity"
          >
            <span>Get Started Free</span>
            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
          </Link>
        </FadeUpDiv>
        
        <StaggerContainer delayMultiplier={0.2} className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full max-w-6xl mx-auto text-left relative z-10">
          <StaggerItem>
             <GlowingCard className="h-full">
               <Link href="/login" className="block p-8 h-full cursor-pointer hover:opacity-90 transition-opacity">
                <div className="mb-6 bg-gradient-to-br from-blue-500 to-cyan-500 w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-500/20 relative z-30 group-hover:scale-110 transition-transform">
                  <Camera className="w-7 h-7 text-white" />
                </div>
                <h3 className="font-bold text-2xl mb-3 text-[var(--foreground)] relative z-30">Instant Analysis</h3>
                <p className="text-[var(--text-secondary)] leading-relaxed text-lg relative z-30">Take a photo and get detailed nutritional breakdown within seconds using Gemini Vision.</p>
               </Link>
             </GlowingCard>
          </StaggerItem>

          <StaggerItem>
             <GlowingCard className="h-full">
              <Link href="/login" className="block p-8 h-full cursor-pointer hover:opacity-90 transition-opacity">
                <div className="mb-6 bg-gradient-to-br from-purple-500 to-pink-500 w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg shadow-purple-500/20 relative z-30 group-hover:scale-110 transition-transform">
                  <Activity className="w-7 h-7 text-white" />
                </div>
                <h3 className="font-bold text-2xl mb-3 text-[var(--foreground)] relative z-30">AI Suggestions</h3>
                <p className="text-[var(--text-secondary)] leading-relaxed text-lg relative z-30">Get context-aware recommendations based on your nutrition history and personal goals.</p>
              </Link>
             </GlowingCard>
          </StaggerItem>

          <StaggerItem>
             <GlowingCard className="h-full">
              <Link href="/login" className="block p-8 h-full cursor-pointer hover:opacity-90 transition-opacity">
                <div className="mb-6 bg-gradient-to-br from-orange-400 to-red-500 w-14 h-14 rounded-2xl flex items-center justify-center shadow-lg shadow-red-500/20 relative z-30 group-hover:scale-110 transition-transform">
                  <PieChart className="w-7 h-7 text-white" />
                </div>
                <h3 className="font-bold text-2xl mb-3 text-[var(--foreground)] relative z-30">Visual Trends</h3>
                <p className="text-[var(--text-secondary)] leading-relaxed text-lg relative z-30">Track your daily macros with beautiful, interactive charts and progress rings.</p>
              </Link>
            </GlowingCard>
          </StaggerItem>
        </StaggerContainer>
      </main>

      <footer className="relative z-10 border-t border-[var(--divider)] mt-auto py-8 text-center text-[var(--text-secondary)] backdrop-blur-sm">
        <p>© {new Date().getFullYear()} Dietelligence Team. Premium Web Vision.</p>
      </footer>
    </AuroraBackground>
  )
}

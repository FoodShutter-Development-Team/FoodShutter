'use client'

import { useParams } from 'next/navigation'
import Link from 'next/link'
import { FadeUpDiv, InteractiveCard } from '@/components/ui/MotionDiv'
import { ChevronLeft, Info } from 'lucide-react'

export default function NutritionDetailPage() {
  const { id } = useParams()

  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-6 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30 flex items-center gap-4">
         <Link href="/nutrition" className="p-2 hover:bg-[var(--background)] rounded-full transition-colors">
            <ChevronLeft className="w-6 h-6" />
         </Link>
         <h1 className="text-xl font-bold">Food Details</h1>
      </header>

      <main className="flex-1 w-full max-w-3xl mx-auto p-6 md:p-8 space-y-6">
         <FadeUpDiv>
             <InteractiveCard className="p-8 rounded-[32px] text-center">
                <div className="w-24 h-24 mx-auto bg-green-500/10 rounded-full flex items-center justify-center mb-6">
                   <Info className="w-10 h-10 text-green-500" />
                </div>
                <h2 className="text-3xl font-extrabold mb-2">Item #{id}</h2>
                <p className="text-[var(--text-secondary)]">Detailed macro tracking view placeholder.</p>
                
                <div className="grid grid-cols-3 gap-4 mt-8 pt-8 border-t border-[var(--divider)]">
                    <div>
                       <p className="text-sm font-semibold text-[var(--text-secondary)] uppercase tracking-wider mb-1">Protein</p>
                       <p className="font-bold text-2xl">--g</p>
                    </div>
                    <div>
                       <p className="text-sm font-semibold text-[var(--text-secondary)] uppercase tracking-wider mb-1">Carbs</p>
                       <p className="font-bold text-2xl">--g</p>
                    </div>
                    <div>
                       <p className="text-sm font-semibold text-[var(--text-secondary)] uppercase tracking-wider mb-1">Fat</p>
                       <p className="font-bold text-2xl">--g</p>
                    </div>
                </div>
             </InteractiveCard>
         </FadeUpDiv>
      </main>
    </div>
  )
}

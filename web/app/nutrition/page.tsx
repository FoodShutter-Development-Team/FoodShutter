'use client'

import { useState, useEffect } from 'react';
import useSWR from 'swr';
import { searchNutrition } from '@/lib/api/nutrition';
import { FadeUpDiv, StaggerContainer, StaggerItem, InteractiveCard } from '@/components/ui/MotionDiv';
import { Search, Apple, ChevronRight } from 'lucide-react';
import Link from 'next/link';

export default function NutritionSearchPage() {
  const [query, setQuery] = useState('');
  const [debouncedQuery, setDebouncedQuery] = useState('');

  // Debounce logic
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedQuery(query);
    }, 300);
    return () => clearTimeout(handler);
  }, [query]);

  const { data: results, error, isLoading } = useSWR(
    debouncedQuery ? ['search-nutrition', debouncedQuery] : null,
    ([_, q]) => searchNutrition(q)
  );

  return (
    <div className="flex flex-col min-h-screen">
      <header className="px-6 py-8 md:py-12 border-b border-[var(--divider)] bg-[var(--surface)]/50 backdrop-blur-md sticky top-0 z-30">
        <FadeUpDiv className="flex flex-col gap-6 max-w-4xl mx-auto">
          <div className="flex items-center gap-4">
             <div className="bg-green-500/10 p-3 rounded-2xl hidden md:block">
               <Apple className="w-6 h-6 text-green-500" />
             </div>
             <div>
                <h1 className="text-3xl font-extrabold tracking-tight">Nutrition Base</h1>
                <p className="text-[var(--text-secondary)] font-medium mt-1">Search for food items from the vector database.</p>
             </div>
          </div>
          
          <div className="relative">
             <Search className="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-[var(--text-secondary)]" />
             <input 
               type="text" 
               value={query}
               onChange={e => setQuery(e.target.value)}
               placeholder="Search foods, e.g. 'Grilled Chicken'..."
               className="w-full pl-12 pr-4 py-4 rounded-full bg-[var(--background)] border border-[var(--divider)] focus:border-green-500 focus:ring-2 focus:ring-green-500/20 outline-none transition-all font-medium"
             />
          </div>
        </FadeUpDiv>
      </header>

      <main className="flex-1 w-full max-w-4xl mx-auto p-6 md:p-8 space-y-6">
          {!debouncedQuery && (
             <div className="text-center py-20 text-[var(--text-secondary)]">Start typing to search our nutrition database.</div>
          )}
          {isLoading && <div className="text-center py-10 text-[var(--text-secondary)] animate-pulse">Searching...</div>}
          {error && <div className="text-center py-10 text-red-500">Failed to search database.</div>}
          
          {debouncedQuery && results && results.length === 0 && (
             <div className="text-center py-10 font-bold">No results found for "{debouncedQuery}"</div>
          )}

          {results && results.length > 0 && (
              <StaggerContainer delayMultiplier={0.1}>
                 {results.map((item: any, idx: number) => (
                     <StaggerItem key={idx} className="mb-4">
                        <Link href={`/nutrition/${item.id || idx}`}>
                            <InteractiveCard className="p-5 rounded-[24px] flex items-center justify-between group cursor-pointer hover:border-green-500/30">
                               <div className="flex items-center gap-4">
                                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/40 dark:to-green-800/20 flex items-center justify-center">
                                     <Apple className="w-5 h-5 text-green-500" />
                                  </div>
                                  <div>
                                     <p className="font-bold text-lg group-hover:text-green-500 transition-colors">{item.name || 'Unknown Food'}</p>
                                     <p className="text-sm text-[var(--text-secondary)]">100g serving</p>
                                  </div>
                               </div>
                               <ChevronRight className="w-5 h-5 text-[var(--divider)] group-hover:text-green-500 transition-colors" />
                            </InteractiveCard>
                        </Link>
                     </StaggerItem>
                 ))}
              </StaggerContainer>
          )}
      </main>
    </div>
  )
}

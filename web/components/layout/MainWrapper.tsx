'use client'

import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils/cn'

export function MainWrapper({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()
  
  // Calculate if the current route has the sidebar
  const hasSidebar = !(pathname === '/' || pathname.startsWith('/login'))

  return (
    <main 
      className={cn(
        "min-h-screen flex flex-col w-full transition-all duration-300",
        hasSidebar ? "md:pl-64 pb-24 md:pb-0" : ""
      )}
    >
      {children}
    </main>
  )
}

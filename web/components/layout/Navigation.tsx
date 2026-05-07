'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Activity, History, PieChart, Settings, Camera } from 'lucide-react'
import { cn } from '@/lib/utils/cn'
import { createClient } from '@/lib/supabase/client'
import { useEffect, useState } from 'react'

const ROUTES = [
  { href: '/dashboard', label: 'Dashboard', icon: Activity },
  { href: '/history', label: 'History', icon: History },
  { href: '/stats', label: 'Stats', icon: PieChart },
  { href: '/settings', label: 'Settings', icon: Settings },
]

export function Navigation() {
  const pathname = usePathname()
  
  // Do not show navigation on auth/landing pages
  if (pathname === '/' || pathname.startsWith('/login')) return null

  return (
    <>
      <DesktopSidebar pathname={pathname} />
      <MobileTabBar pathname={pathname} />
    </>
  )
}

function DesktopSidebar({ pathname }: { pathname: string }) {
  const [userEmail, setUserEmail] = useState<string>('...')
  
  useEffect(() => {
    const supabase = createClient()
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (user) {
        setUserEmail(user.email || 'User')
      } else {
        setUserEmail('Not logged in')
      }
    })
  }, [])

  return (
    <div className="hidden md:flex flex-col w-64 h-full fixed inset-y-0 left-0 bg-[var(--surface)] border-r border-[var(--divider)] shadow-sm z-50">
      <div className="p-6 pb-2 text-xl font-bold text-[var(--color-primary-600)] flex items-center space-x-2">
        <Camera className="w-6 h-6" />
        <span>Foodshutter</span>
      </div>
      
      <div className="flex-1 py-6 px-4 space-y-2">
        {ROUTES.map((route) => {
          const isActive = pathname.startsWith(route.href)
          const Icon = route.icon
          return (
            <Link 
              key={route.href} 
              href={route.href}
              className={cn(
                "flex items-center space-x-3 px-4 py-3 rounded-[var(--radius-ios)] transition-all duration-200 group relative overflow-hidden",
                isActive 
                  ? "bg-blue-500/10 text-[var(--color-primary-600)] font-semibold shadow-sm"
                  : "text-[var(--text-secondary)] hover:bg-[var(--background)] hover:text-[var(--foreground)]"
              )}
            >
              {isActive && (
                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-2/3 bg-[var(--color-primary-600)] rounded-r-md"></div>
              )}
              <Icon className={cn("w-5 h-5", isActive ? "scale-110 transition-transform" : "group-hover:scale-110 transition-transform")} />
              <span>{route.label}</span>
            </Link>
          )
        })}
      </div>
      
      <div className="p-4 border-t border-[var(--divider)]">
        <div className="flex items-center space-x-3 px-4 py-3 rounded-[var(--radius-ios)] bg-[var(--background)]">
           <div className="w-8 h-8 rounded-full bg-[var(--color-primary-600)]/20 text-[var(--color-primary-600)] flex items-center justify-center font-bold uppercase">
             {userEmail !== '...' && userEmail !== 'Not logged in' ? userEmail.charAt(0) : 'U'}
           </div>
           <div className="text-sm font-medium truncate max-w-[150px]">{userEmail}</div>
        </div>
      </div>
    </div>
  )
}

function MobileTabBar({ pathname }: { pathname: string }) {
  return (
    <div className="md:hidden fixed bottom-0 left-0 w-full bg-[var(--surface)]/80 backdrop-blur-xl border-t border-[var(--divider)] z-50 pb-[env(safe-area-inset-bottom,16px)] pt-2 px-2 shadow-[0_-4px_24px_rgba(0,0,0,0.04)]">
      <div className="flex justify-around items-center">
        {ROUTES.map((route) => {
          const isActive = pathname.startsWith(route.href)
          const Icon = route.icon
          return (
            <Link 
              key={route.href} 
              href={route.href}
              className={cn(
                "flex flex-col items-center justify-center p-2 w-16 transition-all duration-300",
                isActive ? "text-[var(--color-primary-600)] -translate-y-1" : "text-[var(--text-secondary)] hover:text-[var(--foreground)]"
              )}
            >
              <div className="relative">
                <Icon className="w-6 h-6 mb-1" />
                {isActive && <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-[var(--color-primary-600)]" />}
              </div>
              <span className="text-[10px] font-medium">{route.label}</span>
            </Link>
          )
        })}
      </div>
    </div>
  )
}

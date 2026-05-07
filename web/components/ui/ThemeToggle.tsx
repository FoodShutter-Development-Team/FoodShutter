'use client'

import { useTheme } from 'next-themes'
import { Moon, Sun, Laptop } from 'lucide-react'
import { useEffect, useState } from 'react'

export function ThemeToggle() {
  const { theme, setTheme } = useTheme()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) return (
    <div className="flex bg-[var(--surface)] border border-[var(--divider)] rounded-full p-1 shadow-sm opacity-0">
       <div className="w-8 h-8"></div>
       <div className="w-8 h-8"></div>
       <div className="w-8 h-8"></div>
    </div>
  )

  return (
    <div className="flex bg-[var(--surface)] border border-[var(--divider)] rounded-full p-1 shadow-sm">
      {['system', 'light', 'dark'].map((t) => (
         <button 
            key={t}
            onClick={() => setTheme(t)}
            className={`flex items-center justify-center p-2 rounded-full transition-all ${theme === t ? 'bg-[var(--foreground)] text-[var(--background)] shadow-sm' : 'text-[var(--text-secondary)] hover:text-[var(--foreground)]'}`}
         >
            {t === 'system' && <Laptop className="w-4 h-4" />}
            {t === 'light' && <Sun className="w-4 h-4" />}
            {t === 'dark' && <Moon className="w-4 h-4" />}
         </button>
      ))}
    </div>
  )
}

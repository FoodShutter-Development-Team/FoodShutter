'use client'

import { useRef, useState, ReactNode, useEffect } from 'react'
import { useTheme } from 'next-themes'

export function GlowingCard({ children, className = '' }: { children: ReactNode, className?: string }) {
  const divRef = useRef<HTMLDivElement>(null)
  const [mounted, setMounted] = useState(false)
  const [isFocused, setIsFocused] = useState(false)
  const [position, setPosition] = useState({ x: 0, y: 0 })
  const [opacity, setOpacity] = useState(0)
  const { resolvedTheme } = useTheme()

  // Avoid hydration mismatch by waiting for mount
  useEffect(() => {
    setMounted(true)
  }, [])

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!divRef.current || isFocused) return

    const rect = divRef.current.getBoundingClientRect()
    setPosition({ x: e.clientX - rect.left, y: e.clientY - rect.top })
  }

  const handleFocus = () => {
    setIsFocused(true)
    setOpacity(1)
  }

  const handleBlur = () => {
    setIsFocused(false)
    setOpacity(0)
  }

  const handleMouseEnter = () => {
    setOpacity(1)
  }

  const handleMouseLeave = () => {
    setOpacity(0)
  }

  return (
    <div
      ref={divRef}
      onMouseMove={handleMouseMove}
      onFocus={handleFocus}
      onBlur={handleBlur}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      className={`relative overflow-hidden rounded-3xl bg-[var(--surface)] border border-[var(--divider)] shadow-sm group ${className}`}
    >
      {/* Dynamic Theme Glow */}
      <div
        className="pointer-events-none absolute -inset-px transition duration-300 z-10"
        style={{
          opacity: mounted ? opacity : 0,
          background: mounted 
            ? `radial-gradient(600px circle at ${position.x}px ${position.y}px, ${resolvedTheme === 'dark' ? 'rgba(255, 255, 255, 0.08)' : 'rgba(34, 197, 94, 0.15)'}, transparent 40%)`
            : 'none',
        }}
      />
      
      {/* Subtle border highlight */}
      <div
        className="pointer-events-none absolute -inset-px opacity-0 transition duration-300 z-20"
        style={{
          opacity: mounted ? opacity : 0,
          background: mounted
            ? `radial-gradient(300px circle at ${position.x}px ${position.y}px, rgba(255,255,255,0.4), transparent 40%)`
            : 'none',
          WebkitMask: `linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)`,
          WebkitMaskComposite: 'xor',
          maskComposite: 'exclude',
          padding: '1px', // Border width indicator
        }}
      />

      <div className="relative z-30 h-full w-full">
        {children}
      </div>
    </div>
  )
}

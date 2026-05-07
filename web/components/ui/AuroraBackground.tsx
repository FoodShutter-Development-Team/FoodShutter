'use client'

import { motion } from 'framer-motion'
import { ReactNode } from 'react'

export function AuroraBackground({ children }: { children: ReactNode }) {
  return (
    <div className="relative min-h-screen w-full flex flex-col items-center justify-center overflow-hidden bg-[var(--background)] transition-colors duration-500">
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none w-full h-full">
        <motion.div
           animate={{
              x: ["0%", "20%", "-20%", "0%"],
              y: ["0%", "10%", "-10%", "0%"],
              scale: [1, 1.2, 1]
           }}
           transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
           className="absolute -top-[10%] -left-[10%] w-[50vw] h-[50vh] bg-[var(--accent-glow-primary)] rounded-full blur-[100px] will-change-transform"
        />
        <motion.div
           animate={{
              x: ["0%", "-30%", "20%", "0%"],
              y: ["0%", "-20%", "20%", "0%"],
              scale: [1, 1.3, 0.9, 1]
           }}
           transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
           className="absolute top-[20%] right-[10%] w-[60vw] h-[60vh] bg-[var(--accent-glow-secondary)] rounded-full blur-[120px] will-change-transform"
        />
        <motion.div
           animate={{
              x: ["0%", "40%", "-10%", "0%"],
              y: ["0%", "30%", "-30%", "0%"],
              scale: [1, 0.8, 1.2, 1]
           }}
           transition={{ duration: 30, repeat: Infinity, ease: "linear" }}
           className="absolute -bottom-[20%] left-[20%] w-[50vw] h-[50vh] bg-[var(--color-primary-600)] rounded-full blur-[120px] opacity-40 dark:opacity-60 will-change-transform"
        />
        
        {/* Delicate grain overlay for luxury texture */}
        <div className="absolute inset-0 z-0 opacity-[0.03] mix-blend-normal pointer-events-none bg-[url('data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0MDAiIGhlaWdodD0iNDAwIj4KICA8ZmlsdGVyIGlkPSJub2lzZSI+CiAgICA8ZmVUdXJidWxlbmNlIHR5cGU9ImZyYWN0YWxOb2lzZSIgYmFzZUZyZXF1ZW5jeT0iMC45IiBudW1PY3RhdmVzPSIzIiBzdGl0Y2hUaWxlcz0ic3RpdGNoIi8+CiAgPC9maWx0ZXI+CiAgPHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsdGVyPSJ1cmwoI25vaXNlKSIgb3BhY2l0eT0iMSIvPgo8L3N2Zz4=')]" />
      </div>

      <div className="relative z-10 w-full h-full flex flex-col flex-1">
        {children}
      </div>
    </div>
  )
}

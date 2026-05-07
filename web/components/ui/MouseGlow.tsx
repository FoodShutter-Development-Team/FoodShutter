'use client'

import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'

export function MouseGlow() {
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 })
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    const updateMousePosition = (e: MouseEvent) => {
      setMousePosition({ x: e.clientX, y: e.clientY })
      setIsVisible(true)
    }

    const handleMouseLeave = (e: MouseEvent) => {
      if (
        e.clientY <= 0 ||
        e.clientX <= 0 ||
        e.clientX >= window.innerWidth ||
        e.clientY >= window.innerHeight
      ) {
        setIsVisible(false)
      }
    }

    window.addEventListener('mousemove', updateMousePosition)
    document.addEventListener('mouseleave', handleMouseLeave)

    return () => {
      window.removeEventListener('mousemove', updateMousePosition)
      document.removeEventListener('mouseleave', handleMouseLeave)
    }
  }, [])

  return (
    <motion.div
      className="pointer-events-none fixed top-0 left-0 z-[100] w-[400px] h-[400px] mix-blend-multiply dark:mix-blend-screen"
      animate={{
        x: mousePosition.x - 200, 
        y: mousePosition.y - 200,
        opacity: isVisible ? 1 : 0
      }}
      transition={{ type: 'tween', ease: 'easeOut', duration: 0 }}
    >
      <div className="w-full h-full bg-[#4ade80]/40 dark:bg-blue-500/20 blur-[80px] rounded-full" />
    </motion.div>
  )
}

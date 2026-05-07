'use client'

import { motion, HTMLMotionProps } from 'framer-motion'
import { cn } from '@/lib/utils/cn'

interface MotionDivProps extends HTMLMotionProps<'div'> {
  delay?: number
  duration?: number
  delayMultiplier?: number
}

export function FadeUpDiv({ className, delay = 0, duration = 0.5, children, ...props }: MotionDivProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration, delay, type: "spring", bounce: 0.3 }}
      className={cn("w-full", className)}
      {...props}
    >
      {children}
    </motion.div>
  )
}

export function StaggerContainer({ className, delayMultiplier = 0.1, children, ...props }: MotionDivProps) {
    return (
        <motion.div
            initial="hidden"
            animate="visible"
            variants={{
                hidden: { opacity: 0 },
                visible: {
                    opacity: 1,
                    transition: {
                        staggerChildren: delayMultiplier,
                    }
                }
            }}
            className={className}
            {...props}
        >
            {children}
        </motion.div>
    )
}

export function StaggerItem({ className, children, ...props }: MotionDivProps) {
    return (
        <motion.div
            variants={{
                hidden: { opacity: 0, y: 20 },
                visible: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 300, damping: 24 } }
            }}
            className={className}
            {...props}
        >
            {children}
        </motion.div>
    )
}

// Hover interaction card
export function InteractiveCard({ className, children, ...props }: MotionDivProps) {
  return (
    <motion.div
      whileHover={{ scale: 1.02, y: -4 }}
      whileTap={{ scale: 0.98 }}
      transition={{ type: "spring", stiffness: 400, damping: 20 }}
      className={cn(
        "bg-[var(--surface)]/80 backdrop-blur-xl border border-[var(--divider)] shadow-sm overflow-hidden",
        className
      )}
      {...props}
    >
      {children}
    </motion.div>
  )
}

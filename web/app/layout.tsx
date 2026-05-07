import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Navigation } from '@/components/layout/Navigation'
import { MainWrapper } from '@/components/layout/MainWrapper'
import { ThemeProvider } from '@/components/providers/ThemeProvider'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'Foodshutter',
  description: 'AI-powered nutrition companion for smarter eating decisions',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <body className="antialiased min-h-screen relative bg-[var(--background)] text-[var(--foreground)] overflow-x-hidden flex">
        <ThemeProvider
          attribute="class"
          defaultTheme="light"
          enableSystem={false}
          storageKey="foodshutter-theme"
          disableTransitionOnChange
        >
          <Navigation />
          <MainWrapper>
            {children}
          </MainWrapper>
        </ThemeProvider>
      </body>
    </html>
  )
}

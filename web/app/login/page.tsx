'use client'

import { useEffect, useState, Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Apple, Mail, AlertTriangle } from 'lucide-react'

function LoginContent() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [errorObj, setErrorObj] = useState<any>(null)
  const searchParams = useSearchParams()

  useEffect(() => {
    const errorMsg = searchParams.get('message')
    if (errorMsg) {
      setErrorObj({ message: errorMsg })
    }
    const successMsg = searchParams.get('success')
    if (successMsg) {
      setMessage(successMsg)
    }
  }, [searchParams])

  const handleAppleLogin = async () => {
    setErrorObj(null)
    const supabase = createClient()
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'apple',
      options: {
        redirectTo: `${window.location.origin}/auth/callback?next=/dashboard`,
      },
    })
    
    if (error) {
      console.error('Error logging in with Apple:', error)
      setErrorObj(error)
    }
  }

  const handlePasswordLogin = async (e: React.MouseEvent) => {
    e.preventDefault()
    if (!email || !password) return;
    setLoading(true)
    setErrorObj(null)
    setMessage('')
    const supabase = createClient()
    
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setErrorObj(error)
    } else {
      window.location.href = '/dashboard'
    }
    setLoading(false)
  }

  const handleEmailLogin = async (e: React.MouseEvent) => {
    e.preventDefault()
    if (!email) return;
    setLoading(true)
    setErrorObj(null)
    setMessage('')
    const supabase = createClient()
    
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback?next=/dashboard`,
      },
    })

    if (error) {
      setErrorObj(error)
    } else {
      setMessage('Magic link sent! Check your email to securely log in.')
    }
    setLoading(false)
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center p-6">
      <div className="w-full max-w-sm space-y-8 flex flex-col items-center text-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Login to <span className="text-[var(--color-primary-600)]">Foodshutter</span></h1>
          <p className="mt-2 text-[var(--text-secondary)]">Sign in to track your nutrition and view history.</p>
        </div>
        
        {errorObj && (
           <div className="w-full bg-red-500/10 border border-red-500/20 text-red-600 p-4 rounded-xl flex items-start text-left text-sm gap-3">
              <AlertTriangle className="w-5 h-5 shrink-0" />
              <div>
                 <strong>Authentication Error</strong>
                 <p className="mt-1">{errorObj.message || 'Validation failed. Please ensure providers are configured in Supabase.'}</p>
                 {errorObj.message?.includes('Unsupported provider') && (
                    <p className="mt-2 font-semibold">Tip: You must configure an Apple Secret (p8 key) in your Supabase Auth dashboard before Apple Login will work.</p>
                 )}
              </div>
           </div>
        )}

        {message && (
            <div className="w-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-600 p-4 rounded-xl flex items-center gap-3 font-medium text-sm text-left">
               <Mail className="w-5 h-5" />
               {message}
            </div>
        )}

        <div className="w-full space-y-4">
          <button
            onClick={handleAppleLogin}
            className="w-full flex items-center justify-center gap-2 rounded-[var(--radius-ios)] bg-black dark:bg-white text-white dark:text-black font-semibold py-4 px-4 shadow-[0_4px_12px_rgba(0,0,0,0.1)] active:scale-95 transition-transform"
          >
            <Apple className="w-5 h-5 mb-1" />
            Continue with Apple
          </button>
          
          <div className="relative py-2">
            <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-[var(--divider)]"></div></div>
            <div className="relative flex justify-center text-xs uppercase"><span className="bg-[var(--background)] px-2 text-[var(--text-secondary)] font-bold">Or Email Login</span></div>
          </div>

          <form className="space-y-4">
             <input 
                type="email" 
                placeholder="developer@example.com"
                value={email}
                onChange={e => setEmail(e.target.value)}
                className="w-full px-4 py-4 rounded-[var(--radius-ios)] bg-[var(--surface)] border border-[var(--divider)] focus:border-[var(--color-primary-500)] outline-none text-left"
                required
             />
             <input 
                type="password" 
                placeholder="Password (for password login)"
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="w-full px-4 py-4 rounded-[var(--radius-ios)] bg-[var(--surface)] border border-[var(--divider)] focus:border-[var(--color-primary-500)] outline-none text-left"
             />
             <div className="flex flex-col sm:flex-row gap-3">
               <button
                 type="button"
                 onClick={handlePasswordLogin}
                 disabled={loading || !email || !password}
                 className="flex-1 flex items-center justify-center gap-2 rounded-[var(--radius-ios)] bg-[var(--foreground)] hover:bg-[var(--foreground)]/90 disabled:opacity-50 text-[var(--background)] font-semibold py-4 px-4 shadow-sm active:scale-95 transition-transform"
               >
                 {loading ? 'Wait...' : 'Password Login'}
               </button>
               <button
                 type="button"
                 onClick={handleEmailLogin}
                 disabled={loading || !email}
                 className="flex-1 flex items-center justify-center gap-2 rounded-[var(--radius-ios)] bg-blue-600 hover:bg-blue-700 disabled:opacity-50 text-white font-semibold py-4 px-4 shadow-sm active:scale-95 transition-transform"
               >
                 {loading ? 'Sending...' : 'Magic Link'}
               </button>
             </div>
          </form>

        </div>

        <p className="text-sm text-[var(--text-secondary)] mt-8">
          By signing in, you agree to our Terms of Service and Privacy Policy.
        </p>
      </div>
    </div>
  )
}

export default function LoginPage() {
  return (
    <Suspense fallback={<div className="min-h-screen flex items-center justify-center">Loading...</div>}>
      <LoginContent />
    </Suspense>
  )
}

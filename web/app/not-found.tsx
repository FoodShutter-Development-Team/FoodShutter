import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="flex flex-col min-h-screen items-center justify-center p-6 text-center">
      <h2 className="text-6xl font-bold mb-4 text-[var(--text-secondary)]">404</h2>
      <p className="text-xl font-semibold mb-2">Page Not Found</p>
      <p className="text-[var(--text-secondary)] mb-8">Could not find requested resource</p>
      <Link 
        href="/"
        className="px-6 py-3 bg-[var(--color-primary-500)] text-white rounded-[var(--radius-ios)] font-semibold hover:bg-[var(--color-primary-600)] transition-colors"
      >
        Return Home
      </Link>
    </div>
  )
}

import type { ReactNode } from 'react'
import { ChevronLeft } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

interface AppHeaderProps {
  title?: ReactNode
  subtitle?: ReactNode
  leading?: ReactNode
  trailing?: ReactNode
  showBack?: boolean
}

export function AppHeader({ title, subtitle, leading, trailing, showBack }: AppHeaderProps) {
  const navigate = useNavigate()
  return (
    <header className="sticky top-0 z-30 flex items-center gap-3 bg-background/95 px-5 pb-3 pt-[calc(env(safe-area-inset-top)+16px)] backdrop-blur-md">
      {showBack ? (
        <button
          onClick={() => navigate(-1)}
          aria-label="Voltar"
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-surface-elevated text-text-primary active:opacity-70"
        >
          <ChevronLeft size={20} />
        </button>
      ) : (
        leading
      )}
      <div className="min-w-0 flex-1">
        {title && <h1 className="truncate text-lg font-semibold text-text-primary">{title}</h1>}
        {subtitle && <p className="truncate text-sm text-text-secondary">{subtitle}</p>}
      </div>
      {trailing}
    </header>
  )
}

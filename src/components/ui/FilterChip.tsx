import type { ReactNode } from 'react'

interface FilterChipProps {
  label: string
  active?: boolean
  onClick?: () => void
  icon?: ReactNode
}

export function FilterChip({ label, active = false, onClick, icon }: FilterChipProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        'flex shrink-0 items-center gap-1.5 rounded-full px-4 py-2 text-sm font-medium transition-colors',
        active
          ? 'bg-primary text-white'
          : 'bg-surface-elevated text-text-secondary active:bg-surface-secondary',
      ].join(' ')}
    >
      {icon}
      {label}
    </button>
  )
}

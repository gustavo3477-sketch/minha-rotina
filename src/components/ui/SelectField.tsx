import { ChevronRight } from 'lucide-react'
import type { ReactNode } from 'react'

interface SelectFieldProps {
  value: string
  placeholder?: string
  icon?: ReactNode
  onClick: () => void
}

export function SelectField({ value, placeholder = 'Selecionar', icon, onClick }: SelectFieldProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex w-full items-center justify-between gap-2 rounded-2xl border border-border/70 bg-surface-secondary px-4 py-3 text-left"
    >
      <span className="flex items-center gap-2 text-[15px] text-text-primary">
        {icon}
        {value || <span className="text-text-muted">{placeholder}</span>}
      </span>
      <ChevronRight size={18} className="shrink-0 text-text-muted" />
    </button>
  )
}

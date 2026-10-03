import { Check } from 'lucide-react'
import type { ReactNode } from 'react'

interface OptionRowProps {
  label: string
  description?: string
  icon?: ReactNode
  selected?: boolean
  onClick: () => void
}

export function OptionRow({ label, description, icon, selected, onClick }: OptionRowProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex w-full items-center gap-3 rounded-2xl px-2 py-3 text-left active:bg-surface-elevated"
    >
      {icon}
      <div className="flex-1">
        <p className="text-[15px] font-medium text-text-primary">{label}</p>
        {description && <p className="text-xs text-text-secondary">{description}</p>}
      </div>
      {selected && <Check size={18} className="text-primary" />}
    </button>
  )
}

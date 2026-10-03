import type { ReactNode } from 'react'
import { getIcon } from '../../lib/icons'

interface EmptyStateProps {
  icon?: string
  title: string
  description?: string
  action?: ReactNode
}

export function EmptyState({ icon = 'Inbox', title, description, action }: EmptyStateProps) {
  const Icon = getIcon(icon)
  return (
    <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-border/70 px-4 py-8 text-center">
      <Icon size={28} strokeWidth={1.75} className="text-text-muted" />
      <p className="text-sm font-medium text-text-secondary">{title}</p>
      {description && <p className="text-xs text-text-muted">{description}</p>}
      {action}
    </div>
  )
}

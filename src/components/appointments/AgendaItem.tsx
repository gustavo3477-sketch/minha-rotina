import { getIcon } from '../../lib/icons'
import { getTokenClasses } from '../../lib/tokens'
import type { AgendaEntry } from '../../hooks/useAgendaEntries'

export function AgendaItem({ entry, onClick }: { entry: AgendaEntry; onClick?: () => void }) {
  const Icon = getIcon(entry.icon)
  const classes = getTokenClasses(entry.token)

  return (
    <button
      onClick={onClick}
      className="flex w-full items-center gap-3 rounded-2xl px-1 py-2.5 text-left active:bg-surface-elevated"
    >
      <div className="w-12 shrink-0 text-right">
        <p className="text-sm font-bold text-text-primary">{entry.time ?? 'Dia todo'}</p>
      </div>
      <div className={['flex h-9 w-9 shrink-0 items-center justify-center rounded-xl', classes.bgSoft, classes.text].join(' ')}>
        <Icon size={16} strokeWidth={2.1} />
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-[15px] font-medium text-text-primary">{entry.title}</p>
        {entry.subtitle && <p className="truncate text-xs text-text-secondary">{entry.subtitle}</p>}
      </div>
    </button>
  )
}

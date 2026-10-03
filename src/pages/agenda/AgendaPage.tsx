import { useMemo, useState } from 'react'
import { Search } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { addDays } from 'date-fns'
import { toISODate } from '../../lib/date-utils'
import { formatAgendaGroupLabel, formatDayMonthLong } from '../../lib/format'
import { useAgendaEntries, type AgendaEntryType } from '../../hooks/useAgendaEntries'
import { AgendaItem } from '../../components/appointments/AgendaItem'
import { FilterChip } from '../../components/ui/FilterChip'
import { EmptyState } from '../../components/ui/EmptyState'

const FILTERS: { value: 'ALL' | AgendaEntryType; label: string }[] = [
  { value: 'ALL', label: 'Tudo' },
  { value: 'APPOINTMENT', label: 'Compromissos' },
  { value: 'SERVICE', label: 'Serviço' },
  { value: 'EXTRA', label: 'Extras' },
]

export function AgendaPage() {
  const navigate = useNavigate()
  const today = useMemo(() => new Date(), [])
  const rangeEnd = useMemo(() => addDays(today, 60), [today])

  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState<'ALL' | AgendaEntryType>('ALL')

  const entries = useAgendaEntries(toISODate(today), toISODate(rangeEnd))

  const filtered = useMemo(() => {
    return entries.filter((e) => {
      if (filter !== 'ALL' && e.type !== filter) return false
      if (search && !e.title.toLowerCase().includes(search.toLowerCase())) return false
      return true
    })
  }, [entries, filter, search])

  const groups = useMemo(() => {
    const map = new Map<string, typeof filtered>()
    filtered.forEach((entry) => {
      if (!map.has(entry.date)) map.set(entry.date, [])
      map.get(entry.date)!.push(entry)
    })
    return [...map.entries()]
  }, [filtered])

  return (
    <div className="flex flex-col gap-5 px-5 pt-[calc(env(safe-area-inset-top)+16px)]">
      <h1 className="text-xl font-bold text-text-primary">Agenda</h1>

      <div className="relative">
        <Search size={17} className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-text-muted" />
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Buscar compromissos..."
          className="w-full rounded-2xl border border-border/70 bg-surface-secondary py-3 pl-11 pr-4 text-[15px] text-text-primary placeholder:text-text-muted focus:border-primary focus:outline-none"
        />
      </div>

      <div className="flex gap-2 overflow-x-auto">
        {FILTERS.map((f) => (
          <FilterChip key={f.value} label={f.label} active={filter === f.value} onClick={() => setFilter(f.value)} />
        ))}
      </div>

      {groups.length === 0 ? (
        <EmptyState icon="SearchX" title="Nada encontrado" description="Ajuste os filtros ou a busca." />
      ) : (
        <div className="flex flex-col gap-5">
          {groups.map(([date, dateEntries]) => {
            const dateObj = new Date(`${date}T00:00:00`)
            return (
              <div key={date}>
                <p className="mb-1.5 text-sm font-semibold text-text-secondary">
                  {formatAgendaGroupLabel(dateObj, today)} • {formatDayMonthLong(dateObj)}
                </p>
                <div className="flex flex-col divide-y divide-divider rounded-2xl bg-surface px-2">
                  {dateEntries.map((entry) => (
                    <AgendaItem key={entry.id} entry={entry} onClick={() => navigate(`/dia/${date}`)} />
                  ))}
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

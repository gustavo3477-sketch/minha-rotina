import { Bell, Menu, Plus } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useAppStore } from '../../store/appStore'
import { useDayResolution, useEngineOptions } from '../../hooks/useSchedule'
import { useAgendaEntries } from '../../hooks/useAgendaEntries'
import { addDays, differenceInCalendarDays, fromISODate, toISODate } from '../../lib/date-utils'
import { formatDayMonthLong, formatGreeting, formatWeekdayLong } from '../../lib/format'
import { StatusCard } from '../../components/schedule/StatusCard'
import { AgendaItem } from '../../components/appointments/AgendaItem'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { EmptyState } from '../../components/ui/EmptyState'
import { findNextDayByClassification, resolveDay } from '../../lib/schedule-engine'
import { useMemo } from 'react'

export function TodayPage() {
  const navigate = useNavigate()
  const userName = useAppStore((s) => s.userName)
  const today = useMemo(() => new Date(), [])
  const todayIso = toISODate(today)

  const todayResolution = useDayResolution(todayIso)
  const todayEntries = useAgendaEntries(todayIso, todayIso)
  const engineOptions = useEngineOptions()

  const tomorrowResolution = useMemo(() => {
    if (!engineOptions.dayTypes.length) return null
    return resolveDay(addDays(today, 1), engineOptions)
  }, [today, engineOptions])

  const nextRestDay = useMemo(() => {
    if (!engineOptions.dayTypes.length) return null
    return findNextDayByClassification(addDays(today, 1), 'REST', engineOptions)
  }, [today, engineOptions])

  if (!todayResolution) {
    return <div className="px-5 pt-10 text-text-secondary">Carregando sua escala...</div>
  }

  const daysUntilNextRest = nextRestDay
    ? differenceInCalendarDays(fromISODate(nextRestDay.date), today)
    : null

  return (
    <div className="flex flex-col gap-5 px-5 pt-[calc(env(safe-area-inset-top)+16px)]">
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate('/mais')}
          aria-label="Menu"
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-surface text-text-primary active:opacity-70"
        >
          <Menu size={20} />
        </button>
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-xl font-bold text-text-primary">
            {formatGreeting()}, {userName}!
          </h1>
          <p className="truncate text-sm text-text-secondary">
            {formatWeekdayLong(today)}, {formatDayMonthLong(today)}
          </p>
        </div>
        <button
          onClick={() => navigate('/configuracoes/notificacoes')}
          aria-label="Notificações"
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-surface text-text-primary active:opacity-70"
        >
          <Bell size={19} />
        </button>
      </div>

      <StatusCard resolution={todayResolution} />

      <Card padding="lg" className="flex flex-col gap-1">
        <div className="mb-2 flex items-center gap-2">
          <h2 className="text-[15px] font-semibold text-text-primary">Compromissos de hoje</h2>
          <Badge token="primary">{todayEntries.length}</Badge>
        </div>

        {todayEntries.length === 0 ? (
          <EmptyState icon="CalendarX" title="Nenhum compromisso para hoje" />
        ) : (
          <div className="flex flex-col divide-y divide-divider">
            {todayEntries.map((entry) => (
              <AgendaItem key={entry.id} entry={entry} onClick={() => navigate(`/dia/${todayIso}`)} />
            ))}
          </div>
        )}

        <button
          onClick={() => navigate(`/novo-compromisso?date=${todayIso}`)}
          className="mt-3 flex items-center justify-center gap-1.5 rounded-2xl bg-primary/15 py-3 text-sm font-semibold text-primary active:bg-primary/25"
        >
          <Plus size={16} strokeWidth={2.5} />
          Novo compromisso
        </button>
      </Card>

      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={() => nextRestDay && navigate(`/dia/${nextRestDay.date}`)}
          className="rounded-3xl bg-off/15 p-4 text-left active:opacity-80"
        >
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-off">Próxima folga</p>
          {nextRestDay ? (
            <>
              <p className="text-[15px] font-bold text-text-primary">
                {formatWeekdayLong(fromISODate(nextRestDay.date))}
              </p>
              <p className="text-xs text-text-secondary">{formatDayMonthLong(fromISODate(nextRestDay.date))}</p>
              {daysUntilNextRest !== null && (
                <p className="mt-1 text-xs text-text-muted">
                  ({daysUntilNextRest} {daysUntilNextRest === 1 ? 'dia' : 'dias'})
                </p>
              )}
            </>
          ) : (
            <p className="text-sm text-text-secondary">—</p>
          )}
        </button>

        <button
          onClick={() => navigate(`/dia/${toISODate(addDays(today, 1))}`)}
          className="flex flex-col justify-between rounded-3xl bg-surface-elevated p-4 text-left active:opacity-80"
        >
          <p className="text-xs font-semibold uppercase tracking-wide text-text-muted">Amanhã</p>
          {tomorrowResolution && (
            <>
              <p className="mt-2 text-[15px] font-bold text-text-primary">{tomorrowResolution.label}</p>
              {tomorrowResolution.startTime && (
                <p className="text-xs text-text-secondary">
                  {tomorrowResolution.startTime} → {tomorrowResolution.endTime}
                </p>
              )}
            </>
          )}
        </button>
      </div>
    </div>
  )
}

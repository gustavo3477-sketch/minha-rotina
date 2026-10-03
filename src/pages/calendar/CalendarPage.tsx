import { useMemo, useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import {
  addMonths,
  eachDayOfInterval,
  endOfMonth,
  endOfWeek,
  isSameDay,
  isSameMonth,
  startOfMonth,
  startOfWeek,
} from 'date-fns'
import { useRangeResolution, useAppointmentsInRange } from '../../hooks/useSchedule'
import { toISODate } from '../../lib/date-utils'
import { formatMonthYear } from '../../lib/format'
import { CalendarDay } from '../../components/calendar/CalendarDay'
import { CalendarLegend } from '../../components/calendar/CalendarLegend'

const WEEKDAY_LABELS = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM']

export function CalendarPage() {
  const [monthCursor, setMonthCursor] = useState(() => startOfMonth(new Date()))
  const today = useMemo(() => new Date(), [])

  const gridStart = useMemo(() => startOfWeek(monthCursor, { weekStartsOn: 1 }), [monthCursor])
  const gridEnd = useMemo(
    () => endOfWeek(endOfMonth(monthCursor), { weekStartsOn: 1 }),
    [monthCursor],
  )
  const days = useMemo(() => eachDayOfInterval({ start: gridStart, end: gridEnd }), [gridStart, gridEnd])

  const startIso = toISODate(gridStart)
  const endIso = toISODate(gridEnd)
  const resolutions = useRangeResolution(startIso, endIso)
  const resolutionMap = useMemo(() => new Map(resolutions.map((r) => [r.date, r])), [resolutions])
  const appointmentsByDate = useAppointmentsInRange(startIso, endIso, 'APPOINTMENT')
  const extrasByDate = useAppointmentsInRange(startIso, endIso, 'EXTRA_SHIFT')

  return (
    <div className="flex flex-col gap-5 px-5 pt-[calc(env(safe-area-inset-top)+16px)]">
      <div className="flex items-center justify-between">
        <button
          onClick={() => setMonthCursor((m) => addMonths(m, -1))}
          className="flex h-9 w-9 items-center justify-center rounded-full bg-surface text-text-primary active:opacity-70"
          aria-label="Mês anterior"
        >
          <ChevronLeft size={18} />
        </button>
        <h1 className="text-lg font-bold text-text-primary">{formatMonthYear(monthCursor)}</h1>
        <button
          onClick={() => setMonthCursor((m) => addMonths(m, 1))}
          className="flex h-9 w-9 items-center justify-center rounded-full bg-surface text-text-primary active:opacity-70"
          aria-label="Próximo mês"
        >
          <ChevronRight size={18} />
        </button>
      </div>

      <button
        onClick={() => setMonthCursor(startOfMonth(new Date()))}
        className="self-center rounded-full bg-surface-elevated px-5 py-1.5 text-xs font-semibold text-text-primary active:opacity-70"
      >
        Hoje
      </button>

      <div className="grid grid-cols-7 gap-1.5">
        {WEEKDAY_LABELS.map((label) => (
          <div key={label} className="text-center text-[10px] font-bold text-text-muted">
            {label}
          </div>
        ))}
        {days.map((day) => {
          const iso = toISODate(day)
          return (
            <CalendarDay
              key={iso}
              date={day}
              resolution={resolutionMap.get(iso) ?? null}
              inCurrentMonth={isSameMonth(day, monthCursor)}
              isToday={isSameDay(day, today)}
              hasAppointments={(appointmentsByDate.get(iso)?.length ?? 0) > 0}
              hasExtra={(extrasByDate.get(iso)?.length ?? 0) > 0}
            />
          )
        })}
      </div>

      <CalendarLegend />
    </div>
  )
}

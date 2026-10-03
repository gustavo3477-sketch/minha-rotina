import { useMemo } from 'react'
import { eachDayOfInterval, endOfMonth, endOfWeek, isSameDay, isSameMonth, startOfMonth, startOfWeek } from 'date-fns'
import { resolveRange } from '../../lib/schedule-engine'
import { toISODate } from '../../lib/date-utils'
import { formatMonthYear } from '../../lib/format'
import type { DayType, ScheduleVersion } from '../../types'

const WEEKDAY_LABELS = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']

export function OnboardingCalendarPreview({
  version,
  dayTypes,
}: {
  version: ScheduleVersion
  dayTypes: DayType[]
}) {
  const today = useMemo(() => new Date(), [])
  const monthCursor = useMemo(() => startOfMonth(today), [today])
  const gridStart = useMemo(() => startOfWeek(monthCursor, { weekStartsOn: 1 }), [monthCursor])
  const gridEnd = useMemo(() => endOfWeek(endOfMonth(monthCursor), { weekStartsOn: 1 }), [monthCursor])
  const days = useMemo(() => eachDayOfInterval({ start: gridStart, end: gridEnd }), [gridStart, gridEnd])

  const resolutions = useMemo(() => {
    try {
      return resolveRange(gridStart, gridEnd, { versions: [version], dayTypes, exceptions: [] })
    } catch {
      return []
    }
  }, [gridStart, gridEnd, version, dayTypes])
  const resolutionMap = useMemo(() => new Map(resolutions.map((r) => [r.date, r])), [resolutions])

  return (
    <div className="rounded-3xl bg-surface p-4">
      <p className="mb-3 text-center text-sm font-semibold text-text-primary">{formatMonthYear(monthCursor)}</p>
      <div className="grid grid-cols-7 gap-1">
        {WEEKDAY_LABELS.map((label, i) => (
          <div key={i} className="text-center text-[10px] font-bold text-text-muted">
            {label}
          </div>
        ))}
        {days.map((day) => {
          const iso = toISODate(day)
          const resolution = resolutionMap.get(iso)
          const inMonth = isSameMonth(day, monthCursor)
          const isToday = isSameDay(day, today)
          let fillClass = 'bg-surface-secondary text-text-muted'
          if (inMonth && resolution) {
            fillClass = resolution.dayType.classification === 'WORK' ? 'bg-work text-white' : 'bg-off text-white'
          }
          return (
            <div
              key={iso}
              className={[
                'flex aspect-square items-center justify-center rounded-lg text-[11px] font-bold',
                fillClass,
                inMonth ? 'opacity-100' : 'opacity-30',
                isToday ? 'ring-2 ring-primary' : '',
              ].join(' ')}
            >
              {day.getDate()}
            </div>
          )
        })}
      </div>
    </div>
  )
}

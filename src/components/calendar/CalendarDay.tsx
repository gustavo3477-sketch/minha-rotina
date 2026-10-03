import { useNavigate } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import type { DayResolution } from '../../types'
import { toISODate } from '../../lib/date-utils'
import { resolveDayColor } from '../../lib/color'

interface CalendarDayProps {
  date: Date
  resolution: DayResolution | null
  inCurrentMonth: boolean
  isToday: boolean
  hasAppointments: boolean
  hasExtra: boolean
}

function shortLabel(resolution: DayResolution, isSunday: boolean): string {
  // Marcação manual sempre tem prioridade visual — inclusive sobre o "DOM" fixo.
  if (resolution.isException) {
    return resolution.dayType.displayName.slice(0, 7).toUpperCase()
  }
  if (isSunday) return 'DOM'
  if (resolution.dayType.classification === 'WORK') return 'SERV'
  if (resolution.dayType.classification === 'REST') return 'FOLGA'
  return resolution.dayType.displayName.slice(0, 7).toUpperCase()
}

export function CalendarDay({
  date,
  resolution,
  inCurrentMonth,
  isToday,
  hasAppointments,
  hasExtra,
}: CalendarDayProps) {
  const navigate = useNavigate()
  const dayNumber = date.getDate()
  const isSunday = date.getDay() === 0

  const showColor = inCurrentMonth && resolution
  const { background, text } = showColor
    ? resolveDayColor(resolution.dayType.color)
    : { background: undefined, text: undefined }
  const label = showColor ? shortLabel(resolution, isSunday) : ''

  return (
    <button
      type="button"
      onClick={() => navigate(`/dia/${toISODate(date)}`)}
      className={[
        'relative flex aspect-square w-full flex-col items-center justify-center gap-0.5 rounded-2xl px-0.5 transition-opacity',
        showColor ? '' : 'bg-surface-secondary text-text-muted',
        inCurrentMonth ? 'opacity-100' : 'opacity-40',
        isToday ? 'ring-2 ring-primary ring-offset-2 ring-offset-background' : '',
      ].join(' ')}
      style={showColor ? { backgroundColor: background, color: text } : undefined}
    >
      <span className={['text-[13px] font-bold leading-none', !inCurrentMonth ? 'text-text-muted' : ''].join(' ')}>
        {dayNumber}
      </span>
      {label && <span className="max-w-full truncate px-0.5 text-[8px] font-bold leading-none tracking-wide">{label}</span>}
      {showColor && resolution!.isException && (
        <span
          className="absolute right-1 top-1 opacity-70"
          title="Marcação manual"
          style={{ color: text }}
        >
          <Pencil size={8} strokeWidth={3} />
        </span>
      )}
      {(hasAppointments || hasExtra) && (
        <div className="absolute bottom-1 flex items-center gap-0.5">
          {hasAppointments && <span className="h-1 w-1 rounded-full bg-appointment" />}
          {hasExtra && <span className="h-1 w-1 rounded-full bg-extra" />}
        </div>
      )}
    </button>
  )
}

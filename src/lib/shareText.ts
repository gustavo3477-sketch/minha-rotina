import type { Appointment, DayResolution } from '../types'
import { fromISODate } from './date-utils'
import { formatDayMonthYearLong, formatWeekdayLong } from './format'

export interface ShareOptions {
  onlyWorkDays: boolean
  includeExtras: boolean
  includeAppointments: boolean
  includeNotes: boolean
}

export function buildShareText(
  resolutions: DayResolution[],
  appointmentsByDate: Map<string, Appointment[]>,
  extrasByDate: Map<string, Appointment[]>,
  notes: Record<string, string>,
  options: ShareOptions,
): string {
  const lines: string[] = ['MINHA ROTINA', '']

  resolutions.forEach((r) => {
    if (options.onlyWorkDays && r.dayType.classification !== 'WORK') return
    const date = fromISODate(r.date)
    lines.push(`${formatWeekdayLong(date)}, ${formatDayMonthYearLong(date)}`)
    lines.push(
      r.startTime && r.endTime ? `${r.label}: ${r.startTime} - ${r.endTime}` : r.label,
    )

    if (options.includeExtras) {
      const extras = extrasByDate.get(r.date) ?? []
      extras.forEach((e) => lines.push(`+ Extra: ${e.startTime}-${e.endTime} ${e.title}`))
    }

    if (options.includeAppointments) {
      const appts = appointmentsByDate.get(r.date) ?? []
      appts.forEach((a) => lines.push(`• ${a.allDay ? 'Dia todo' : a.startTime} ${a.title}`))
    }

    if (options.includeNotes && notes[r.date]) {
      lines.push(`Obs.: ${notes[r.date]}`)
    }

    lines.push('')
  })

  return lines.join('\n').trim()
}

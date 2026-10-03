import { addDays, addMonths, addWeeks, addYears } from 'date-fns'
import type { Appointment } from '../types'
import { fromISODate, toISODate } from './date-utils'

/** Gera as datas (ISO) em que um compromisso recorrente ocorre dentro do intervalo informado. */
export function getOccurrencesInRange(
  appointment: Appointment,
  rangeStart: Date,
  rangeEnd: Date,
): string[] {
  const { recurrence } = appointment
  const startDate = fromISODate(appointment.date)
  const until = recurrence.until ? fromISODate(recurrence.until) : undefined
  const effectiveEnd = until && until < rangeEnd ? until : rangeEnd

  if (recurrence.frequency === 'NONE') {
    return startDate >= rangeStart && startDate <= rangeEnd ? [appointment.date] : []
  }

  if (startDate > effectiveEnd) return []

  const interval = Math.max(1, recurrence.interval ?? 1)
  const step = (date: Date): Date => {
    switch (recurrence.frequency) {
      case 'DAILY':
        return addDays(date, interval)
      case 'WEEKLY':
        return addWeeks(date, interval)
      case 'BIWEEKLY':
        return addWeeks(date, 2)
      case 'MONTHLY':
        return addMonths(date, interval)
      case 'YEARLY':
        return addYears(date, interval)
      case 'CUSTOM':
        return addDays(date, interval)
      default:
        return addDays(date, interval)
    }
  }

  const occurrences: string[] = []
  let cursor = startDate
  let count = 0
  const maxCount = recurrence.count ?? Infinity
  const hardCap = 730 // trava de segurança para não gerar ocorrências indefinidamente

  while (cursor <= effectiveEnd && count < maxCount && occurrences.length < hardCap) {
    if (cursor >= rangeStart) {
      occurrences.push(toISODate(cursor))
    }
    count++
    cursor = step(cursor)
  }

  return occurrences
}

export function isAppointmentOnDate(appointment: Appointment, dateIso: string): boolean {
  const date = fromISODate(dateIso)
  return getOccurrencesInRange(appointment, date, date).length > 0
}

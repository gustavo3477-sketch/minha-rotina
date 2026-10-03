import { differenceInCalendarDays, format } from 'date-fns'
import { ptBR } from 'date-fns/locale'

export function capitalize(text: string): string {
  return text.charAt(0).toUpperCase() + text.slice(1)
}

export function formatWeekdayLong(date: Date): string {
  return capitalize(format(date, 'EEEE', { locale: ptBR }))
}

export function formatWeekdayShort(date: Date): string {
  return capitalize(format(date, 'EEE', { locale: ptBR })).replace('.', '')
}

export function formatDayMonthLong(date: Date): string {
  return format(date, "d 'de' MMMM", { locale: ptBR })
}

export function formatDayMonthYearLong(date: Date): string {
  return format(date, "d 'de' MMMM 'de' yyyy", { locale: ptBR })
}

export function formatMonthYear(date: Date): string {
  return capitalize(format(date, 'MMMM yyyy', { locale: ptBR }))
}

export function formatAgendaGroupLabel(date: Date, today: Date): string {
  const diffDays = differenceInCalendarDays(date, today)
  if (diffDays === 0) return 'Hoje'
  if (diffDays === 1) return 'Amanhã'
  return capitalize(format(date, 'EEEE', { locale: ptBR })).replace('-feira', '')
}

export function formatGreeting(date: Date = new Date()): string {
  const hour = date.getHours()
  if (hour < 12) return 'Bom dia'
  if (hour < 18) return 'Boa tarde'
  return 'Boa noite'
}

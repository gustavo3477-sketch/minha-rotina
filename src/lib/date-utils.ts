import { addDays, differenceInCalendarDays, format, isSameDay, parseISO } from 'date-fns'

export const ISO_FORMAT = 'yyyy-MM-dd'

export function toISODate(date: Date): string {
  return format(date, ISO_FORMAT)
}

export function fromISODate(iso: string): Date {
  return parseISO(iso)
}

export function mod(n: number, m: number): number {
  return ((n % m) + m) % m
}

export { addDays, differenceInCalendarDays, isSameDay }

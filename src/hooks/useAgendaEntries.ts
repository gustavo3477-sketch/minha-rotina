import { useMemo } from 'react'
import { useAppStore } from '../store/appStore'
import { useAppointmentsInRange, useRangeResolution } from './useSchedule'

export type AgendaEntryType = 'APPOINTMENT' | 'EXTRA' | 'SERVICE'

export interface AgendaEntry {
  id: string
  date: string
  time?: string
  endTime?: string
  title: string
  subtitle?: string
  icon: string
  token: string
  type: AgendaEntryType
}

export function useAgendaEntries(startIso: string, endIso: string): AgendaEntry[] {
  const categories = useAppStore((s) => s.categories)
  const appointmentsByDate = useAppointmentsInRange(startIso, endIso, 'APPOINTMENT')
  const extrasByDate = useAppointmentsInRange(startIso, endIso, 'EXTRA_SHIFT')
  const resolutions = useRangeResolution(startIso, endIso)
  const categoryMap = useMemo(() => new Map(categories.map((c) => [c.id, c])), [categories])

  return useMemo(() => {
    const entries: AgendaEntry[] = []

    appointmentsByDate.forEach((list, date) => {
      list.forEach((a) => {
        const category = categoryMap.get(a.categoryId ?? '')
        entries.push({
          id: `${a.id}-${date}`,
          date,
          time: a.allDay ? undefined : a.startTime,
          endTime: a.endTime,
          title: a.title,
          subtitle: a.location,
          icon: category?.icon ?? 'CalendarClock',
          token: category?.color ?? 'appointment',
          type: 'APPOINTMENT',
        })
      })
    })

    extrasByDate.forEach((list, date) => {
      list.forEach((a) => {
        entries.push({
          id: `${a.id}-${date}`,
          date,
          time: a.startTime,
          endTime: a.endTime,
          title: a.title || 'Serviço extra',
          icon: 'Zap',
          token: 'extra',
          type: 'EXTRA',
        })
      })
    })

    resolutions.forEach((r) => {
      if (r.dayType.classification === 'WORK' && r.startTime) {
        entries.push({
          id: `service-${r.date}`,
          date: r.date,
          time: r.startTime,
          endTime: r.endTime,
          title: 'Início do serviço',
          icon: r.dayType.icon,
          token: 'work',
          type: 'SERVICE',
        })
      }
    })

    return entries.sort((a, b) => {
      if (a.date !== b.date) return a.date.localeCompare(b.date)
      return (a.time ?? '').localeCompare(b.time ?? '')
    })
  }, [appointmentsByDate, extrasByDate, resolutions, categoryMap])
}

import { useMemo } from 'react'
import { useAppStore } from '../store/appStore'
import { resolveDay, resolveRange } from '../lib/schedule-engine'
import { fromISODate } from '../lib/date-utils'
import { getOccurrencesInRange } from '../lib/recurrence'
import type { Appointment, DayResolution } from '../types'

function useEngineInputs() {
  const dayTypes = useAppStore((s) => s.dayTypes)
  const scheduleVersions = useAppStore((s) => s.scheduleVersions)
  const scheduleExceptions = useAppStore((s) => s.scheduleExceptions)
  return { dayTypes, scheduleVersions, scheduleExceptions }
}

/** Expõe {versions, dayTypes, exceptions} prontos para chamadas ad-hoc do motor de escala. */
export function useEngineOptions() {
  const { dayTypes, scheduleVersions, scheduleExceptions } = useEngineInputs()
  return useMemo(
    () => ({ versions: scheduleVersions, dayTypes, exceptions: scheduleExceptions }),
    [scheduleVersions, dayTypes, scheduleExceptions],
  )
}

export function useDayResolution(dateIso: string): DayResolution | null {
  const { dayTypes, scheduleVersions, scheduleExceptions } = useEngineInputs()
  return useMemo(() => {
    if (dayTypes.length === 0 || scheduleVersions.length === 0) return null
    return resolveDay(fromISODate(dateIso), {
      versions: scheduleVersions,
      dayTypes,
      exceptions: scheduleExceptions,
    })
  }, [dateIso, dayTypes, scheduleVersions, scheduleExceptions])
}

export function useRangeResolution(startIso: string, endIso: string): DayResolution[] {
  const { dayTypes, scheduleVersions, scheduleExceptions } = useEngineInputs()
  return useMemo(() => {
    if (dayTypes.length === 0 || scheduleVersions.length === 0) return []
    return resolveRange(fromISODate(startIso), fromISODate(endIso), {
      versions: scheduleVersions,
      dayTypes,
      exceptions: scheduleExceptions,
    })
  }, [startIso, endIso, dayTypes, scheduleVersions, scheduleExceptions])
}

function sortByTime(a: Appointment, b: Appointment) {
  if (a.allDay && !b.allDay) return -1
  if (!a.allDay && b.allDay) return 1
  return (a.startTime ?? '').localeCompare(b.startTime ?? '')
}

export function useAppointmentsForDate(dateIso: string, kind: Appointment['kind'] = 'APPOINTMENT') {
  const appointments = useAppStore((s) => s.appointments)
  return useMemo(() => {
    const date = fromISODate(dateIso)
    return appointments
      .filter((a) => a.kind === kind)
      .filter((a) => getOccurrencesInRange(a, date, date).length > 0)
      .sort(sortByTime)
  }, [appointments, dateIso, kind])
}

export function useAppointmentsInRange(
  startIso: string,
  endIso: string,
  kind?: Appointment['kind'],
) {
  const appointments = useAppStore((s) => s.appointments)
  return useMemo(() => {
    const start = fromISODate(startIso)
    const end = fromISODate(endIso)
    const map = new Map<string, Appointment[]>()
    appointments
      .filter((a) => !kind || a.kind === kind)
      .forEach((a) => {
        const occurrences = getOccurrencesInRange(a, start, end)
        occurrences.forEach((iso) => {
          if (!map.has(iso)) map.set(iso, [])
          map.get(iso)!.push(a)
        })
      })
    map.forEach((list) => list.sort(sortByTime))
    return map
  }, [appointments, startIso, endIso, kind])
}

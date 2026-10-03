import type {
  CyclePosition,
  DayResolution,
  DayType,
  ScheduleException,
  ScheduleVersion,
} from '../types'
import { addDays, differenceInCalendarDays, fromISODate, isSameDay, mod, toISODate } from './date-utils'

/**
 * Motor de cálculo da escala.
 *
 * Nada é persistido dia a dia: apenas a(s) ScheduleVersion (regra + data de
 * referência) e exceções pontuais. Qualquer data — passada ou futura — é
 * resolvida sob demanda a partir dessas regras.
 */

function countWeekdayOccurrences(start: Date, end: Date, weekday: number): number {
  const totalDays = differenceInCalendarDays(end, start) + 1
  if (totalDays <= 0) return 0
  const startWeekday = start.getDay()
  const shift = mod(weekday - startWeekday, 7)
  if (shift >= totalDays) return 0
  return Math.floor((totalDays - shift - 1) / 7) + 1
}

function countCountableDays(start: Date, end: Date, fixedWeekdays: Set<number>): number {
  if (start > end) return 0
  const totalDays = differenceInCalendarDays(end, start) + 1
  let fixedCount = 0
  for (const weekday of fixedWeekdays) {
    fixedCount += countWeekdayOccurrences(start, end, weekday)
  }
  return totalDays - fixedCount
}

/** Deslocamento (em dias "contáveis" do ciclo) entre referenceDate e targetDate. */
export function computeCycleOffset(
  referenceDate: Date,
  targetDate: Date,
  fixedWeekdays: Set<number>,
): number {
  if (isSameDay(referenceDate, targetDate)) return 0
  if (targetDate > referenceDate) {
    return countCountableDays(addDays(referenceDate, 1), targetDate, fixedWeekdays)
  }
  return -countCountableDays(targetDate, addDays(referenceDate, -1), fixedWeekdays)
}

export function pickVersionForDate(
  versions: ScheduleVersion[],
  iso: string,
): ScheduleVersion | undefined {
  if (versions.length === 0) return undefined
  const sorted = [...versions].sort((a, b) => a.effectiveFrom.localeCompare(b.effectiveFrom))
  let candidate = sorted[0]
  for (const version of sorted) {
    if (version.effectiveFrom <= iso) candidate = version
    else break
  }
  return candidate
}

/** Dado um índice resolvido no ciclo, calcula "dia X de Y" olhando a sequência
 * contígua de posições com o mesmo tipo de dia (tratando o ciclo como circular). */
export function computeRunInfo(
  sortedPositions: CyclePosition[],
  index: number,
): { dayNumber: number; dayCount: number } {
  const n = sortedPositions.length
  if (n === 0) return { dayNumber: 1, dayCount: 1 }
  const dayTypeId = sortedPositions[index].dayTypeId
  const allSame = sortedPositions.every((p) => p.dayTypeId === dayTypeId)
  if (allSame) {
    return { dayNumber: index + 1, dayCount: n }
  }

  let start = index
  while (sortedPositions[mod(start - 1, n)].dayTypeId === dayTypeId) {
    start = mod(start - 1, n)
    if (start === index) break
  }

  let length = 0
  let i = start
  while (sortedPositions[i].dayTypeId === dayTypeId) {
    length++
    i = mod(i + 1, n)
    if (i === start) break
  }

  const dayNumber = mod(index - start, n) + 1
  return { dayNumber, dayCount: length }
}

export interface ResolveDayOptions {
  versions: ScheduleVersion[]
  dayTypes: DayType[]
  exceptions: ScheduleException[]
}

export function resolveDay(date: Date, options: ResolveDayOptions): DayResolution {
  const { versions, dayTypes, exceptions } = options
  const iso = toISODate(date)
  const dayTypeMap = new Map(dayTypes.map((dt) => [dt.id, dt]))

  const exception = exceptions.find((e) => e.date === iso)
  if (exception) {
    const dayType = dayTypeMap.get(exception.dayTypeId)
    if (!dayType) throw new Error(`Tipo de dia não encontrado: ${exception.dayTypeId}`)
    return {
      date: iso,
      dayType,
      label: dayType.displayName,
      startTime: exception.startTime,
      endTime: exception.endTime,
      isFixedDay: false,
      isException: true,
    }
  }

  const version = pickVersionForDate(versions, iso)
  if (!version) {
    throw new Error('Nenhuma configuração de escala encontrada para esta data.')
  }

  const weekday = date.getDay()
  const fixedRule = version.fixedDayRules.find((r) => r.weekday === weekday && r.enabled)
  if (fixedRule) {
    const dayType = dayTypeMap.get(fixedRule.dayTypeId)
    if (!dayType) throw new Error(`Tipo de dia não encontrado: ${fixedRule.dayTypeId}`)
    return {
      date: iso,
      dayType,
      label: dayType.displayName,
      isFixedDay: true,
      isException: false,
    }
  }

  const sorted = [...version.cyclePositions].sort((a, b) => a.order - b.order)
  const n = sorted.length
  if (n === 0) {
    throw new Error('O ciclo da escala não possui posições configuradas.')
  }

  const fixedWeekdays = new Set(
    version.fixedDayRules.filter((r) => r.enabled).map((r) => r.weekday),
  )
  const referenceDate = fromISODate(version.referenceDate)
  const offset = computeCycleOffset(referenceDate, date, fixedWeekdays)
  const index = mod(version.referencePositionIndex + offset, n)
  const position = sorted[index]
  const dayType = dayTypeMap.get(position.dayTypeId)
  if (!dayType) throw new Error(`Tipo de dia não encontrado: ${position.dayTypeId}`)
  const { dayNumber, dayCount } = computeRunInfo(sorted, index)

  return {
    date: iso,
    dayType,
    label: position.nameOverride || dayType.displayName,
    startTime: position.startTime,
    endTime: position.endTime,
    crossesMidnight: position.crossesMidnight,
    isFixedDay: false,
    isException: false,
    cyclePosition: position,
    cycleDayNumber: dayNumber,
    cycleDayCount: dayCount,
  }
}

/** Procura, a partir de (e incluindo) `from`, a próxima data cuja classificação bata com `classification`. */
export function findNextDayByClassification(
  from: Date,
  classification: DayResolution['dayType']['classification'],
  options: ResolveDayOptions,
  maxDays = 120,
): DayResolution | null {
  let cursor = from
  for (let i = 0; i < maxDays; i++) {
    const resolution = resolveDay(cursor, options)
    if (resolution.dayType.classification === classification) return resolution
    cursor = addDays(cursor, 1)
  }
  return null
}

/** Lista as próximas N datas (a partir de `from`, inclusive) que batem com `classification`. */
export function listUpcomingDaysByClassification(
  from: Date,
  classification: DayResolution['dayType']['classification'],
  count: number,
  options: ResolveDayOptions,
  maxDays = 365,
): DayResolution[] {
  const results: DayResolution[] = []
  let cursor = from
  for (let i = 0; i < maxDays && results.length < count; i++) {
    const resolution = resolveDay(cursor, options)
    if (resolution.dayType.classification === classification) results.push(resolution)
    cursor = addDays(cursor, 1)
  }
  return results
}

export function resolveRange(
  start: Date,
  end: Date,
  options: ResolveDayOptions,
): DayResolution[] {
  const days: DayResolution[] = []
  let cursor = start
  while (cursor <= end) {
    days.push(resolveDay(cursor, options))
    cursor = addDays(cursor, 1)
  }
  return days
}

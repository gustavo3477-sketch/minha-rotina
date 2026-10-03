import { createId } from './id'
import type { Category, DayType, ScheduleVersion } from '../types'

export const WORK_DAY_TYPE_ID = 'day-type-work'
export const OFF_DAY_TYPE_ID = 'day-type-off'
export const EXTRA_DAY_TYPE_ID = 'day-type-extra'
export const OTHER_DAY_TYPE_ID = 'day-type-other'

/** Tipos de dia essenciais que devem sempre existir (usados pela escala automática
 * e/ou oferecidos como marcação manual padrão). Cores em hex — mesma paleta visual
 * já aprovada (--color-work/--color-off) — para que a mudança de arquitetura não
 * altere a aparência atual do calendário. */
export function createCoreDayTypes(): DayType[] {
  return [
    {
      id: WORK_DAY_TYPE_ID,
      displayName: 'SERVIÇO',
      classification: 'WORK',
      color: '#ef5b57',
      icon: 'Briefcase',
      isCore: true,
    },
    {
      id: OFF_DAY_TYPE_ID,
      displayName: 'FOLGA',
      classification: 'REST',
      color: '#22c55e',
      icon: 'Leaf',
      isCore: true,
    },
    {
      id: EXTRA_DAY_TYPE_ID,
      displayName: 'SERVIÇO EXTRA',
      classification: 'MANUAL',
      color: '#3b82f6',
      icon: 'Zap',
      isCore: true,
    },
    {
      id: OTHER_DAY_TYPE_ID,
      displayName: 'OUTRO',
      classification: 'MANUAL',
      color: '#f97316',
      icon: 'Star',
      isCore: true,
    },
  ]
}

export function createDefaultDayTypes(): DayType[] {
  return createCoreDayTypes()
}

const CORE_ORDER: Record<string, number> = {
  [WORK_DAY_TYPE_ID]: 0,
  [OFF_DAY_TYPE_ID]: 1,
  [EXTRA_DAY_TYPE_ID]: 2,
  [OTHER_DAY_TYPE_ID]: 3,
}

/** Ordena tipos de dia para exibição: núcleo (Serviço, Folga, Serviço Extra,
 * Outro) primeiro nessa ordem fixa, depois categorias personalizadas por nome.
 * A ordem de armazenamento (chave do IndexedDB) não reflete essa prioridade. */
export function sortDayTypesForDisplay(dayTypes: DayType[]): DayType[] {
  return [...dayTypes].sort((a, b) => {
    const orderA = CORE_ORDER[a.id] ?? 100
    const orderB = CORE_ORDER[b.id] ?? 100
    if (orderA !== orderB) return orderA - orderB
    return a.displayName.localeCompare(b.displayName)
  })
}

export const CORE_DAY_TYPE_IDS = new Set([
  WORK_DAY_TYPE_ID,
  OFF_DAY_TYPE_ID,
  EXTRA_DAY_TYPE_ID,
  OTHER_DAY_TYPE_ID,
])

/** Retorna os tipos-núcleo que ainda não existem em `existing` (por id).
 * Usado para "curar" bancos já semeados antes desta funcionalidade existir,
 * sem sobrescrever cores que o usuário já tenha personalizado. */
export function getMissingCoreDayTypes(existing: DayType[]): DayType[] {
  const existingIds = new Set(existing.map((d) => d.id))
  return createCoreDayTypes().filter((dt) => !existingIds.has(dt.id))
}

/** Entre os tipos já existentes, os que são núcleo (Serviço/Folga/Serviço Extra/
 * Outro) mas ainda não têm `isCore: true` marcado — bancos semeados antes desse
 * campo existir. Precisam ser corrigidos para não ficarem excluíveis. */
export function getCoreDayTypesNeedingFlag(existing: DayType[]): DayType[] {
  return existing.filter((dt) => CORE_DAY_TYPE_IDS.has(dt.id) && !dt.isCore)
}

export function createDefaultCategories(): Category[] {
  return [
    { id: createId(), name: 'Saúde', color: 'special', icon: 'HeartPulse' },
    { id: createId(), name: 'Esporte', color: 'extra', icon: 'Dumbbell' },
    { id: createId(), name: 'Religião', color: 'appointment', icon: 'Church' },
    { id: createId(), name: 'Documentos', color: 'primary', icon: 'FileText' },
    { id: createId(), name: 'Geral', color: 'text-secondary', icon: 'MapPin' },
  ]
}

export interface Default2x2Params {
  referenceDate: string
  workStart: string
  workEnd: string
  crossesMidnight?: boolean
  workDayTypeId?: string
  offDayTypeId?: string
  effectiveFrom?: string
}

/** Cria a configuração padrão 2x2 com domingo como folga fixa fora da contagem. */
export function createDefault2x2Schedule(params: Default2x2Params): ScheduleVersion {
  const workDayTypeId = params.workDayTypeId ?? WORK_DAY_TYPE_ID
  const offDayTypeId = params.offDayTypeId ?? OFF_DAY_TYPE_ID

  return {
    id: createId(),
    name: 'Minha escala',
    effectiveFrom: params.effectiveFrom ?? params.referenceDate,
    referenceDate: params.referenceDate,
    referencePositionIndex: 0,
    cyclePositions: [
      {
        id: createId(),
        order: 1,
        dayTypeId: workDayTypeId,
        startTime: params.workStart,
        endTime: params.workEnd,
        crossesMidnight: params.crossesMidnight ?? params.workEnd < params.workStart,
      },
      {
        id: createId(),
        order: 2,
        dayTypeId: workDayTypeId,
        startTime: params.workStart,
        endTime: params.workEnd,
        crossesMidnight: params.crossesMidnight ?? params.workEnd < params.workStart,
      },
      {
        id: createId(),
        order: 3,
        dayTypeId: offDayTypeId,
      },
      {
        id: createId(),
        order: 4,
        dayTypeId: offDayTypeId,
      },
    ],
    fixedDayRules: [
      { weekday: 0, enabled: true, dayTypeId: offDayTypeId },
      { weekday: 1, enabled: false, dayTypeId: offDayTypeId },
      { weekday: 2, enabled: false, dayTypeId: offDayTypeId },
      { weekday: 3, enabled: false, dayTypeId: offDayTypeId },
      { weekday: 4, enabled: false, dayTypeId: offDayTypeId },
      { weekday: 5, enabled: false, dayTypeId: offDayTypeId },
      { weekday: 6, enabled: false, dayTypeId: offDayTypeId },
    ],
  }
}

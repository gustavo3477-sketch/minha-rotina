// Domínio: tipos compartilhados do Minha Rotina

export type DayClassification = 'WORK' | 'REST' | 'MANUAL'

export interface DayType {
  id: string
  displayName: string
  classification: DayClassification
  color: string // cor hexadecimal (#rrggbb); tokens antigos ('work','off',...) ainda são aceitos por compatibilidade
  icon: string // nome do ícone lucide
  isCore?: boolean // tipos essenciais (Serviço, Folga, Serviço Extra, Outro) não podem ser excluídos
}

export interface CyclePosition {
  id: string
  order: number // posição 1-based dentro do ciclo
  dayTypeId: string
  nameOverride?: string // ex: "SERVIÇO 1", "POSTO A", "DIURNO"
  startTime?: string // "13:00"
  endTime?: string // "01:00"
  crossesMidnight?: boolean
}

export interface FixedDayRule {
  weekday: number // 0 = domingo ... 6 = sábado
  enabled: boolean
  dayTypeId: string // tipo aplicado (ex: FOLGA fixa)
}

export interface ScheduleVersion {
  id: string
  name: string
  effectiveFrom: string // ISO yyyy-MM-dd — regra vale a partir desta data
  referenceDate: string // ISO yyyy-MM-dd — data âncora
  referencePositionIndex: number // posição (0-based) do ciclo na data âncora
  cyclePositions: CyclePosition[]
  fixedDayRules: FixedDayRule[]
}

export interface ScheduleException {
  id: string
  date: string // ISO yyyy-MM-dd
  dayTypeId: string
  startTime?: string
  endTime?: string
  reason?: string
  originalDayTypeId: string
}

export interface Category {
  id: string
  name: string
  color: string
  icon: string
}

export type RecurrenceFrequency =
  | 'NONE'
  | 'DAILY'
  | 'WEEKLY'
  | 'BIWEEKLY'
  | 'MONTHLY'
  | 'YEARLY'
  | 'CUSTOM'

export interface RecurrenceRule {
  frequency: RecurrenceFrequency
  interval?: number
  until?: string // ISO yyyy-MM-dd
  count?: number
}

export type AppointmentKind = 'APPOINTMENT' | 'EXTRA_SHIFT' | 'CHANGE'

export interface Appointment {
  id: string
  kind: AppointmentKind
  title: string
  date: string // ISO yyyy-MM-dd
  allDay: boolean
  startTime?: string
  endTime?: string
  categoryId?: string
  location?: string
  description?: string
  recurrence: RecurrenceRule
  reminderMinutesBefore?: number
  priority?: 'LOW' | 'NORMAL' | 'HIGH'
  createdAt: string
  updatedAt: string
}

export interface ExtraShift {
  id: string
  date: string
  startTime: string
  endTime: string
  note?: string
  createdAt: string
}

export interface DayResolution {
  date: string
  dayType: DayType
  label: string
  startTime?: string
  endTime?: string
  crossesMidnight?: boolean
  isFixedDay: boolean
  isException: boolean
  cyclePosition?: CyclePosition
  cycleDayNumber?: number // 1-based dentro do ciclo, ex: "Dia 1 de 2"
  cycleDayCount?: number // tamanho do bloco (ex.: 2 dias de trabalho)
}

export interface DayNote {
  date: string
  text: string
  updatedAt: string
}

export interface SyncMetadata {
  id: string
  lastSyncedAt?: string
  pendingChanges: number
}

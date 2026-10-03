import Dexie, { type Table } from 'dexie'
import type {
  Appointment,
  Category,
  DayNote,
  DayType,
  ScheduleException,
  ScheduleVersion,
  SyncMetadata,
} from '../types'

export class MinhaRotinaDB extends Dexie {
  dayTypes!: Table<DayType, string>
  scheduleVersions!: Table<ScheduleVersion, string>
  scheduleExceptions!: Table<ScheduleException, string>
  categories!: Table<Category, string>
  appointments!: Table<Appointment, string>
  dayNotes!: Table<DayNote, string>
  syncMetadata!: Table<SyncMetadata, string>

  constructor() {
    super('minha-rotina')
    this.version(1).stores({
      dayTypes: 'id',
      scheduleVersions: 'id, effectiveFrom',
      scheduleExceptions: 'id, date',
      categories: 'id',
      appointments: 'id, date, kind',
      dayNotes: 'date',
      syncMetadata: 'id',
    })
  }
}

export const db = new MinhaRotinaDB()

import { create } from 'zustand'
import { db } from '../lib/db'
import { createId } from '../lib/id'
import {
  createDefault2x2Schedule,
  createDefaultCategories,
  createDefaultDayTypes,
  getCoreDayTypesNeedingFlag,
  getMissingCoreDayTypes,
} from '../lib/default-data'
import { resolveDay } from '../lib/schedule-engine'
import { fromISODate } from '../lib/date-utils'
import { isHexColor, toHex } from '../lib/color'
import type {
  Appointment,
  Category,
  DayNote,
  DayType,
  ScheduleException,
  ScheduleVersion,
} from '../types'

interface AppState {
  isHydrated: boolean
  userName: string
  onboardingCompleted: boolean
  dayTypes: DayType[]
  categories: Category[]
  scheduleVersions: ScheduleVersion[]
  scheduleExceptions: ScheduleException[]
  appointments: Appointment[]
  dayNotes: Record<string, string>

  hydrate: () => Promise<void>
  setDayNote: (date: string, text: string) => Promise<void>

  setUserName: (name: string) => void
  completeOnboarding: () => void
  restartOnboarding: () => void

  addAppointment: (appointment: Appointment) => Promise<void>
  updateAppointment: (id: string, patch: Partial<Appointment>) => Promise<void>
  deleteAppointment: (id: string) => Promise<void>

  addScheduleVersion: (version: ScheduleVersion) => Promise<void>
  updateScheduleVersion: (id: string, patch: Partial<ScheduleVersion>) => Promise<void>

  addException: (exception: ScheduleException) => Promise<void>
  removeException: (id: string) => Promise<void>
  /** Aplica, troca ou remove (dayTypeId=null) a marcação manual de um dia,
   * sem nunca duplicar a exceção existente para a mesma data. */
  setDayMark: (date: string, dayTypeId: string | null, reason?: string) => Promise<void>

  addCategory: (category: Category) => Promise<void>
  updateCategory: (id: string, patch: Partial<Category>) => Promise<void>
  deleteCategory: (id: string) => Promise<void>
  addDayType: (dayType: DayType) => Promise<void>
  updateDayType: (id: string, patch: Partial<DayType>) => Promise<void>
  deleteDayType: (id: string) => Promise<void>
}

let seedPromise: Promise<void> | null = null

/** Garante que a semeadura inicial rode uma única vez mesmo se `hydrate()` for
 * chamado concorrentemente (ex.: dupla invocação de efeitos do StrictMode). */
function seedIfEmpty(): Promise<void> {
  if (!seedPromise) {
    seedPromise = seedDatabase()
  }
  return seedPromise
}

async function seedDatabase() {
  const dayTypeCount = await db.dayTypes.count()
  if (dayTypeCount > 0) return

  const dayTypes = createDefaultDayTypes()
  const categories = createDefaultCategories()
  const schedule = createDefault2x2Schedule({
    referenceDate: '2026-09-16',
    workStart: '13:00',
    workEnd: '01:00',
  })

  await db.dayTypes.bulkPut(dayTypes)
  await db.categories.bulkPut(categories)
  await db.scheduleVersions.put(schedule)
}

export const useAppStore = create<AppState>((set, get) => ({
  isHydrated: false,
  userName: 'Gustavo',
  onboardingCompleted: true,
  dayTypes: [],
  categories: [],
  scheduleVersions: [],
  scheduleExceptions: [],
  appointments: [],
  dayNotes: {},

  hydrate: async () => {
    try {
      await seedIfEmpty()
    } catch (error) {
      console.error('Falha ao semear dados iniciais', error)
    }
    const [loadedDayTypes, categories, scheduleVersions, scheduleExceptions, appointments, dayNotes] =
      await Promise.all([
        db.dayTypes.toArray(),
        db.categories.toArray(),
        db.scheduleVersions.toArray(),
        db.scheduleExceptions.toArray(),
        db.appointments.toArray(),
        db.dayNotes.toArray(),
      ])

    // Cura bancos semeados antes da funcionalidade de marcação manual existir:
    // adiciona (sem sobrescrever) os tipos-núcleo que ainda faltarem...
    const missingCoreDayTypes = getMissingCoreDayTypes(loadedDayTypes)
    if (missingCoreDayTypes.length > 0) {
      await db.dayTypes.bulkPut(missingCoreDayTypes)
    }
    // ...restaura isCore=true em núcleos salvos antes desse campo existir...
    const needsCoreFlag = new Set(getCoreDayTypesNeedingFlag(loadedDayTypes).map((dt) => dt.id))
    // ...e normaliza cores antigas (tokens como 'work'/'off') para hex real,
    // preservando a aparência exata (mesma cor, só muda a representação).
    const normalizedDayTypes = loadedDayTypes.map((dt) => {
      const needsHex = !isHexColor(dt.color)
      const needsCore = needsCoreFlag.has(dt.id)
      if (!needsHex && !needsCore) return dt
      return { ...dt, color: needsHex ? toHex(dt.color) : dt.color, isCore: needsCore ? true : dt.isCore }
    })
    const changed = normalizedDayTypes.filter((dt, i) => dt !== loadedDayTypes[i])
    if (changed.length > 0) {
      await db.dayTypes.bulkPut(changed)
    }
    const dayTypes = [...normalizedDayTypes, ...missingCoreDayTypes]

    const storedName = localStorage.getItem('minha-rotina:userName')
    const storedOnboarding = localStorage.getItem('minha-rotina:onboardingCompleted')
    set({
      dayTypes,
      categories,
      scheduleVersions,
      scheduleExceptions,
      appointments,
      dayNotes: Object.fromEntries(dayNotes.map((n) => [n.date, n.text])),
      userName: storedName ?? get().userName,
      onboardingCompleted: storedOnboarding ? storedOnboarding === 'true' : true,
      isHydrated: true,
    })
  },

  setDayNote: async (date, text) => {
    const note: DayNote = { date, text, updatedAt: new Date().toISOString() }
    await db.dayNotes.put(note)
    set({ dayNotes: { ...get().dayNotes, [date]: text } })
  },

  setUserName: (name) => {
    localStorage.setItem('minha-rotina:userName', name)
    set({ userName: name })
  },
  completeOnboarding: () => {
    localStorage.setItem('minha-rotina:onboardingCompleted', 'true')
    set({ onboardingCompleted: true })
  },
  restartOnboarding: () => {
    localStorage.setItem('minha-rotina:onboardingCompleted', 'false')
    set({ onboardingCompleted: false })
  },

  addAppointment: async (appointment) => {
    await db.appointments.add(appointment)
    set({ appointments: [...get().appointments, appointment] })
  },
  updateAppointment: async (id, patch) => {
    await db.appointments.update(id, patch)
    set({
      appointments: get().appointments.map((a) => (a.id === id ? { ...a, ...patch } : a)),
    })
  },
  deleteAppointment: async (id) => {
    await db.appointments.delete(id)
    set({ appointments: get().appointments.filter((a) => a.id !== id) })
  },

  addScheduleVersion: async (version) => {
    await db.scheduleVersions.add(version)
    set({ scheduleVersions: [...get().scheduleVersions, version] })
  },
  updateScheduleVersion: async (id, patch) => {
    await db.scheduleVersions.update(id, patch)
    set({
      scheduleVersions: get().scheduleVersions.map((v) => (v.id === id ? { ...v, ...patch } : v)),
    })
  },

  addException: async (exception) => {
    await db.scheduleExceptions.add(exception)
    set({ scheduleExceptions: [...get().scheduleExceptions, exception] })
  },
  removeException: async (id) => {
    await db.scheduleExceptions.delete(id)
    set({ scheduleExceptions: get().scheduleExceptions.filter((e) => e.id !== id) })
  },

  setDayMark: async (date, dayTypeId, reason) => {
    const existing = get().scheduleExceptions.find((e) => e.date === date)

    if (dayTypeId === null) {
      if (existing) await get().removeException(existing.id)
      return
    }

    if (existing) {
      await db.scheduleExceptions.update(existing.id, { dayTypeId, reason })
      set({
        scheduleExceptions: get().scheduleExceptions.map((e) =>
          e.id === existing.id ? { ...e, dayTypeId, reason } : e,
        ),
      })
      return
    }

    // originalDayTypeId guarda o que a escala automática determinaria para esta
    // data, calculado ignorando exceções — preserva a escala original intacta.
    const automatic = resolveDay(fromISODate(date), {
      versions: get().scheduleVersions,
      dayTypes: get().dayTypes,
      exceptions: [],
    })
    const exception: ScheduleException = {
      id: createId(),
      date,
      dayTypeId,
      reason,
      originalDayTypeId: automatic.dayType.id,
    }
    await get().addException(exception)
  },

  addCategory: async (category) => {
    await db.categories.add(category)
    set({ categories: [...get().categories, category] })
  },
  updateCategory: async (id, patch) => {
    await db.categories.update(id, patch)
    set({ categories: get().categories.map((c) => (c.id === id ? { ...c, ...patch } : c)) })
  },
  deleteCategory: async (id) => {
    await db.categories.delete(id)
    set({ categories: get().categories.filter((c) => c.id !== id) })
  },
  addDayType: async (dayType) => {
    await db.dayTypes.add(dayType)
    set({ dayTypes: [...get().dayTypes, dayType] })
  },
  updateDayType: async (id, patch) => {
    await db.dayTypes.update(id, patch)
    set({ dayTypes: get().dayTypes.map((dt) => (dt.id === id ? { ...dt, ...patch } : dt)) })
  },
  deleteDayType: async (id) => {
    const target = get().dayTypes.find((dt) => dt.id === id)
    if (target?.isCore) return
    await db.dayTypes.delete(id)
    set({ dayTypes: get().dayTypes.filter((dt) => dt.id !== id) })
  },
}))

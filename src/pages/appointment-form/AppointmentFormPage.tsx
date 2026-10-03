import { useMemo, useState } from 'react'
import { useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { Repeat, Bell as BellIcon } from 'lucide-react'
import { useAppStore } from '../../store/appStore'
import { createId } from '../../lib/id'
import { fromISODate, toISODate } from '../../lib/date-utils'
import { formatDayMonthYearLong } from '../../lib/format'
import { toast } from '../../store/toastStore'
import { AppHeader } from '../../components/layout/AppHeader'
import { EmptyState } from '../../components/ui/EmptyState'
import { Modal } from '../../components/ui/Modal'
import { SegmentedControl } from '../../components/ui/SegmentedControl'
import { FormField, TextArea, TextInput } from '../../components/ui/FormField'
import { Switch } from '../../components/ui/Switch'
import { TimePicker } from '../../components/ui/TimePicker'
import { SelectField } from '../../components/ui/SelectField'
import { BottomSheet } from '../../components/ui/BottomSheet'
import { OptionRow } from '../../components/ui/OptionRow'
import { IconBadge } from '../../components/ui/IconBadge'
import { PrimaryButton } from '../../components/ui/PrimaryButton'
import type { Appointment, AppointmentKind, RecurrenceFrequency } from '../../types'

const KIND_OPTIONS: { value: AppointmentKind; label: string }[] = [
  { value: 'APPOINTMENT', label: 'COMPROMISSO' },
  { value: 'EXTRA_SHIFT', label: 'SERVIÇO EXTRA' },
  { value: 'CHANGE', label: 'ALTERAÇÃO' },
]

const RECURRENCE_OPTIONS: { value: RecurrenceFrequency; label: string }[] = [
  { value: 'NONE', label: 'Não repetir' },
  { value: 'DAILY', label: 'Diariamente' },
  { value: 'WEEKLY', label: 'Semanalmente' },
  { value: 'BIWEEKLY', label: 'Quinzenalmente' },
  { value: 'MONTHLY', label: 'Mensalmente' },
  { value: 'YEARLY', label: 'Anualmente' },
  { value: 'CUSTOM', label: 'Personalizado' },
]

const REMINDER_OPTIONS: { value: number | null; label: string }[] = [
  { value: null, label: 'Nenhum' },
  { value: 0, label: 'No horário' },
  { value: 5, label: '5 minutos antes' },
  { value: 10, label: '10 minutos antes' },
  { value: 15, label: '15 minutos antes' },
  { value: 30, label: '30 minutos antes' },
  { value: 60, label: '1 hora antes' },
  { value: 1440, label: '1 dia antes' },
]

export function AppointmentFormPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const [searchParams] = useSearchParams()

  const categories = useAppStore((s) => s.categories)
  const dayTypes = useAppStore((s) => s.dayTypes)
  const appointments = useAppStore((s) => s.appointments)
  const addAppointment = useAppStore((s) => s.addAppointment)
  const updateAppointment = useAppStore((s) => s.updateAppointment)
  const deleteAppointment = useAppStore((s) => s.deleteAppointment)
  const setDayMark = useAppStore((s) => s.setDayMark)

  const editing = id ? appointments.find((a) => a.id === id) : undefined
  const initialKind = (searchParams.get('kind') as AppointmentKind | null) ?? editing?.kind ?? 'APPOINTMENT'
  const initialDate = searchParams.get('date') ?? editing?.date ?? toISODate(new Date())

  const [kind, setKind] = useState<AppointmentKind>(initialKind)
  const [title, setTitle] = useState(editing?.title ?? '')
  const [date, setDate] = useState(initialDate)
  const [allDay, setAllDay] = useState(editing?.allDay ?? false)
  const [startTime, setStartTime] = useState(editing?.startTime ?? '09:00')
  const [endTime, setEndTime] = useState(editing?.endTime ?? '10:00')
  const [categoryId, setCategoryId] = useState(editing?.categoryId ?? categories[0]?.id)
  const [location, setLocation] = useState(editing?.location ?? '')
  const [description, setDescription] = useState(editing?.description ?? '')
  const [recurrence, setRecurrence] = useState<RecurrenceFrequency>(editing?.recurrence.frequency ?? 'NONE')
  const [reminder, setReminder] = useState<number | null>(editing?.reminderMinutesBefore ?? null)
  const [changeDayTypeId, setChangeDayTypeId] = useState(dayTypes[0]?.id)
  const [changeReason, setChangeReason] = useState('')

  const [categorySheetOpen, setCategorySheetOpen] = useState(false)
  const [recurrenceSheetOpen, setRecurrenceSheetOpen] = useState(false)
  const [reminderSheetOpen, setReminderSheetOpen] = useState(false)
  const [dayTypeSheetOpen, setDayTypeSheetOpen] = useState(false)
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false)

  const selectedCategory = useMemo(() => categories.find((c) => c.id === categoryId), [categories, categoryId])
  const selectedDayType = useMemo(() => dayTypes.find((d) => d.id === changeDayTypeId), [dayTypes, changeDayTypeId])

  const titleByKind: Record<AppointmentKind, string> = {
    APPOINTMENT: editing ? 'Editar compromisso' : 'Novo compromisso',
    EXTRA_SHIFT: editing ? 'Editar serviço extra' : 'Novo serviço extra',
    CHANGE: 'Registrar alteração',
  }

  function handleSave() {
    if (kind === 'CHANGE') {
      if (!changeDayTypeId) return
      setDayMark(date, changeDayTypeId, changeReason || undefined)
      toast.success('Alteração registrada')
      navigate(-1)
      return
    }

    if (!title.trim()) return

    const base = {
      title: title.trim(),
      date,
      allDay,
      startTime: allDay ? undefined : startTime,
      endTime: allDay ? undefined : endTime,
      categoryId: kind === 'APPOINTMENT' ? categoryId : undefined,
      location: location.trim() || undefined,
      description: description.trim() || undefined,
      recurrence: { frequency: recurrence, interval: 1 },
      reminderMinutesBefore: reminder ?? undefined,
      priority: 'NORMAL' as const,
    }

    if (editing) {
      updateAppointment(editing.id, { ...base, updatedAt: new Date().toISOString() })
    } else {
      const appointment: Appointment = {
        id: createId(),
        kind,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        ...base,
      }
      addAppointment(appointment)
    }
    toast.success('Salvo')
    navigate(-1)
  }

  async function handleDelete() {
    if (!editing) return
    await deleteAppointment(editing.id)
    setDeleteConfirmOpen(false)
    toast.success('Compromisso excluído')
    navigate(-1)
  }

  if (id && !editing) {
    return (
      <div className="flex flex-col gap-5 pb-8">
        <AppHeader showBack title="Compromisso" />
        <div className="px-5">
          <EmptyState title="Compromisso não encontrado" description="Ele pode já ter sido excluído." />
        </div>
      </div>
    )
  }

  const isRecurring = !!editing && editing.recurrence.frequency !== 'NONE'

  return (
    <div className="flex flex-col gap-5 pb-8">
      <AppHeader showBack title={titleByKind[kind]} />

      <div className="flex flex-col gap-5 px-5">
        {!editing && (
          <SegmentedControl
            options={KIND_OPTIONS}
            value={kind}
            onChange={(v) => setKind(v as AppointmentKind)}
          />
        )}

        {isRecurring && editing && (
          <div className="rounded-2xl bg-surface px-4 py-3 text-xs text-text-secondary">
            Este compromisso se repete (começou em {formatDayMonthYearLong(fromISODate(editing.date))}). Alterar ou
            excluir vale para <span className="font-semibold text-text-primary">todas as repetições</span>. Para
            parar de repetir, mude "Repetição" para "Não repetir".
          </div>
        )}

        {kind === 'CHANGE' ? (
          <>
            <FormField label="Data">
              <TextInput type="date" value={date} onChange={(e) => setDate(e.target.value)} />
            </FormField>
            <FormField label="Nova situação neste dia">
              <SelectField
                value={selectedDayType?.displayName ?? ''}
                icon={selectedDayType && <IconBadge icon={selectedDayType.icon} token={selectedDayType.color} size="sm" />}
                onClick={() => setDayTypeSheetOpen(true)}
              />
            </FormField>
            <FormField label="Motivo">
              <TextArea
                rows={3}
                placeholder="Ex.: troca de plantão, férias, afastamento..."
                value={changeReason}
                onChange={(e) => setChangeReason(e.target.value)}
              />
            </FormField>
          </>
        ) : (
          <>
            <FormField label="Título">
              <TextInput
                placeholder="Ex.: Dentista"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
            </FormField>

            <div className="grid grid-cols-2 gap-3">
              <FormField label="Data">
                <TextInput type="date" value={date} onChange={(e) => setDate(e.target.value)} />
              </FormField>
              <FormField
                label="Dia inteiro"
                action={<Switch checked={allDay} onChange={setAllDay} label="Dia inteiro" />}
              >
                <div />
              </FormField>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <FormField label="Horário inicial">
                <TimePicker value={startTime} onChange={setStartTime} disabled={allDay} />
              </FormField>
              <FormField label="Horário final">
                <TimePicker value={endTime} onChange={setEndTime} disabled={allDay} />
              </FormField>
            </div>

            {kind === 'APPOINTMENT' && (
              <FormField label="Categoria">
                <SelectField
                  value={selectedCategory?.name ?? ''}
                  icon={
                    selectedCategory && (
                      <IconBadge icon={selectedCategory.icon} token={selectedCategory.color} size="sm" />
                    )
                  }
                  onClick={() => setCategorySheetOpen(true)}
                />
              </FormField>
            )}

            <FormField label="Local">
              <TextInput
                placeholder="Ex.: Clínica OdontoVida"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
              />
            </FormField>

            <FormField label="Descrição">
              <TextArea
                rows={3}
                placeholder="Adicione detalhes..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
              />
            </FormField>

            <FormField label="Repetição">
              <SelectField
                value={RECURRENCE_OPTIONS.find((o) => o.value === recurrence)?.label ?? ''}
                icon={<Repeat size={16} className="text-text-muted" />}
                onClick={() => setRecurrenceSheetOpen(true)}
              />
            </FormField>

            <FormField label="Lembrete">
              <SelectField
                value={REMINDER_OPTIONS.find((o) => o.value === reminder)?.label ?? 'Nenhum'}
                icon={<BellIcon size={16} className="text-text-muted" />}
                onClick={() => setReminderSheetOpen(true)}
              />
            </FormField>
          </>
        )}

        <PrimaryButton onClick={handleSave}>SALVAR</PrimaryButton>

        {editing && (
          <PrimaryButton variant="danger" onClick={() => setDeleteConfirmOpen(true)}>
            EXCLUIR
          </PrimaryButton>
        )}
      </div>

      <Modal open={deleteConfirmOpen} onClose={() => setDeleteConfirmOpen(false)} title="Excluir compromisso?">
        <p className="mb-4 text-sm text-text-secondary">
          “{editing?.title}” será excluído
          {isRecurring ? ', junto com todas as suas repetições' : ''}. Isso não pode ser desfeito.
        </p>
        <div className="flex gap-3">
          <PrimaryButton variant="secondary" onClick={() => setDeleteConfirmOpen(false)}>
            Cancelar
          </PrimaryButton>
          <PrimaryButton variant="danger" onClick={handleDelete}>
            Excluir
          </PrimaryButton>
        </div>
      </Modal>

      <BottomSheet open={categorySheetOpen} onClose={() => setCategorySheetOpen(false)} title="Categoria">
        <div className="flex flex-col">
          {categories.map((c) => (
            <OptionRow
              key={c.id}
              label={c.name}
              icon={<IconBadge icon={c.icon} token={c.color} size="sm" />}
              selected={c.id === categoryId}
              onClick={() => {
                setCategoryId(c.id)
                setCategorySheetOpen(false)
              }}
            />
          ))}
        </div>
      </BottomSheet>

      <BottomSheet open={recurrenceSheetOpen} onClose={() => setRecurrenceSheetOpen(false)} title="Repetição">
        <div className="flex flex-col">
          {RECURRENCE_OPTIONS.map((o) => (
            <OptionRow
              key={o.value}
              label={o.label}
              icon={<Repeat size={16} className="text-text-muted" />}
              selected={o.value === recurrence}
              onClick={() => {
                setRecurrence(o.value)
                setRecurrenceSheetOpen(false)
              }}
            />
          ))}
        </div>
      </BottomSheet>

      <BottomSheet open={reminderSheetOpen} onClose={() => setReminderSheetOpen(false)} title="Lembrete">
        <div className="flex flex-col">
          {REMINDER_OPTIONS.map((o) => (
            <OptionRow
              key={String(o.value)}
              label={o.label}
              icon={<BellIcon size={16} className="text-text-muted" />}
              selected={o.value === reminder}
              onClick={() => {
                setReminder(o.value)
                setReminderSheetOpen(false)
              }}
            />
          ))}
        </div>
      </BottomSheet>

      <BottomSheet open={dayTypeSheetOpen} onClose={() => setDayTypeSheetOpen(false)} title="Tipo de dia">
        <div className="flex flex-col">
          {dayTypes.map((dt) => (
            <OptionRow
              key={dt.id}
              label={dt.displayName}
              icon={<IconBadge icon={dt.icon} token={dt.color} size="sm" />}
              selected={dt.id === changeDayTypeId}
              onClick={() => {
                setChangeDayTypeId(dt.id)
                setDayTypeSheetOpen(false)
              }}
            />
          ))}
        </div>
      </BottomSheet>
    </div>
  )
}

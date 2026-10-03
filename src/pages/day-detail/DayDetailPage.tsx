import { useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Plus, RotateCcw, Settings } from 'lucide-react'
import { useAppStore } from '../../store/appStore'
import { useAppointmentsForDate, useDayResolution, useEngineOptions } from '../../hooks/useSchedule'
import { resolveDay } from '../../lib/schedule-engine'
import { sortDayTypesForDisplay } from '../../lib/default-data'
import { fromISODate } from '../../lib/date-utils'
import { formatDayMonthYearLong, formatWeekdayLong } from '../../lib/format'
import { AppHeader } from '../../components/layout/AppHeader'
import { StatusCard } from '../../components/schedule/StatusCard'
import { AppointmentCard } from '../../components/appointments/AppointmentCard'
import { Card } from '../../components/ui/Card'
import { EmptyState } from '../../components/ui/EmptyState'
import { TextArea, TextInput, FormField } from '../../components/ui/FormField'
import { BottomSheet } from '../../components/ui/BottomSheet'
import { OptionRow } from '../../components/ui/OptionRow'
import { IconBadge } from '../../components/ui/IconBadge'
import { ColorPickerSheet } from '../../components/ui/ColorPickerSheet'
import { PrimaryButton } from '../../components/ui/PrimaryButton'
import { createId } from '../../lib/id'
import { toast } from '../../store/toastStore'

export function DayDetailPage() {
  const { date } = useParams<{ date: string }>()
  const navigate = useNavigate()
  const iso = date!
  const dateObj = useMemo(() => fromISODate(iso), [iso])

  const categories = useAppStore((s) => s.categories)
  const dayTypes = useAppStore((s) => s.dayTypes)
  const dayNotes = useAppStore((s) => s.dayNotes)
  const setDayNote = useAppStore((s) => s.setDayNote)
  const setDayMark = useAppStore((s) => s.setDayMark)
  const addDayType = useAppStore((s) => s.addDayType)

  const resolution = useDayResolution(iso)
  const engineOptions = useEngineOptions()
  const appointments = useAppointmentsForDate(iso, 'APPOINTMENT')
  const extraShifts = useAppointmentsForDate(iso, 'EXTRA_SHIFT')

  const [noteDraft, setNoteDraft] = useState(dayNotes[iso] ?? '')
  const [markSheetOpen, setMarkSheetOpen] = useState(false)
  const [creatingCustom, setCreatingCustom] = useState(false)
  const [customName, setCustomName] = useState('')
  const [customColor, setCustomColor] = useState('#6b7280')
  const [customColorPickerOpen, setCustomColorPickerOpen] = useState(false)

  const categoryMap = useMemo(() => new Map(categories.map((c) => [c.id, c])), [categories])

  const automaticResolution = useMemo(() => {
    if (!engineOptions.dayTypes.length) return null
    return resolveDay(dateObj, { ...engineOptions, exceptions: [] })
  }, [dateObj, engineOptions])

  if (!resolution) return null

  function saveNote() {
    if (noteDraft !== (dayNotes[iso] ?? '')) {
      setDayNote(iso, noteDraft)
      toast.success('Salvo')
    }
  }

  function applyMark(dayTypeId: string) {
    setDayMark(iso, dayTypeId)
    setMarkSheetOpen(false)
    setCreatingCustom(false)
    toast.success('Dia marcado')
  }

  function removeMark() {
    setDayMark(iso, null)
    setMarkSheetOpen(false)
    toast.success('Marcação removida')
  }

  function createCustomAndApply() {
    if (!customName.trim()) return
    const newType = {
      id: createId(),
      displayName: customName.trim().toUpperCase(),
      classification: 'MANUAL' as const,
      color: customColor,
      icon: 'Star',
      isCore: false,
    }
    addDayType(newType)
    setDayMark(iso, newType.id)
    setMarkSheetOpen(false)
    setCreatingCustom(false)
    setCustomName('')
    toast.success('Categoria criada e aplicada')
  }

  return (
    <div className="flex flex-col gap-5 pb-6">
      <AppHeader
        showBack
        title={formatWeekdayLong(dateObj)}
        subtitle={formatDayMonthYearLong(dateObj)}
        trailing={
          <button
            onClick={() => setMarkSheetOpen(true)}
            aria-label="Marcar dia"
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-surface-elevated text-text-primary active:opacity-70"
          >
            <Settings size={18} />
          </button>
        }
      />

      <div className="px-5">
        <StatusCard resolution={resolution} />
        {resolution.isException && automaticResolution && (
          <button
            onClick={() => setMarkSheetOpen(true)}
            className="mt-2 flex w-full items-center justify-between rounded-2xl bg-surface px-4 py-2.5 text-left active:opacity-80"
          >
            <span className="text-xs text-text-secondary">
              Escala automática: <span className="font-semibold text-text-primary">{automaticResolution.label}</span>
            </span>
            <span className="text-xs font-semibold text-primary">Alterar</span>
          </button>
        )}
      </div>

      <Card padding="lg" className="mx-5">
        <div className="mb-2 flex items-center justify-between">
          <h2 className="text-[15px] font-semibold text-text-primary">
            Compromissos ({appointments.length})
          </h2>
          <button
            onClick={() => navigate(`/novo-compromisso?date=${iso}`)}
            aria-label="Novo compromisso"
            className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-white active:opacity-80"
          >
            <Plus size={16} strokeWidth={2.5} />
          </button>
        </div>
        {appointments.length === 0 ? (
          <EmptyState title="Nenhum compromisso" />
        ) : (
          <div className="flex flex-col divide-y divide-divider">
            {appointments.map((a) => (
              <AppointmentCard
                key={a.id}
                appointment={a}
                category={categoryMap.get(a.categoryId ?? '')}
                onClick={() => navigate(`/compromisso/${a.id}`)}
              />
            ))}
          </div>
        )}
      </Card>

      <Card padding="lg" className="mx-5">
        <div className="mb-2 flex items-center justify-between">
          <h2 className="text-[15px] font-semibold text-text-primary">Serviço extra</h2>
          <button
            onClick={() => navigate(`/novo-compromisso?date=${iso}&kind=EXTRA_SHIFT`)}
            aria-label="Novo serviço extra"
            className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-white active:opacity-80"
          >
            <Plus size={16} strokeWidth={2.5} />
          </button>
        </div>
        {extraShifts.length === 0 ? (
          <EmptyState title="Nenhum serviço extra" />
        ) : (
          <div className="flex flex-col divide-y divide-divider">
            {extraShifts.map((a) => (
              <AppointmentCard key={a.id} appointment={a} onClick={() => navigate(`/compromisso/${a.id}`)} />
            ))}
          </div>
        )}
      </Card>

      <Card padding="lg" className="mx-5">
        <h2 className="mb-2 text-[15px] font-semibold text-text-primary">Observações do dia</h2>
        <TextArea
          rows={3}
          placeholder="Adicione observação..."
          value={noteDraft}
          onChange={(e) => setNoteDraft(e.target.value)}
          onBlur={saveNote}
        />
      </Card>

      <BottomSheet
        open={markSheetOpen}
        onClose={() => {
          setMarkSheetOpen(false)
          setCreatingCustom(false)
        }}
        title="Marcar dia"
      >
        {!creatingCustom ? (
          <div className="flex flex-col gap-3">
            {automaticResolution && (
              <div className="flex items-center gap-3 rounded-2xl bg-surface-secondary px-3 py-3">
                <IconBadge icon={automaticResolution.dayType.icon} token={automaticResolution.dayType.color} size="sm" />
                <div>
                  <p className="text-xs text-text-muted">Marcação automática (escala)</p>
                  <p className="text-[15px] font-medium text-text-primary">{automaticResolution.label}</p>
                </div>
              </div>
            )}

            <div className="flex flex-col">
              {sortDayTypesForDisplay(dayTypes).map((dt) => (
                <OptionRow
                  key={dt.id}
                  label={dt.displayName}
                  icon={<IconBadge icon={dt.icon} token={dt.color} size="sm" />}
                  selected={resolution.dayType.id === dt.id && resolution.isException}
                  onClick={() => applyMark(dt.id)}
                />
              ))}
              <OptionRow
                label="Personalizado"
                description="Criar uma nova categoria de marcação"
                icon={<IconBadge icon="Star" token="#6b7280" size="sm" />}
                onClick={() => setCreatingCustom(true)}
              />
            </div>

            {resolution.isException && (
              <button
                onClick={removeMark}
                className="flex items-center justify-center gap-2 rounded-2xl bg-surface-secondary py-3 text-sm font-semibold text-text-primary active:opacity-80"
              >
                <RotateCcw size={15} />
                Remover marcação manual
              </button>
            )}
          </div>
        ) : (
          <div className="flex flex-col gap-4">
            <FormField label="Nome da categoria">
              <TextInput
                autoFocus
                placeholder="Ex.: Plantão"
                value={customName}
                onChange={(e) => setCustomName(e.target.value)}
              />
            </FormField>
            <FormField label="Cor">
              <button
                type="button"
                onClick={() => setCustomColorPickerOpen(true)}
                className="flex items-center gap-3 rounded-2xl border border-border/70 bg-surface-secondary px-4 py-3"
              >
                <span className="h-8 w-8 shrink-0 rounded-full" style={{ backgroundColor: customColor }} />
                <span className="text-[15px] text-text-primary">{customColor.toUpperCase()}</span>
              </button>
            </FormField>
            <div className="flex gap-3">
              <PrimaryButton variant="secondary" onClick={() => setCreatingCustom(false)}>
                Voltar
              </PrimaryButton>
              <PrimaryButton onClick={createCustomAndApply}>Criar e aplicar</PrimaryButton>
            </div>
          </div>
        )}
      </BottomSheet>

      <ColorPickerSheet
        open={customColorPickerOpen}
        value={customColor}
        onClose={() => setCustomColorPickerOpen(false)}
        onChange={setCustomColor}
      />
    </div>
  )
}

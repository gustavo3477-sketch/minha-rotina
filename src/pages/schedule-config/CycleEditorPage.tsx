import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronDown, ChevronUp, Palette, Pencil, Plus, Trash2 } from 'lucide-react'
import { useAppStore } from '../../store/appStore'
import { pickVersionForDate } from '../../lib/schedule-engine'
import { toISODate } from '../../lib/date-utils'
import { createId } from '../../lib/id'
import { toast } from '../../store/toastStore'
import { AppHeader } from '../../components/layout/AppHeader'
import { Card } from '../../components/ui/Card'
import { FormField, TextInput } from '../../components/ui/FormField'
import { TimePicker } from '../../components/ui/TimePicker'
import { SelectField } from '../../components/ui/SelectField'
import { BottomSheet } from '../../components/ui/BottomSheet'
import { OptionRow } from '../../components/ui/OptionRow'
import { IconBadge } from '../../components/ui/IconBadge'
import { PrimaryButton } from '../../components/ui/PrimaryButton'
import type { CyclePosition, DayType } from '../../types'

export function CycleEditorPage() {
  const navigate = useNavigate()
  const scheduleVersions = useAppStore((s) => s.scheduleVersions)
  const dayTypes = useAppStore((s) => s.dayTypes)
  const updateScheduleVersion = useAppStore((s) => s.updateScheduleVersion)

  const currentVersion = useMemo(
    () => pickVersionForDate(scheduleVersions, toISODate(new Date())),
    [scheduleVersions],
  )
  const dayTypeMap = useMemo(() => new Map(dayTypes.map((d) => [d.id, d])), [dayTypes])
  const sortedPositions = useMemo(
    () => (currentVersion ? [...currentVersion.cyclePositions].sort((a, b) => a.order - b.order) : []),
    [currentVersion],
  )

  const [editingPosition, setEditingPosition] = useState<CyclePosition | null>(null)
  const [dayTypePickerOpenFor, setDayTypePickerOpenFor] = useState(false)

  if (!currentVersion) return null

  function persistPositions(positions: CyclePosition[]) {
    const reordered = positions.map((p, i) => ({ ...p, order: i + 1 }))
    updateScheduleVersion(currentVersion!.id, { cyclePositions: reordered })
  }

  function movePosition(index: number, direction: -1 | 1) {
    const next = [...sortedPositions]
    const target = index + direction
    if (target < 0 || target >= next.length) return
    ;[next[index], next[target]] = [next[target], next[index]]
    persistPositions(next)
  }

  function removePosition(id: string) {
    if (sortedPositions.length <= 2) {
      toast.error('O ciclo precisa de ao menos 2 posições')
      return
    }
    persistPositions(sortedPositions.filter((p) => p.id !== id))
  }

  function addPosition() {
    const restType = dayTypes.find((d) => d.classification === 'REST') ?? dayTypes[0]
    const newPosition: CyclePosition = {
      id: createId(),
      order: sortedPositions.length + 1,
      dayTypeId: restType.id,
      nameOverride: 'Novo dia',
    }
    persistPositions([...sortedPositions, newPosition])
  }

  function savePosition(updated: CyclePosition) {
    persistPositions(sortedPositions.map((p) => (p.id === updated.id ? updated : p)))
    setEditingPosition(null)
    toast.success('Salvo')
  }

  return (
    <div className="flex flex-col gap-6 pb-8">
      <AppHeader showBack title="Meu ciclo" subtitle="Nomes, horários e tipos de cada dia" />

      <div className="flex flex-col gap-3 px-5">
        {sortedPositions.map((position, index) => {
          const dayType = dayTypeMap.get(position.dayTypeId)
          if (!dayType) return null
          return (
            <Card key={position.id} padding="md" className="flex items-center gap-3">
              <IconBadge icon={dayType.icon} token={dayType.color} />
              <div className="min-w-0 flex-1">
                <p className="text-[15px] font-semibold text-text-primary">
                  {index + 1}. {position.nameOverride || dayType.displayName}
                </p>
                <p className="truncate text-xs text-text-secondary">
                  {dayType.classification === 'WORK' ? 'Trabalho' : 'Descanso'}
                  {position.startTime && position.endTime ? ` • ${position.startTime}–${position.endTime}` : ''}
                </p>
              </div>
              <div className="flex flex-col">
                <button onClick={() => movePosition(index, -1)} className="p-1 text-text-muted active:text-text-primary">
                  <ChevronUp size={16} />
                </button>
                <button onClick={() => movePosition(index, 1)} className="p-1 text-text-muted active:text-text-primary">
                  <ChevronDown size={16} />
                </button>
              </div>
              <button
                onClick={() => setEditingPosition(position)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-surface-elevated text-text-primary active:opacity-70"
              >
                <Pencil size={14} />
              </button>
              <button
                onClick={() => removePosition(position.id)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-danger/15 text-danger active:opacity-70"
              >
                <Trash2 size={14} />
              </button>
            </Card>
          )
        })}

        <button
          onClick={addPosition}
          className="flex items-center justify-center gap-2 rounded-2xl border border-dashed border-border py-3 text-sm font-semibold text-primary active:bg-primary/10"
        >
          <Plus size={16} />
          Adicionar dia
        </button>

        <button
          onClick={() => navigate('/configuracoes/cores-calendario')}
          className="flex items-center justify-between rounded-2xl bg-surface-secondary px-4 py-3.5"
        >
          <span className="flex items-center gap-2 text-sm font-medium text-text-primary">
            <Palette size={16} className="text-primary" />
            Cores e categorias do calendário
          </span>
        </button>
      </div>

      {editingPosition && (
        <PositionEditorSheet
          position={editingPosition}
          dayTypes={dayTypes}
          onClose={() => setEditingPosition(null)}
          onSave={savePosition}
          dayTypePickerOpenFor={dayTypePickerOpenFor}
          setDayTypePickerOpenFor={setDayTypePickerOpenFor}
        />
      )}
    </div>
  )
}

function PositionEditorSheet({
  position,
  dayTypes,
  onClose,
  onSave,
  dayTypePickerOpenFor,
  setDayTypePickerOpenFor,
}: {
  position: CyclePosition
  dayTypes: DayType[]
  onClose: () => void
  onSave: (p: CyclePosition) => void
  dayTypePickerOpenFor: boolean
  setDayTypePickerOpenFor: (v: boolean) => void
}) {
  const [name, setName] = useState(position.nameOverride ?? '')
  const [dayTypeId, setDayTypeId] = useState(position.dayTypeId)
  const [startTime, setStartTime] = useState(position.startTime ?? '13:00')
  const [endTime, setEndTime] = useState(position.endTime ?? '01:00')
  const dayType = dayTypes.find((d) => d.id === dayTypeId)

  return (
    <BottomSheet open onClose={onClose} title="Editar dia do ciclo">
      <div className="flex flex-col gap-4">
        <FormField label="Nome">
          <TextInput value={name} onChange={(e) => setName(e.target.value)} placeholder="Ex.: Posto A" />
        </FormField>
        <FormField label="Tipo de dia">
          <SelectField
            value={dayType?.displayName ?? ''}
            icon={dayType && <IconBadge icon={dayType.icon} token={dayType.color} size="sm" />}
            onClick={() => setDayTypePickerOpenFor(true)}
          />
        </FormField>
        {dayType?.classification === 'WORK' && (
          <div className="grid grid-cols-2 gap-3">
            <FormField label="Horário inicial">
              <TimePicker value={startTime} onChange={setStartTime} />
            </FormField>
            <FormField label="Horário final">
              <TimePicker value={endTime} onChange={setEndTime} />
            </FormField>
          </div>
        )}
        <PrimaryButton
          onClick={() =>
            onSave({
              ...position,
              nameOverride: name || undefined,
              dayTypeId,
              startTime: dayType?.classification === 'WORK' ? startTime : undefined,
              endTime: dayType?.classification === 'WORK' ? endTime : undefined,
              crossesMidnight: dayType?.classification === 'WORK' ? endTime < startTime : undefined,
            })
          }
        >
          SALVAR
        </PrimaryButton>
      </div>

      <BottomSheet open={dayTypePickerOpenFor} onClose={() => setDayTypePickerOpenFor(false)} title="Tipo de dia">
        <div className="flex flex-col">
          {dayTypes.map((dt) => (
            <OptionRow
              key={dt.id}
              label={dt.displayName}
              icon={<IconBadge icon={dt.icon} token={dt.color} size="sm" />}
              selected={dt.id === dayTypeId}
              onClick={() => {
                setDayTypeId(dt.id)
                setDayTypePickerOpenFor(false)
              }}
            />
          ))}
        </div>
      </BottomSheet>
    </BottomSheet>
  )
}

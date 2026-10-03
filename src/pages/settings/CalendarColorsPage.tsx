import { useState } from 'react'
import { Lock, Pencil, Plus, Trash2 } from 'lucide-react'
import { useAppStore } from '../../store/appStore'
import { createId } from '../../lib/id'
import { sortDayTypesForDisplay } from '../../lib/default-data'
import { toast } from '../../store/toastStore'
import { AppHeader } from '../../components/layout/AppHeader'
import { Card } from '../../components/ui/Card'
import { FormField, TextInput } from '../../components/ui/FormField'
import { BottomSheet } from '../../components/ui/BottomSheet'
import { IconBadge } from '../../components/ui/IconBadge'
import { ColorPickerSheet } from '../../components/ui/ColorPickerSheet'
import { PrimaryButton } from '../../components/ui/PrimaryButton'
import { Modal } from '../../components/ui/Modal'
import type { DayType } from '../../types'

const PRESET_ICONS = [
  'Briefcase',
  'Leaf',
  'Zap',
  'Star',
  'Sun',
  'Moon',
  'Home',
  'Coffee',
  'Shield',
  'Umbrella',
  'Plane',
  'HeartPulse',
]

export function CalendarColorsPage() {
  const dayTypes = useAppStore((s) => s.dayTypes)
  const addDayType = useAppStore((s) => s.addDayType)
  const updateDayType = useAppStore((s) => s.updateDayType)
  const deleteDayType = useAppStore((s) => s.deleteDayType)

  const [editingDayType, setEditingDayType] = useState<DayType | null>(null)
  const [confirmDelete, setConfirmDelete] = useState<DayType | null>(null)

  function createDayType() {
    const newType: DayType = {
      id: createId(),
      displayName: 'Nova categoria',
      classification: 'MANUAL',
      color: '#6b7280',
      icon: 'Star',
      isCore: false,
    }
    addDayType(newType)
    setEditingDayType(newType)
  }

  function saveDayType(updated: DayType) {
    updateDayType(updated.id, updated)
    setEditingDayType(null)
    toast.success('Salvo')
  }

  function confirmDeleteDayType() {
    if (!confirmDelete) return
    deleteDayType(confirmDelete.id)
    setConfirmDelete(null)
    toast.success('Categoria removida')
  }

  return (
    <div className="flex flex-col gap-4 pb-8">
      <AppHeader showBack title="Cores do calendário" subtitle="Escala automática e marcação manual dos dias" />

      <div className="flex flex-col gap-3 px-5">
        {sortDayTypesForDisplay(dayTypes).map((dt) => (
          <Card key={dt.id} padding="md" className="flex items-center gap-3">
            <IconBadge icon={dt.icon} token={dt.color} />
            <div className="min-w-0 flex-1">
              <p className="text-[15px] font-semibold text-text-primary">{dt.displayName}</p>
              <p className="text-xs text-text-secondary">
                {dt.classification === 'WORK'
                  ? 'Usado na escala automática (trabalho)'
                  : dt.classification === 'REST'
                    ? 'Usado na escala automática (descanso)'
                    : 'Disponível para marcação manual'}
              </p>
            </div>
            <button
              onClick={() => setEditingDayType(dt)}
              className="flex h-8 w-8 items-center justify-center rounded-full bg-surface-elevated text-text-primary active:opacity-70"
            >
              <Pencil size={14} />
            </button>
            {dt.isCore ? (
              <div
                className="flex h-8 w-8 items-center justify-center rounded-full bg-surface-elevated text-text-muted"
                title="Categoria essencial — não pode ser excluída"
              >
                <Lock size={13} />
              </div>
            ) : (
              <button
                onClick={() => setConfirmDelete(dt)}
                className="flex h-8 w-8 items-center justify-center rounded-full bg-danger/15 text-danger active:opacity-70"
              >
                <Trash2 size={14} />
              </button>
            )}
          </Card>
        ))}

        <button
          onClick={createDayType}
          className="flex items-center justify-center gap-2 rounded-2xl border border-dashed border-border py-3 text-sm font-semibold text-primary active:bg-primary/10"
        >
          <Plus size={16} />
          Nova categoria
        </button>
      </div>

      {editingDayType && (
        <DayTypeEditorSheet dayType={editingDayType} onClose={() => setEditingDayType(null)} onSave={saveDayType} />
      )}

      <Modal open={!!confirmDelete} onClose={() => setConfirmDelete(null)} title="Excluir categoria?">
        <div className="flex flex-col gap-4">
          <p className="text-sm text-text-secondary">
            Os dias marcados com "{confirmDelete?.displayName}" voltarão a mostrar a escala automática.
          </p>
          <div className="flex gap-3">
            <PrimaryButton variant="secondary" onClick={() => setConfirmDelete(null)}>
              Cancelar
            </PrimaryButton>
            <PrimaryButton className="!bg-danger active:!bg-danger/80" onClick={confirmDeleteDayType}>
              Excluir
            </PrimaryButton>
          </div>
        </div>
      </Modal>
    </div>
  )
}

function DayTypeEditorSheet({
  dayType,
  onClose,
  onSave,
}: {
  dayType: DayType
  onClose: () => void
  onSave: (d: DayType) => void
}) {
  const [displayName, setDisplayName] = useState(dayType.displayName)
  const [color, setColor] = useState(dayType.color)
  const [icon, setIcon] = useState(dayType.icon)
  const [colorPickerOpen, setColorPickerOpen] = useState(false)

  return (
    <BottomSheet open onClose={onClose} title="Editar categoria">
      <div className="flex flex-col gap-4">
        <FormField label="Nome exibido">
          <TextInput value={displayName} onChange={(e) => setDisplayName(e.target.value)} />
        </FormField>

        <FormField label="Cor">
          <button
            type="button"
            onClick={() => setColorPickerOpen(true)}
            className="flex items-center gap-3 rounded-2xl border border-border/70 bg-surface-secondary px-4 py-3"
          >
            <span className="h-8 w-8 shrink-0 rounded-full border border-white/10" style={{ backgroundColor: color }} />
            <span className="text-[15px] text-text-primary">{color.toUpperCase()}</span>
          </button>
        </FormField>

        <FormField label="Ícone">
          <div className="flex flex-wrap gap-2">
            {PRESET_ICONS.map((name) => (
              <button
                key={name}
                onClick={() => setIcon(name)}
                className={[
                  'flex h-10 w-10 items-center justify-center rounded-xl bg-surface-secondary',
                  icon === name ? 'ring-2 ring-primary' : '',
                ].join(' ')}
              >
                <IconBadge icon={name} token={color} size="sm" />
              </button>
            ))}
          </div>
        </FormField>

        <PrimaryButton onClick={() => onSave({ ...dayType, displayName, color, icon })}>SALVAR</PrimaryButton>
      </div>

      <ColorPickerSheet open={colorPickerOpen} value={color} onClose={() => setColorPickerOpen(false)} onChange={setColor} />
    </BottomSheet>
  )
}

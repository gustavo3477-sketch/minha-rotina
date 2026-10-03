import { useState } from 'react'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { useAppStore } from '../../../store/appStore'
import { createId } from '../../../lib/id'
import { toast } from '../../../store/toastStore'
import { Card } from '../../../components/ui/Card'
import { IconBadge } from '../../../components/ui/IconBadge'
import { BottomSheet } from '../../../components/ui/BottomSheet'
import { FormField, TextInput } from '../../../components/ui/FormField'
import { PrimaryButton } from '../../../components/ui/PrimaryButton'
import type { Category } from '../../../types'

const PRESET_ICONS = ['HeartPulse', 'Dumbbell', 'Church', 'FileText', 'MapPin', 'Briefcase', 'Home', 'Plane', 'GraduationCap', 'ShoppingBag']
const PRESET_COLORS = ['work', 'off', 'extra', 'appointment', 'special', 'primary']

export function CategoriesSection() {
  const categories = useAppStore((s) => s.categories)
  const addCategory = useAppStore((s) => s.addCategory)
  const updateCategory = useAppStore((s) => s.updateCategory)
  const deleteCategory = useAppStore((s) => s.deleteCategory)
  const [editing, setEditing] = useState<Category | null>(null)

  function createNew() {
    const category: Category = { id: createId(), name: 'Nova categoria', color: 'primary', icon: 'Tag' }
    addCategory(category)
    setEditing(category)
  }

  return (
    <div className="flex flex-col gap-3">
      {categories.map((c) => (
        <Card key={c.id} padding="md" className="flex items-center gap-3">
          <IconBadge icon={c.icon} token={c.color} />
          <p className="flex-1 text-[15px] font-medium text-text-primary">{c.name}</p>
          <button
            onClick={() => setEditing(c)}
            className="flex h-8 w-8 items-center justify-center rounded-full bg-surface-elevated text-text-primary active:opacity-70"
          >
            <Pencil size={14} />
          </button>
          <button
            onClick={() => {
              deleteCategory(c.id)
              toast.success('Categoria removida')
            }}
            className="flex h-8 w-8 items-center justify-center rounded-full bg-danger/15 text-danger active:opacity-70"
          >
            <Trash2 size={14} />
          </button>
        </Card>
      ))}

      <button
        onClick={createNew}
        className="flex items-center justify-center gap-2 rounded-2xl border border-dashed border-border py-3 text-sm font-semibold text-primary active:bg-primary/10"
      >
        <Plus size={16} />
        Nova categoria
      </button>

      {editing && (
        <BottomSheet open onClose={() => setEditing(null)} title="Editar categoria">
          <CategoryForm
            category={editing}
            onSave={(patch) => {
              updateCategory(editing.id, patch)
              setEditing(null)
              toast.success('Salvo')
            }}
          />
        </BottomSheet>
      )}
    </div>
  )
}

function CategoryForm({ category, onSave }: { category: Category; onSave: (patch: Partial<Category>) => void }) {
  const [name, setName] = useState(category.name)
  const [color, setColor] = useState(category.color)
  const [icon, setIcon] = useState(category.icon)

  return (
    <div className="flex flex-col gap-4">
      <FormField label="Nome">
        <TextInput value={name} onChange={(e) => setName(e.target.value)} />
      </FormField>
      <FormField label="Cor">
        <div className="flex flex-wrap gap-2">
          {PRESET_COLORS.map((c) => (
            <button
              key={c}
              onClick={() => setColor(c)}
              className={['h-9 w-9 rounded-full', `bg-${c}`, color === c ? 'ring-2 ring-white ring-offset-2 ring-offset-surface' : ''].join(' ')}
            />
          ))}
        </div>
      </FormField>
      <FormField label="Ícone">
        <div className="flex flex-wrap gap-2">
          {PRESET_ICONS.map((name) => (
            <button
              key={name}
              onClick={() => setIcon(name)}
              className={['flex h-10 w-10 items-center justify-center rounded-xl bg-surface-secondary', icon === name ? 'ring-2 ring-primary' : ''].join(' ')}
            >
              <IconBadge icon={name} token={color} size="sm" />
            </button>
          ))}
        </div>
      </FormField>
      <PrimaryButton onClick={() => onSave({ name, color, icon })}>SALVAR</PrimaryButton>
    </div>
  )
}

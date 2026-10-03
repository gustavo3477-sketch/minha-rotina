import { Check, Moon } from 'lucide-react'
import { Card } from '../../../components/ui/Card'

export function AppearanceSection() {
  return (
    <div className="flex flex-col gap-4">
      <Card padding="md" className="flex items-center gap-3 border-primary">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/15 text-primary">
          <Moon size={18} />
        </div>
        <div className="flex-1">
          <p className="text-[15px] font-medium text-text-primary">Escuro</p>
          <p className="text-xs text-text-secondary">Identidade visual oficial do Minha Rotina</p>
        </div>
        <Check size={18} className="text-primary" />
      </Card>
      <p className="px-1 text-xs text-text-muted">
        O Minha Rotina usa um tema escuro único, desenhado para leitura rápida da escala. Outros temas
        podem ser adicionados futuramente sem alterar essa identidade.
      </p>
    </div>
  )
}

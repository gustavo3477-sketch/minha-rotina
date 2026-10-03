import { ChevronRight, User } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useAppStore } from '../../store/appStore'
import { getIcon } from '../../lib/icons'
import { Card } from '../../components/ui/Card'

const ROWS = [
  { label: 'Próximas folgas', icon: 'CalendarHeart', to: '/proximas-folgas' },
  { label: 'Compartilhar', icon: 'Share2', to: '/compartilhar' },
  { label: 'Configuração da escala', icon: 'SlidersHorizontal', to: '/configuracao-escala' },
  { label: 'Configurações', icon: 'Settings', to: '/configuracoes' },
]

export function MorePage() {
  const navigate = useNavigate()
  const userName = useAppStore((s) => s.userName)

  return (
    <div className="flex flex-col gap-5 px-5 pt-[calc(env(safe-area-inset-top)+16px)]">
      <h1 className="text-xl font-bold text-text-primary">Mais</h1>

      <Card padding="md" className="flex items-center gap-3">
        <div className="flex h-11 w-11 items-center justify-center rounded-full bg-primary/15 text-primary">
          <User size={20} />
        </div>
        <p className="text-[15px] font-semibold text-text-primary">{userName}</p>
      </Card>

      <Card padding="none" className="divide-y divide-divider">
        {ROWS.map((row) => {
          const Icon = getIcon(row.icon)
          return (
            <button
              key={row.label}
              onClick={() => navigate(row.to)}
              className="flex w-full items-center gap-3 px-4 py-3.5 active:bg-surface-elevated"
            >
              <Icon size={19} className="text-primary" />
              <span className="flex-1 text-left text-[15px] text-text-primary">{row.label}</span>
              <ChevronRight size={18} className="text-text-muted" />
            </button>
          )
        })}
      </Card>
    </div>
  )
}

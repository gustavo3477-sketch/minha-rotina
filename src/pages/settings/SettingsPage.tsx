import { ChevronRight } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { getIcon } from '../../lib/icons'
import { AppHeader } from '../../components/layout/AppHeader'
import { Card } from '../../components/ui/Card'

interface SettingsRow {
  label: string
  icon: string
  to: string
}

const ROWS: SettingsRow[] = [
  { label: 'Minha conta', icon: 'User', to: '/configuracoes/minha-conta' },
  { label: 'Minha escala', icon: 'Calendar', to: '/configuracao-escala' },
  { label: 'Horário de trabalho', icon: 'Clock', to: '/configuracao-escala' },
  { label: 'Cores do calendário', icon: 'PaintBucket', to: '/configuracoes/cores-calendario' },
  { label: 'Categorias', icon: 'Tags', to: '/configuracoes/categorias' },
  { label: 'Notificações', icon: 'Bell', to: '/configuracoes/notificacoes' },
  { label: 'Aparência', icon: 'SunMoon', to: '/configuracoes/aparencia' },
  { label: 'Dados e backup', icon: 'Database', to: '/configuracoes/dados-backup' },
  { label: 'Compartilhamento', icon: 'Share2', to: '/compartilhar' },
  { label: 'PWA / Instalação', icon: 'Smartphone', to: '/configuracoes/pwa' },
  { label: 'Sobre', icon: 'Info', to: '/configuracoes/sobre' },
]

export function SettingsPage() {
  const navigate = useNavigate()
  return (
    <div className="flex flex-col gap-4 pb-8">
      <AppHeader showBack title="Configurações" />

      <div className="px-5">
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
    </div>
  )
}

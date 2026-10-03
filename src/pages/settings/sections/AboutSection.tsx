import { CalendarCheck2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useAppStore } from '../../../store/appStore'
import { Card } from '../../../components/ui/Card'

export function AboutSection() {
  const navigate = useNavigate()
  const restartOnboarding = useAppStore((s) => s.restartOnboarding)
  return (
    <div className="flex flex-col items-center gap-4 pt-4 text-center">
      <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary text-white">
        <CalendarCheck2 size={30} />
      </div>
      <div>
        <h2 className="text-lg font-bold text-text-primary">Minha Rotina</h2>
        <p className="text-sm text-text-secondary">Seu tempo. Seu equilíbrio.</p>
      </div>
      <Card padding="md" className="w-full text-left text-sm text-text-secondary">
        Versão 1.0.0
        <br />
        Escala, compromissos e organização da rotina — funcionando 100% offline, com seus dados
        guardados neste dispositivo.
      </Card>
      <p className="text-xs italic text-text-muted">"Disciplina hoje, um amanhã melhor."</p>
      <button
        onClick={() => {
          restartOnboarding()
          navigate('/onboarding')
        }}
        className="text-sm font-medium text-primary"
      >
        Rever introdução
      </button>
    </div>
  )
}

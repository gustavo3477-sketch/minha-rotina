import { Check, Download, Smartphone } from 'lucide-react'
import { usePwaStore } from '../../../store/pwaStore'
import { useOnlineStatus } from '../../../hooks/useOnlineStatus'
import { toast } from '../../../store/toastStore'
import { Card } from '../../../components/ui/Card'
import { PrimaryButton } from '../../../components/ui/PrimaryButton'

export function PwaSection() {
  const { deferredPrompt, isInstalled, setDeferredPrompt } = usePwaStore()
  const online = useOnlineStatus()

  async function handleInstall() {
    if (!deferredPrompt) return
    await deferredPrompt.prompt()
    const choice = await deferredPrompt.userChoice
    if (choice.outcome === 'accepted') toast.success('Aplicativo instalado')
    setDeferredPrompt(null)
  }

  return (
    <div className="flex flex-col gap-4">
      <Card padding="lg" className="flex items-center gap-3">
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/15 text-primary">
          <Smartphone size={22} />
        </div>
        <div className="flex-1">
          <p className="text-[15px] font-medium text-text-primary">
            {isInstalled ? 'Instalado' : 'Instalar na tela inicial'}
          </p>
          <p className="text-xs text-text-secondary">
            {isInstalled
              ? 'O Minha Rotina já está instalado como aplicativo.'
              : 'Use como um app nativo, sem precisar de loja de aplicativos.'}
          </p>
        </div>
        {isInstalled && <Check size={20} className="text-success" />}
      </Card>

      {!isInstalled && (
        <PrimaryButton onClick={handleInstall} disabled={!deferredPrompt}>
          <Download size={16} />
          {deferredPrompt ? 'Instalar agora' : 'Instalação indisponível neste navegador'}
        </PrimaryButton>
      )}

      <Card padding="md" className="flex items-center justify-between">
        <span className="text-sm text-text-secondary">Status da conexão</span>
        <span className={online ? 'text-sm font-medium text-success' : 'text-sm font-medium text-warning'}>
          {online ? 'Online' : 'Offline'}
        </span>
      </Card>

      <p className="px-1 text-xs text-text-muted">
        No iPhone/Safari: toque em Compartilhar → "Adicionar à Tela de Início". No Android/Chrome, use o
        botão acima ou o menu ⋮ → "Instalar aplicativo".
      </p>
    </div>
  )
}

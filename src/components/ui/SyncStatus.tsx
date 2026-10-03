import { Cloud, CloudOff } from 'lucide-react'
import { useOnlineStatus } from '../../hooks/useOnlineStatus'

export function SyncStatus() {
  const online = useOnlineStatus()

  if (online) {
    return (
      <div className="flex items-center gap-1.5 text-xs font-medium text-text-muted">
        <Cloud size={13} />
        Sincronizado
      </div>
    )
  }

  return (
    <div className="flex items-center gap-1.5 text-xs font-medium text-warning">
      <CloudOff size={13} />
      Aguardando conexão
    </div>
  )
}

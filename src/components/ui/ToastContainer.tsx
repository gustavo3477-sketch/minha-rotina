import { Check, CloudOff, Info, TriangleAlert } from 'lucide-react'
import { useToastStore } from '../../store/toastStore'

const ICONS = {
  success: Check,
  info: Info,
  offline: CloudOff,
  error: TriangleAlert,
}

export function ToastContainer() {
  const toasts = useToastStore((s) => s.toasts)
  if (toasts.length === 0) return null

  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-[calc(env(safe-area-inset-bottom)+84px)] z-[60] flex flex-col items-center gap-2 px-4">
      {toasts.map((t) => {
        const Icon = ICONS[t.kind]
        return (
          <div
            key={t.id}
            className="pointer-events-auto flex items-center gap-2 rounded-full border border-border/60 bg-surface-elevated px-4 py-2.5 text-sm font-medium text-text-primary shadow-lg"
          >
            <Icon size={16} className={t.kind === 'error' ? 'text-danger' : 'text-success'} />
            {t.message}
          </div>
        )
      })}
    </div>
  )
}

import { useState } from 'react'
import { Card } from '../../../components/ui/Card'
import { Switch } from '../../../components/ui/Switch'
import { toast } from '../../../store/toastStore'

function usePersistedBoolean(key: string, initial: boolean) {
  const [value, setValue] = useState(() => {
    const stored = localStorage.getItem(key)
    return stored === null ? initial : stored === 'true'
  })
  return [
    value,
    (next: boolean) => {
      localStorage.setItem(key, String(next))
      setValue(next)
    },
  ] as const
}

export function NotificationsSection() {
  const [enabled, setEnabled] = usePersistedBoolean('minha-rotina:notif:enabled', false)
  const [reminders, setReminders] = usePersistedBoolean('minha-rotina:notif:reminders', true)
  const [dailySummary, setDailySummary] = usePersistedBoolean('minha-rotina:notif:daily', false)

  async function handleToggleEnabled(next: boolean) {
    if (next && 'Notification' in window) {
      const permission = await Notification.requestPermission()
      if (permission !== 'granted') {
        toast.error('Permissão de notificação negada')
        return
      }
    }
    setEnabled(next)
  }

  return (
    <div className="flex flex-col gap-3">
      <Card padding="none" className="divide-y divide-divider">
        <Row label="Permitir notificações" checked={enabled} onChange={handleToggleEnabled} />
        <Row label="Lembretes de compromissos" checked={reminders} onChange={setReminders} disabled={!enabled} />
        <Row label="Resumo diário da rotina" checked={dailySummary} onChange={setDailySummary} disabled={!enabled} />
      </Card>
      <p className="px-1 text-xs text-text-muted">
        As notificações dependem da permissão do navegador/dispositivo e do app instalado como PWA.
      </p>
    </div>
  )
}

function Row({
  label,
  checked,
  onChange,
  disabled,
}: {
  label: string
  checked: boolean
  onChange: (v: boolean) => void
  disabled?: boolean
}) {
  return (
    <div className="flex items-center justify-between px-4 py-3.5">
      <span className={['text-[15px]', disabled ? 'text-text-muted' : 'text-text-primary'].join(' ')}>{label}</span>
      <Switch checked={checked && !disabled} onChange={onChange} label={label} />
    </div>
  )
}

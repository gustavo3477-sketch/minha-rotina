import { useMemo, useState } from 'react'
import { addDays, endOfMonth, startOfMonth } from 'date-fns'
import { useAppStore } from '../../store/appStore'
import { useAppointmentsInRange, useEngineOptions, useRangeResolution } from '../../hooks/useSchedule'
import { toISODate } from '../../lib/date-utils'
import { buildShareText } from '../../lib/shareText'
import { toast } from '../../store/toastStore'
import { AppHeader } from '../../components/layout/AppHeader'
import { SegmentedControl } from '../../components/ui/SegmentedControl'
import { Card } from '../../components/ui/Card'
import { Switch } from '../../components/ui/Switch'
import { TextInput } from '../../components/ui/FormField'
import { PrimaryButton } from '../../components/ui/PrimaryButton'

type Scope = 'SCHEDULE' | 'APPOINTMENTS' | 'PERIOD'
type Period = 'CURRENT_MONTH' | 'NEXT_30' | 'CUSTOM'
type Format = 'LINK' | 'PDF' | 'TEXT'

export function SharePage() {
  const dayNotes = useAppStore((s) => s.dayNotes)
  const [scope, setScope] = useState<Scope>('SCHEDULE')
  const [period, setPeriod] = useState<Period>('CURRENT_MONTH')
  const [customStart, setCustomStart] = useState(toISODate(new Date()))
  const [customEnd, setCustomEnd] = useState(toISODate(addDays(new Date(), 30)))

  const [onlyWorkDays, setOnlyWorkDays] = useState(false)
  const [includeExtras, setIncludeExtras] = useState(true)
  const [includeAppointments, setIncludeAppointments] = useState(true)
  const [includeNotes, setIncludeNotes] = useState(false)
  const [format, setFormat] = useState<Format>('LINK')

  const { start, end } = useMemo(() => {
    const today = new Date()
    if (period === 'CURRENT_MONTH') return { start: startOfMonth(today), end: endOfMonth(today) }
    if (period === 'NEXT_30') return { start: today, end: addDays(today, 30) }
    return { start: new Date(`${customStart}T00:00:00`), end: new Date(`${customEnd}T00:00:00`) }
  }, [period, customStart, customEnd])

  const startIso = toISODate(start)
  const endIso = toISODate(end)
  const engineOptions = useEngineOptions()
  const resolutions = useRangeResolution(startIso, endIso)
  const appointmentsByDate = useAppointmentsInRange(startIso, endIso, 'APPOINTMENT')
  const extrasByDate = useAppointmentsInRange(startIso, endIso, 'EXTRA_SHIFT')

  async function handleGenerate() {
    if (!engineOptions.dayTypes.length) return
    const text = buildShareText(resolutions, appointmentsByDate, extrasByDate, dayNotes, {
      onlyWorkDays,
      includeExtras,
      includeAppointments,
      includeNotes,
    })

    if (format === 'PDF') {
      const win = window.open('', '_blank')
      if (win) {
        win.document.write(
          `<pre style="font-family:ui-sans-serif,system-ui;white-space:pre-wrap;padding:24px;">${text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')}</pre>`,
        )
        win.document.close()
        win.focus()
        win.print()
      }
      return
    }

    if (navigator.share) {
      try {
        await navigator.share({ title: 'Minha Rotina', text })
        toast.success('Compartilhado')
        return
      } catch {
        // usuário cancelou o share nativo — cai para o fallback de copiar
      }
    }

    await navigator.clipboard.writeText(text)
    toast.success('Copiado para a área de transferência')
  }

  return (
    <div className="flex flex-col gap-5 pb-8">
      <AppHeader showBack title="Compartilhar" />

      <div className="flex flex-col gap-5 px-5">
        <SegmentedControl
          options={[
            { value: 'SCHEDULE', label: 'Escala' },
            { value: 'APPOINTMENTS', label: 'Compromissos' },
            { value: 'PERIOD', label: 'Período' },
          ]}
          value={scope}
          onChange={(v) => setScope(v as Scope)}
        />

        <div>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-text-muted">Período</h2>
          <div className="flex flex-col gap-1 rounded-2xl bg-surface-secondary p-1">
            {[
              { value: 'CURRENT_MONTH', label: 'Mês atual' },
              { value: 'NEXT_30', label: 'Próximos 30 dias' },
              { value: 'CUSTOM', label: 'Período personalizado' },
            ].map((opt) => (
              <label key={opt.value} className="flex items-center gap-3 rounded-xl px-3 py-2.5 active:bg-surface-elevated">
                <input
                  type="radio"
                  checked={period === opt.value}
                  onChange={() => setPeriod(opt.value as Period)}
                  className="h-4 w-4 accent-primary"
                />
                <span className="text-[15px] text-text-primary">{opt.label}</span>
              </label>
            ))}
          </div>
          {period === 'CUSTOM' && (
            <div className="mt-3 grid grid-cols-2 gap-3">
              <TextInput type="date" value={customStart} onChange={(e) => setCustomStart(e.target.value)} />
              <TextInput type="date" value={customEnd} onChange={(e) => setCustomEnd(e.target.value)} />
            </div>
          )}
        </div>

        <div>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-text-muted">Opções</h2>
          <Card padding="none" className="divide-y divide-divider">
            <ToggleRow label="Mostrar apenas dias de serviço" checked={onlyWorkDays} onChange={setOnlyWorkDays} />
            <ToggleRow label="Incluir serviços extras" checked={includeExtras} onChange={setIncludeExtras} />
            <ToggleRow label="Incluir compromissos" checked={includeAppointments} onChange={setIncludeAppointments} />
            <ToggleRow label="Incluir observações" checked={includeNotes} onChange={setIncludeNotes} />
          </Card>
        </div>

        <div>
          <h2 className="mb-2 text-xs font-semibold uppercase tracking-wide text-text-muted">Formato</h2>
          <div className="flex flex-col gap-1 rounded-2xl bg-surface-secondary p-1">
            {[
              { value: 'LINK', label: 'Link para visualização' },
              { value: 'PDF', label: 'Arquivo PDF' },
              { value: 'TEXT', label: 'Texto simples' },
            ].map((opt) => (
              <label key={opt.value} className="flex items-center gap-3 rounded-xl px-3 py-2.5 active:bg-surface-elevated">
                <input
                  type="radio"
                  checked={format === opt.value}
                  onChange={() => setFormat(opt.value as Format)}
                  className="h-4 w-4 accent-primary"
                />
                <span className="text-[15px] text-text-primary">{opt.label}</span>
              </label>
            ))}
          </div>
        </div>

        <PrimaryButton onClick={handleGenerate}>GERAR COMPARTILHAMENTO</PrimaryButton>
      </div>
    </div>
  )
}

function ToggleRow({
  label,
  checked,
  onChange,
}: {
  label: string
  checked: boolean
  onChange: (v: boolean) => void
}) {
  return (
    <div className="flex items-center justify-between px-4 py-3.5">
      <span className="text-[15px] text-text-primary">{label}</span>
      <Switch checked={checked} onChange={onChange} label={label} />
    </div>
  )
}

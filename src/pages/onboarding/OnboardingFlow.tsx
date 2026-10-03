import { useMemo, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowRight,
  CalendarCheck2,
  CalendarDays,
  CalendarRange,
  Check,
  CloudOff,
  ListChecks,
  Share2,
} from 'lucide-react'
import { useAppStore } from '../../store/appStore'
import { toISODate } from '../../lib/date-utils'
import { createDefault2x2Schedule } from '../../lib/default-data'
import { pickVersionForDate, computeRunInfo } from '../../lib/schedule-engine'
import { toast } from '../../store/toastStore'
import { TextInput } from '../../components/ui/FormField'
import { TimePicker } from '../../components/ui/TimePicker'
import { PrimaryButton } from '../../components/ui/PrimaryButton'
import { CalendarLegend } from '../../components/calendar/CalendarLegend'
import { OnboardingCalendarPreview } from './OnboardingCalendarPreview'
import type { FixedDayRule } from '../../types'

const TOTAL_STEPS = 6

const WEEKDAY_NAMES = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado']

const FEATURES = [
  { icon: CalendarDays, label: 'Calendário visual e intuitivo' },
  { icon: CalendarRange, label: 'Escala automática' },
  { icon: ListChecks, label: 'Compromissos e lembretes' },
  { icon: CloudOff, label: 'Funciona offline' },
  { icon: Share2, label: 'Compartilhe quando quiser' },
]

export function OnboardingFlow() {
  const navigate = useNavigate()
  const completeOnboarding = useAppStore((s) => s.completeOnboarding)
  const scheduleVersions = useAppStore((s) => s.scheduleVersions)
  const dayTypes = useAppStore((s) => s.dayTypes)
  const updateScheduleVersion = useAppStore((s) => s.updateScheduleVersion)
  const addScheduleVersion = useAppStore((s) => s.addScheduleVersion)

  const [step, setStep] = useState(0)
  const [referenceDate, setReferenceDate] = useState(toISODate(new Date()))
  const [positionIndex, setPositionIndex] = useState(0)
  const [workStart, setWorkStart] = useState('13:00')
  const [workEnd, setWorkEnd] = useState('01:00')
  const [fixedDayRules, setFixedDayRules] = useState<FixedDayRule[]>(() => {
    const offType = dayTypes.find((d) => d.classification === 'REST')
    return Array.from({ length: 7 }, (_, weekday) => ({
      weekday,
      enabled: weekday === 0,
      dayTypeId: offType?.id ?? '',
    }))
  })

  const previewVersion = useMemo(
    () =>
      createDefault2x2Schedule({
        referenceDate,
        workStart,
        workEnd,
      }),
    [referenceDate, workStart, workEnd],
  )
  const previewVersionWithRules = useMemo(
    () => ({
      ...previewVersion,
      referencePositionIndex: positionIndex,
      fixedDayRules,
    }),
    [previewVersion, positionIndex, fixedDayRules],
  )

  function finish() {
    const existing = pickVersionForDate(scheduleVersions, toISODate(new Date()))
    if (existing && scheduleVersions.length <= 1) {
      updateScheduleVersion(existing.id, {
        referenceDate,
        referencePositionIndex: positionIndex,
        fixedDayRules,
        cyclePositions: previewVersionWithRules.cyclePositions,
      })
    } else {
      addScheduleVersion({ ...previewVersionWithRules, effectiveFrom: referenceDate })
    }
    completeOnboarding()
    toast.success('Escala configurada')
    navigate('/')
  }

  function skip() {
    completeOnboarding()
    navigate('/')
  }

  return (
    <div className="flex min-h-dvh flex-col bg-background px-6 pb-8 pt-[calc(env(safe-area-inset-top)+20px)]">
      <div className="flex items-center justify-between text-sm font-medium text-text-muted">
        <span>{step + 1} de {TOTAL_STEPS}</span>
        <button onClick={skip} className="text-text-secondary">
          Pular
        </button>
      </div>

      <div className="flex flex-1 flex-col justify-center gap-6 py-6">
        {step === 0 && (
          <div className="flex flex-col items-center gap-5 text-center">
            <div className="flex h-20 w-20 items-center justify-center rounded-3xl bg-primary text-white">
              <CalendarCheck2 size={38} />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-text-primary">
                Bem-vindo ao
                <br />
                Minha Rotina!
              </h1>
              <p className="mt-2 text-sm text-text-secondary">
                Organize sua escala, compromissos e tenha mais controle sobre seu tempo.
              </p>
            </div>
            <div className="flex w-full flex-col gap-3 rounded-3xl bg-surface p-4">
              {FEATURES.map((f) => (
                <div key={f.label} className="flex items-center gap-3">
                  <f.icon size={18} className="shrink-0 text-primary" />
                  <span className="text-sm text-text-secondary">{f.label}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {step === 1 && (
          <StepShell title="Tipo de escala" subtitle="Como funciona o seu ciclo de trabalho">
            <div className="rounded-2xl border-2 border-primary bg-primary/10 p-4">
              <p className="text-[15px] font-semibold text-text-primary">2x2 (personalizada)</p>
              <p className="mt-1 text-sm text-text-secondary">
                2 dias de trabalho, 2 dias de folga. Domingo fixo como folga e fora da contagem do ciclo.
              </p>
            </div>
          </StepShell>
        )}

        {step === 2 && (
          <StepShell title="Dias fixos" subtitle="Dias que não entram na contagem do ciclo">
            <div className="flex flex-col gap-1 rounded-2xl bg-surface-secondary p-2">
              {fixedDayRules.map((rule) => (
                <label key={rule.weekday} className="flex items-center gap-3 rounded-xl px-2 py-2.5">
                  <input
                    type="checkbox"
                    checked={rule.enabled}
                    onChange={() =>
                      setFixedDayRules((rules) =>
                        rules.map((r) => (r.weekday === rule.weekday ? { ...r, enabled: !r.enabled } : r)),
                      )
                    }
                    className="h-4.5 w-4.5 accent-primary"
                  />
                  <span className="text-[15px] text-text-primary">{WEEKDAY_NAMES[rule.weekday]}</span>
                </label>
              ))}
            </div>
          </StepShell>
        )}

        {step === 3 && (
          <StepShell title="Data de referência" subtitle="A partir de qual dia começamos a calcular?">
            <TextInput type="date" value={referenceDate} onChange={(e) => setReferenceDate(e.target.value)} />
            <div className="mt-4 flex flex-col gap-1 rounded-2xl bg-surface-secondary p-2">
              {previewVersion.cyclePositions.map((p, index) => (
                <label key={p.id} className="flex items-center gap-3 rounded-xl px-2 py-2.5">
                  <input
                    type="radio"
                    checked={positionIndex === index}
                    onChange={() => setPositionIndex(index)}
                    className="h-4 w-4 accent-primary"
                  />
                  <span className="text-[15px] text-text-primary">
                    {p.nameOverride} ({computeRunInfo(previewVersion.cyclePositions, index).dayNumber}º dia)
                  </span>
                </label>
              ))}
            </div>
          </StepShell>
        )}

        {step === 4 && (
          <StepShell title="Horário de serviço" subtitle="Horário padrão dos dias de trabalho">
            <div className="grid grid-cols-2 gap-3">
              <TimePicker value={workStart} onChange={setWorkStart} />
              <TimePicker value={workEnd} onChange={setWorkEnd} />
            </div>
          </StepShell>
        )}

        {step === 5 && (
          <StepShell title="Confira sua escala" subtitle="Veja se a prévia está correta antes de continuar">
            <OnboardingCalendarPreview version={previewVersionWithRules} dayTypes={dayTypes} />
            <div className="mt-4">
              <CalendarLegend />
            </div>
          </StepShell>
        )}
      </div>

      <div className="mb-4 flex items-center justify-center gap-1.5">
        {Array.from({ length: TOTAL_STEPS }, (_, i) => (
          <span
            key={i}
            className={['h-1.5 rounded-full transition-all', i === step ? 'w-6 bg-primary' : 'w-1.5 bg-border'].join(' ')}
          />
        ))}
      </div>

      {step < TOTAL_STEPS - 1 ? (
        <PrimaryButton onClick={() => setStep((s) => s + 1)}>
          {step === 0 ? 'VAMOS COMEÇAR' : 'CONTINUAR'}
          <ArrowRight size={18} />
        </PrimaryButton>
      ) : (
        <PrimaryButton onClick={finish}>
          <Check size={18} />
          MINHA ESCALA ESTÁ CORRETA
        </PrimaryButton>
      )}
    </div>
  )
}

function StepShell({ title, subtitle, children }: { title: string; subtitle: string; children: ReactNode }) {
  return (
    <div>
      <h2 className="text-xl font-bold text-text-primary">{title}</h2>
      <p className="mt-1 text-sm text-text-secondary">{subtitle}</p>
      <div className="mt-5">{children}</div>
    </div>
  )
}

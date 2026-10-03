import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ChevronRight, Info, SlidersHorizontal } from 'lucide-react'
import { useAppStore } from '../../store/appStore'
import { pickVersionForDate, computeRunInfo } from '../../lib/schedule-engine'
import { toISODate } from '../../lib/date-utils'
import { createId } from '../../lib/id'
import { toast } from '../../store/toastStore'
import { AppHeader } from '../../components/layout/AppHeader'
import { Card } from '../../components/ui/Card'
import { FormField, TextInput } from '../../components/ui/FormField'
import { TimePicker } from '../../components/ui/TimePicker'
import { SelectField } from '../../components/ui/SelectField'
import { BottomSheet } from '../../components/ui/BottomSheet'
import { OptionRow } from '../../components/ui/OptionRow'
import { PrimaryButton } from '../../components/ui/PrimaryButton'
import type { FixedDayRule } from '../../types'

const WEEKDAY_NAMES = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
]

export function ScheduleConfigPage() {
  const navigate = useNavigate()
  const scheduleVersions = useAppStore((s) => s.scheduleVersions)
  const dayTypes = useAppStore((s) => s.dayTypes)
  const addScheduleVersion = useAppStore((s) => s.addScheduleVersion)

  const currentVersion = useMemo(
    () => pickVersionForDate(scheduleVersions, toISODate(new Date())),
    [scheduleVersions],
  )
  const sortedPositions = useMemo(
    () => (currentVersion ? [...currentVersion.cyclePositions].sort((a, b) => a.order - b.order) : []),
    [currentVersion],
  )
  const dayTypeMap = useMemo(() => new Map(dayTypes.map((d) => [d.id, d])), [dayTypes])

  const [referenceDate, setReferenceDate] = useState(currentVersion?.referenceDate ?? toISODate(new Date()))
  const [positionIndex, setPositionIndex] = useState(currentVersion?.referencePositionIndex ?? 0)
  const workPosition = sortedPositions.find((p) => dayTypeMap.get(p.dayTypeId)?.classification === 'WORK')
  const [workStart, setWorkStart] = useState(workPosition?.startTime ?? '13:00')
  const [workEnd, setWorkEnd] = useState(workPosition?.endTime ?? '01:00')
  const [fixedDayRules, setFixedDayRules] = useState<FixedDayRule[]>(
    currentVersion?.fixedDayRules ?? [],
  )
  const [effectiveFrom, setEffectiveFrom] = useState(toISODate(new Date()))
  const [positionSheetOpen, setPositionSheetOpen] = useState(false)

  if (!currentVersion) return null

  function toggleFixedDay(weekday: number) {
    setFixedDayRules((rules) =>
      rules.map((r) => (r.weekday === weekday ? { ...r, enabled: !r.enabled } : r)),
    )
  }

  function positionLabel(index: number) {
    const position = sortedPositions[index]
    if (!position) return ''
    const dayType = dayTypeMap.get(position.dayTypeId)
    const { dayNumber } = computeRunInfo(sortedPositions, index)
    const kind = dayType?.classification === 'WORK' ? 'Trabalho' : 'Folga'
    return position.nameOverride
      ? `${position.nameOverride} (${dayNumber}º dia)`
      : `${kind} (${dayNumber}º dia)`
  }

  function handleSave() {
    if (!currentVersion) return
    const updatedPositions = currentVersion.cyclePositions.map((p) =>
      dayTypeMap.get(p.dayTypeId)?.classification === 'WORK'
        ? { ...p, startTime: workStart, endTime: workEnd, crossesMidnight: workEnd < workStart }
        : p,
    )

    addScheduleVersion({
      id: createId(),
      name: currentVersion.name,
      effectiveFrom,
      referenceDate,
      referencePositionIndex: positionIndex,
      cyclePositions: updatedPositions,
      fixedDayRules,
    })
    toast.success('Configuração salva')
    navigate(-1)
  }

  return (
    <div className="flex flex-col gap-5 pb-8">
      <AppHeader showBack title="Configuração da escala" />

      <div className="flex flex-col gap-5 px-5">
        <FormField label="Tipo de escala">
          <SelectField value="2x2 (personalizada)" onClick={() => {}} />
        </FormField>

        <Card className="flex gap-3 border-primary/30 bg-primary/10" padding="md">
          <Info size={18} className="mt-0.5 shrink-0 text-primary" />
          <p className="text-sm text-text-secondary">
            2 dias de trabalho, 2 dias de folga.
            <br />
            <span className="font-semibold text-text-primary">DOMINGO FIXO COMO FOLGA.</span>
            <br />O domingo não entra na contagem do ciclo.
          </p>
        </Card>

        <FormField label="Data de referência">
          <TextInput type="date" value={referenceDate} onChange={(e) => setReferenceDate(e.target.value)} />
        </FormField>

        <FormField label="Situação neste dia">
          <SelectField value={positionLabel(positionIndex)} onClick={() => setPositionSheetOpen(true)} />
        </FormField>

        <FormField label="Horário padrão">
          <div className="grid grid-cols-2 gap-3">
            <TimePicker value={workStart} onChange={setWorkStart} />
            <TimePicker value={workEnd} onChange={setWorkEnd} />
          </div>
        </FormField>

        <button
          onClick={() => navigate('/configuracao-escala/ciclo')}
          className="flex items-center justify-between rounded-2xl bg-surface-secondary px-4 py-3.5"
        >
          <span className="flex items-center gap-2 text-sm font-medium text-text-primary">
            <SlidersHorizontal size={16} className="text-primary" />
            Personalizar meu ciclo (nomes, horários, cores)
          </span>
          <ChevronRight size={18} className="text-text-muted" />
        </button>

        <FormField label="Dias fixos (não entram no ciclo)">
          <div className="flex flex-col gap-1 rounded-2xl bg-surface-secondary p-2">
            {fixedDayRules.map((rule) => (
              <label
                key={rule.weekday}
                className="flex items-center gap-3 rounded-xl px-2 py-2.5 active:bg-surface-elevated"
              >
                <input
                  type="checkbox"
                  checked={rule.enabled}
                  onChange={() => toggleFixedDay(rule.weekday)}
                  className="h-4.5 w-4.5 accent-primary"
                />
                <span className="text-[15px] text-text-primary">
                  {WEEKDAY_NAMES[rule.weekday]}
                  {rule.weekday === 0 && <span className="text-text-muted"> (folga fixa)</span>}
                </span>
              </label>
            ))}
          </div>
        </FormField>

        <FormField label="Nova configuração válida a partir de">
          <TextInput type="date" value={effectiveFrom} onChange={(e) => setEffectiveFrom(e.target.value)} />
        </FormField>

        <PrimaryButton onClick={handleSave}>SALVAR CONFIGURAÇÃO</PrimaryButton>
      </div>

      <BottomSheet open={positionSheetOpen} onClose={() => setPositionSheetOpen(false)} title="Situação neste dia">
        <div className="flex flex-col">
          {sortedPositions.map((position, index) => (
            <OptionRow
              key={position.id}
              label={positionLabel(index)}
              selected={index === positionIndex}
              onClick={() => {
                setPositionIndex(index)
                setPositionSheetOpen(false)
              }}
            />
          ))}
        </div>
      </BottomSheet>
    </div>
  )
}

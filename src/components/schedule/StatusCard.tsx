import { ArrowRight, Pencil } from 'lucide-react'
import { getIcon } from '../../lib/icons'
import { resolveDayColor } from '../../lib/color'
import type { DayResolution } from '../../types'

interface StatusCardProps {
  resolution: DayResolution
  compact?: boolean
}

export function StatusCard({ resolution, compact = false }: StatusCardProps) {
  const Icon = getIcon(resolution.dayType.icon)
  const { background, text } = resolveDayColor(resolution.dayType.color)
  const hasTime = Boolean(resolution.startTime && resolution.endTime)
  const overlaySoft = text === '#ffffff' ? 'rgba(255,255,255,0.2)' : 'rgba(17,24,39,0.12)'
  const overlaySofter = text === '#ffffff' ? 'rgba(255,255,255,0.1)' : 'rgba(17,24,39,0.08)'
  const textSoft = text === '#ffffff' ? 'rgba(255,255,255,0.85)' : 'rgba(17,24,39,0.75)'

  return (
    <div
      className={['relative overflow-hidden rounded-3xl', compact ? 'p-4' : 'p-5'].join(' ')}
      style={{ backgroundColor: background, color: text }}
    >
      <div className="absolute -right-6 -top-8 h-28 w-28 rounded-full" style={{ backgroundColor: overlaySofter }} />
      {resolution.isException && (
        <div
          className="absolute right-3 top-3 flex h-6 w-6 items-center justify-center rounded-full"
          style={{ backgroundColor: overlaySoft }}
          title="Marcação manual"
        >
          <Pencil size={12} />
        </div>
      )}
      <div className="relative flex items-center gap-3">
        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl" style={{ backgroundColor: overlaySoft }}>
          <Icon size={22} strokeWidth={2.25} />
        </div>
        <div className="min-w-0">
          <p className="text-xs font-bold uppercase tracking-wider" style={{ color: textSoft }}>
            {resolution.label}
          </p>
          {hasTime ? (
            <p className="flex items-center gap-2 text-xl font-bold leading-tight">
              {resolution.startTime}
              <ArrowRight size={16} className="shrink-0 opacity-80" />
              {resolution.endTime}
              {resolution.crossesMidnight && (
                <span className="text-xs font-medium opacity-80">+1 dia</span>
              )}
            </p>
          ) : resolution.dayType.classification === 'REST' ? (
            <p className="text-lg font-bold leading-tight">Dia de descanso</p>
          ) : null}
        </div>
      </div>
      {resolution.cycleDayNumber && resolution.cycleDayCount && resolution.cycleDayCount > 1 && (
        <p className="relative mt-3 text-sm font-medium" style={{ color: textSoft }}>
          Dia {resolution.cycleDayNumber} de {resolution.cycleDayCount}
        </p>
      )}
      {resolution.isFixedDay && !resolution.isException && (
        <p className="relative mt-3 text-sm font-medium" style={{ color: textSoft }}>
          Folga fixa
        </p>
      )}
      {resolution.isException && (
        <p className="relative mt-3 text-sm font-medium" style={{ color: textSoft }}>
          Marcação manual
        </p>
      )}
    </div>
  )
}

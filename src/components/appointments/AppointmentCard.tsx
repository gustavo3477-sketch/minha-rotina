import { getIcon } from '../../lib/icons'
import { getTokenClasses } from '../../lib/tokens'
import type { Appointment, Category } from '../../types'

interface AppointmentCardProps {
  appointment: Appointment
  category?: Category
  onClick?: () => void
  dense?: boolean
}

export function AppointmentCard({ appointment, category, onClick, dense = false }: AppointmentCardProps) {
  const icon = category?.icon ?? (appointment.kind === 'EXTRA_SHIFT' ? 'Zap' : 'CalendarClock')
  const token = category?.color ?? (appointment.kind === 'EXTRA_SHIFT' ? 'extra' : 'appointment')
  const Icon = getIcon(icon)
  const classes = getTokenClasses(token)

  const Wrapper = onClick ? 'button' : 'div'

  return (
    <Wrapper
      onClick={onClick}
      className={[
        'flex w-full items-center gap-3 rounded-2xl px-1 py-2.5 text-left',
        onClick ? 'active:bg-surface-elevated' : '',
      ].join(' ')}
    >
      <div className="w-12 shrink-0 text-right">
        <p className="text-sm font-bold text-text-primary">
          {appointment.allDay ? 'Dia todo' : appointment.startTime}
        </p>
        {!appointment.allDay && appointment.endTime && (
          <p className="text-xs text-text-muted">{appointment.endTime}</p>
        )}
      </div>
      <div className={['flex shrink-0 items-center justify-center rounded-xl', classes.bgSoft, classes.text, dense ? 'h-8 w-8' : 'h-10 w-10'].join(' ')}>
        <Icon size={dense ? 15 : 18} strokeWidth={2.1} />
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-[15px] font-medium text-text-primary">{appointment.title}</p>
        {!dense && (appointment.location || appointment.description) && (
          <p className="truncate text-xs text-text-secondary">
            {appointment.location || appointment.description}
          </p>
        )}
      </div>
    </Wrapper>
  )
}

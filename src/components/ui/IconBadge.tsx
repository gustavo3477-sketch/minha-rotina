import { getIcon } from '../../lib/icons'
import { getTokenClasses } from '../../lib/tokens'
import { isHexColor, resolveDayColor } from '../../lib/color'

interface IconBadgeProps {
  icon: string
  token?: string
  size?: 'sm' | 'md' | 'lg'
}

const SIZE_CLASSES: Record<string, { box: string; icon: number }> = {
  sm: { box: 'h-8 w-8', icon: 15 },
  md: { box: 'h-10 w-10', icon: 18 },
  lg: { box: 'h-14 w-14', icon: 24 },
}

export function IconBadge({ icon, token = 'primary', size = 'md' }: IconBadgeProps) {
  const Icon = getIcon(icon)
  const sizing = SIZE_CLASSES[size]

  if (isHexColor(token)) {
    const { background } = resolveDayColor(token)
    return (
      <div
        className={['flex shrink-0 items-center justify-center rounded-2xl', sizing.box].join(' ')}
        style={{ backgroundColor: `${background}26`, color: background }}
      >
        <Icon size={sizing.icon} strokeWidth={2} style={{ color: background }} />
      </div>
    )
  }

  const classes = getTokenClasses(token)
  return (
    <div
      className={[
        'flex shrink-0 items-center justify-center rounded-2xl',
        classes.bgSoft,
        classes.text,
        sizing.box,
      ].join(' ')}
    >
      <Icon size={sizing.icon} strokeWidth={2} />
    </div>
  )
}

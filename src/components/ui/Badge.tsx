import type { ReactNode } from 'react'
import { getTokenClasses } from '../../lib/tokens'

interface BadgeProps {
  children: ReactNode
  token?: string
  variant?: 'solid' | 'soft'
  className?: string
}

export function Badge({ children, token = 'primary', variant = 'soft', className = '' }: BadgeProps) {
  const classes = getTokenClasses(token)
  const style =
    variant === 'solid'
      ? `${classes.bg} text-white`
      : `${classes.bgSoft} ${classes.text}`
  return (
    <span
      className={[
        'inline-flex items-center justify-center rounded-full px-2.5 py-0.5 text-xs font-semibold',
        style,
        className,
      ].join(' ')}
    >
      {children}
    </span>
  )
}

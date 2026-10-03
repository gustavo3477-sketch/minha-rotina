import type { HTMLAttributes, ReactNode } from 'react'

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode
  elevated?: boolean
  padding?: 'none' | 'sm' | 'md' | 'lg'
}

const PADDING_CLASSES: Record<string, string> = {
  none: '',
  sm: 'p-3',
  md: 'p-4',
  lg: 'p-5',
}

export function Card({
  children,
  elevated = false,
  padding = 'md',
  className = '',
  ...props
}: CardProps) {
  return (
    <div
      className={[
        'rounded-3xl border border-border/60 shadow-[0_2px_10px_rgba(0,0,0,0.25)]',
        elevated ? 'bg-surface-elevated' : 'bg-surface',
        PADDING_CLASSES[padding],
        className,
      ].join(' ')}
      {...props}
    >
      {children}
    </div>
  )
}

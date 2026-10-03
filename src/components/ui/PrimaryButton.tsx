import type { ButtonHTMLAttributes, ReactNode } from 'react'

interface PrimaryButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  fullWidth?: boolean
}

const VARIANT_CLASSES: Record<string, string> = {
  primary: 'bg-primary text-white active:bg-primary-dark',
  secondary: 'bg-surface-elevated text-text-primary active:bg-surface-secondary',
  ghost: 'bg-transparent text-primary active:bg-primary/10',
  danger: 'bg-danger text-white active:opacity-80',
}

export function PrimaryButton({
  children,
  variant = 'primary',
  fullWidth = true,
  className = '',
  ...props
}: PrimaryButtonProps) {
  return (
    <button
      className={[
        'flex items-center justify-center gap-2 rounded-2xl px-5 py-3.5 text-[15px] font-semibold tracking-wide transition-transform active:scale-[0.98] disabled:opacity-50 disabled:active:scale-100',
        VARIANT_CLASSES[variant],
        fullWidth ? 'w-full' : '',
        className,
      ].join(' ')}
      {...props}
    >
      {children}
    </button>
  )
}

import type { InputHTMLAttributes, ReactNode, TextareaHTMLAttributes } from 'react'

interface FormFieldProps {
  label: string
  children: ReactNode
  action?: ReactNode
}

export function FormField({ label, children, action }: FormFieldProps) {
  return (
    <div className="flex flex-col gap-1.5">
      <div className="flex items-center justify-between">
        <label className="text-xs font-semibold uppercase tracking-wide text-text-muted">
          {label}
        </label>
        {action}
      </div>
      {children}
    </div>
  )
}

export function TextInput(props: InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      {...props}
      className={[
        'w-full rounded-2xl border border-border/70 bg-surface-secondary px-4 py-3 text-[15px] text-text-primary placeholder:text-text-muted focus:border-primary focus:outline-none',
        props.className ?? '',
      ].join(' ')}
    />
  )
}

export function TextArea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      {...props}
      className={[
        'w-full resize-none rounded-2xl border border-border/70 bg-surface-secondary px-4 py-3 text-[15px] text-text-primary placeholder:text-text-muted focus:border-primary focus:outline-none',
        props.className ?? '',
      ].join(' ')}
    />
  )
}

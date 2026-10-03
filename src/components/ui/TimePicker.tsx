import { Clock } from 'lucide-react'

interface TimePickerProps {
  value: string
  onChange: (value: string) => void
  disabled?: boolean
}

export function TimePicker({ value, onChange, disabled }: TimePickerProps) {
  return (
    <div className="relative">
      <input
        type="time"
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value)}
        className="w-full appearance-none rounded-2xl border border-border/70 bg-surface-secondary px-4 py-3 pr-10 text-[15px] text-text-primary focus:border-primary focus:outline-none disabled:opacity-40 [&::-webkit-calendar-picker-indicator]:opacity-0"
      />
      <Clock size={16} className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-text-muted" />
    </div>
  )
}

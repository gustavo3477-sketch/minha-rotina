interface SegmentOption {
  value: string
  label: string
}

interface SegmentedControlProps {
  options: SegmentOption[]
  value: string
  onChange: (value: string) => void
}

export function SegmentedControl({ options, value, onChange }: SegmentedControlProps) {
  return (
    <div className="flex gap-1.5 rounded-2xl bg-surface-secondary p-1.5">
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          onClick={() => onChange(option.value)}
          className={[
            'min-w-0 flex-1 rounded-xl px-1.5 py-2.5 text-center text-[11px] font-semibold leading-tight transition-colors sm:text-xs',
            value === option.value
              ? 'bg-primary text-white'
              : 'text-text-secondary active:bg-surface-elevated',
          ].join(' ')}
        >
          {option.label}
        </button>
      ))}
    </div>
  )
}

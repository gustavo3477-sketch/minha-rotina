import { Palette } from 'lucide-react'
import { BottomSheet } from './BottomSheet'
import { QUICK_COLOR_PALETTE } from '../../lib/color'

interface ColorPickerSheetProps {
  open: boolean
  value: string
  onClose: () => void
  onChange: (hex: string) => void
}

export function ColorPickerSheet({ open, value, onClose, onChange }: ColorPickerSheetProps) {
  return (
    <BottomSheet open={open} onClose={onClose} title="Escolher cor">
      <div className="flex flex-col gap-4">
        <div className="grid grid-cols-5 gap-3">
          {QUICK_COLOR_PALETTE.map((preset) => (
            <button
              key={preset.hex}
              type="button"
              aria-label={preset.name}
              onClick={() => {
                onChange(preset.hex)
                onClose()
              }}
              className={[
                'flex h-11 w-11 items-center justify-center rounded-full transition-transform active:scale-90',
                value.toLowerCase() === preset.hex.toLowerCase() ? 'ring-2 ring-white ring-offset-2 ring-offset-surface' : '',
              ].join(' ')}
              style={{ backgroundColor: preset.hex }}
            />
          ))}
        </div>

        <label className="flex items-center gap-3 rounded-2xl bg-surface-secondary px-4 py-3.5 active:opacity-80">
          <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-surface-elevated text-primary">
            <Palette size={17} />
          </span>
          <span className="flex-1 text-[15px] font-medium text-text-primary">Escolher outra cor</span>
          <span className="h-7 w-7 shrink-0 rounded-full border border-border" style={{ backgroundColor: value }} />
          <input
            type="color"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            className="sr-only"
          />
        </label>
      </div>
    </BottomSheet>
  )
}

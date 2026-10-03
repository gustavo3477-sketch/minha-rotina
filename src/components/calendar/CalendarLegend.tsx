import { useAppStore } from '../../store/appStore'
import { OFF_DAY_TYPE_ID } from '../../lib/default-data'
import { resolveDayColor } from '../../lib/color'

export function CalendarLegend() {
  const dayTypes = useAppStore((s) => s.dayTypes)
  const offType = dayTypes.find((d) => d.id === OFF_DAY_TYPE_ID)

  const items = [
    ...dayTypes.map((dt) => ({ label: dt.displayName, color: resolveDayColor(dt.color).background })),
    { label: 'Compromissos', color: resolveDayColor('appointment').background },
    { label: 'Hoje', color: resolveDayColor('primary').background },
    ...(offType
      ? [{ label: 'Folga fixa (domingo)', color: resolveDayColor(offType.color).background }]
      : []),
  ]

  return (
    <div className="grid grid-cols-2 gap-x-4 gap-y-2 rounded-2xl bg-surface p-4">
      {items.map((item) => (
        <div key={item.label} className="flex items-center gap-2">
          <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ backgroundColor: item.color }} />
          <span className="text-xs text-text-secondary">{item.label}</span>
        </div>
      ))}
    </div>
  )
}

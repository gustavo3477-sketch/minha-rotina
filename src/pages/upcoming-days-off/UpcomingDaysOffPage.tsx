import { useMemo } from 'react'
import { Info } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { listUpcomingDaysByClassification } from '../../lib/schedule-engine'
import { fromISODate } from '../../lib/date-utils'
import { formatDayMonthYearLong, formatWeekdayLong } from '../../lib/format'
import { useEngineOptions } from '../../hooks/useSchedule'
import { AppHeader } from '../../components/layout/AppHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { EmptyState } from '../../components/ui/EmptyState'

export function UpcomingDaysOffPage() {
  const navigate = useNavigate()
  const engineOptions = useEngineOptions()
  const today = useMemo(() => new Date(), [])

  const upcoming = useMemo(() => {
    if (!engineOptions.dayTypes.length) return []
    return listUpcomingDaysByClassification(today, 'REST', 12, engineOptions)
  }, [today, engineOptions])

  return (
    <div className="flex flex-col gap-4 pb-8">
      <AppHeader showBack title="Próximas folgas" />

      <div className="flex flex-col gap-2 px-5">
        {upcoming.length === 0 ? (
          <EmptyState title="Nenhuma folga encontrada" />
        ) : (
          upcoming.map((r) => {
            const date = fromISODate(r.date)
            return (
              <Card
                key={r.date}
                padding="md"
                className="flex cursor-pointer items-center justify-between active:opacity-80"
                onClick={() => navigate(`/dia/${r.date}`)}
              >
                <div>
                  <p className="text-[15px] font-semibold text-text-primary">{formatWeekdayLong(date)}</p>
                  <p className="text-xs text-text-secondary">{formatDayMonthYearLong(date)}</p>
                </div>
                <Badge token="off">{r.isFixedDay ? 'Folga fixa' : 'Folga'}</Badge>
              </Card>
            )
          })
        )}

        <Card padding="md" className="mt-2 flex gap-3 border-primary/30 bg-primary/10">
          <Info size={18} className="mt-0.5 shrink-0 text-primary" />
          <p className="text-sm text-text-secondary">
            O domingo é folga fixa e não entra na contagem do ciclo 2x2.
          </p>
        </Card>
      </div>
    </div>
  )
}

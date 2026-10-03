import { lazy } from 'react'
import { createBrowserRouter } from 'react-router-dom'
import { AppShell } from '../components/layout/AppShell'
import { PlainShell } from '../components/layout/PlainShell'
import { TodayPage } from '../pages/today/TodayPage'

const CalendarPage = lazy(() => import('../pages/calendar/CalendarPage').then((m) => ({ default: m.CalendarPage })))
const DayDetailPage = lazy(() => import('../pages/day-detail/DayDetailPage').then((m) => ({ default: m.DayDetailPage })))
const AppointmentFormPage = lazy(() =>
  import('../pages/appointment-form/AppointmentFormPage').then((m) => ({ default: m.AppointmentFormPage })),
)
const ScheduleConfigPage = lazy(() =>
  import('../pages/schedule-config/ScheduleConfigPage').then((m) => ({ default: m.ScheduleConfigPage })),
)
const CycleEditorPage = lazy(() =>
  import('../pages/schedule-config/CycleEditorPage').then((m) => ({ default: m.CycleEditorPage })),
)
const CalendarColorsPage = lazy(() =>
  import('../pages/settings/CalendarColorsPage').then((m) => ({ default: m.CalendarColorsPage })),
)
const AgendaPage = lazy(() => import('../pages/agenda/AgendaPage').then((m) => ({ default: m.AgendaPage })))
const UpcomingDaysOffPage = lazy(() =>
  import('../pages/upcoming-days-off/UpcomingDaysOffPage').then((m) => ({ default: m.UpcomingDaysOffPage })),
)
const SharePage = lazy(() => import('../pages/share/SharePage').then((m) => ({ default: m.SharePage })))
const SettingsPage = lazy(() => import('../pages/settings/SettingsPage').then((m) => ({ default: m.SettingsPage })))
const MorePage = lazy(() => import('../pages/more/MorePage').then((m) => ({ default: m.MorePage })))
const OnboardingFlow = lazy(() => import('../pages/onboarding/OnboardingFlow').then((m) => ({ default: m.OnboardingFlow })))
const SettingsPlaceholderPage = lazy(() =>
  import('../pages/settings/SettingsPlaceholderPage').then((m) => ({ default: m.SettingsPlaceholderPage })),
)

export const router = createBrowserRouter([
  {
    element: <AppShell />,
    children: [
      { path: '/', element: <TodayPage /> },
      { path: '/calendario', element: <CalendarPage /> },
      { path: '/agenda', element: <AgendaPage /> },
      { path: '/mais', element: <MorePage /> },
    ],
  },
  {
    element: <PlainShell />,
    children: [
      { path: '/dia/:date', element: <DayDetailPage /> },
      { path: '/novo-compromisso', element: <AppointmentFormPage /> },
      { path: '/compromisso/:id', element: <AppointmentFormPage /> },
      { path: '/configuracao-escala', element: <ScheduleConfigPage /> },
      { path: '/configuracao-escala/ciclo', element: <CycleEditorPage /> },
      { path: '/configuracoes/cores-calendario', element: <CalendarColorsPage /> },
      { path: '/proximas-folgas', element: <UpcomingDaysOffPage /> },
      { path: '/compartilhar', element: <SharePage /> },
      { path: '/configuracoes', element: <SettingsPage /> },
      { path: '/configuracoes/:section', element: <SettingsPlaceholderPage /> },
      { path: '/onboarding', element: <OnboardingFlow /> },
    ],
  },
], { basename: import.meta.env.BASE_URL.replace(/\/$/, '') || '/' })

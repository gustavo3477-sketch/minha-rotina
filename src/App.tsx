import { useEffect } from 'react'
import { RouterProvider } from 'react-router-dom'
import { CalendarCheck2 } from 'lucide-react'
import { router } from './app/router'
import { useAppStore } from './store/appStore'
import { registerPwaInstallListeners } from './store/pwaStore'

function App() {
  const hydrate = useAppStore((s) => s.hydrate)
  const isHydrated = useAppStore((s) => s.isHydrated)
  const onboardingCompleted = useAppStore((s) => s.onboardingCompleted)

  useEffect(() => {
    hydrate()
    registerPwaInstallListeners()
  }, [hydrate])

  useEffect(() => {
    if (isHydrated && !onboardingCompleted && router.state.location.pathname !== '/onboarding') {
      router.navigate('/onboarding')
    }
  }, [isHydrated, onboardingCompleted])

  if (!isHydrated) {
    return (
      <div className="flex min-h-dvh flex-col items-center justify-center gap-3 bg-background">
        <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-primary text-white">
          <CalendarCheck2 size={28} />
        </div>
        <p className="text-sm text-text-secondary">Carregando...</p>
      </div>
    )
  }

  return <RouterProvider router={router} />
}

export default App

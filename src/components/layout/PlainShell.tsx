import { Suspense } from 'react'
import { Outlet } from 'react-router-dom'
import { RouteFallback } from './RouteFallback'
import { ToastContainer } from '../ui/ToastContainer'

export function PlainShell() {
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-md flex-col bg-background lg:max-w-3xl">
      <div className="flex-1 pb-[calc(env(safe-area-inset-bottom)+24px)]">
        <Suspense fallback={<RouteFallback />}>
          <Outlet />
        </Suspense>
      </div>
      <ToastContainer />
    </div>
  )
}

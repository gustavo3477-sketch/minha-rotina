import { create } from 'zustand'

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

interface PwaState {
  deferredPrompt: BeforeInstallPromptEvent | null
  isInstalled: boolean
  setDeferredPrompt: (event: BeforeInstallPromptEvent | null) => void
  setInstalled: (installed: boolean) => void
}

export const usePwaStore = create<PwaState>((set) => ({
  deferredPrompt: null,
  isInstalled: window.matchMedia('(display-mode: standalone)').matches,
  setDeferredPrompt: (event) => set({ deferredPrompt: event }),
  setInstalled: (installed) => set({ isInstalled: installed }),
}))

export function registerPwaInstallListeners() {
  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault()
    usePwaStore.getState().setDeferredPrompt(event as BeforeInstallPromptEvent)
  })
  window.addEventListener('appinstalled', () => {
    usePwaStore.getState().setInstalled(true)
    usePwaStore.getState().setDeferredPrompt(null)
  })
}

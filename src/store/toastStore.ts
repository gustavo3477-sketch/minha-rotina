import { create } from 'zustand'
import { createId } from '../lib/id'

export type ToastKind = 'success' | 'info' | 'offline' | 'error'

export interface ToastItem {
  id: string
  message: string
  kind: ToastKind
}

interface ToastState {
  toasts: ToastItem[]
  push: (message: string, kind?: ToastKind) => void
  dismiss: (id: string) => void
}

export const useToastStore = create<ToastState>((set, get) => ({
  toasts: [],
  push: (message, kind = 'success') => {
    const id = createId()
    set({ toasts: [...get().toasts, { id, message, kind }] })
    setTimeout(() => get().dismiss(id), 2600)
  },
  dismiss: (id) => set({ toasts: get().toasts.filter((t) => t.id !== id) }),
}))

export const toast = {
  success: (message: string) => useToastStore.getState().push(message, 'success'),
  info: (message: string) => useToastStore.getState().push(message, 'info'),
  offline: (message: string) => useToastStore.getState().push(message, 'offline'),
  error: (message: string) => useToastStore.getState().push(message, 'error'),
}

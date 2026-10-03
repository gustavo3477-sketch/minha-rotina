import type { ReactNode } from 'react'

interface ModalProps {
  open: boolean
  onClose: () => void
  title?: string
  children: ReactNode
}

export function Modal({ open, onClose, title, children }: ModalProps) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-6">
      <button
        aria-label="Fechar"
        onClick={onClose}
        className="absolute inset-0 bg-black/60 backdrop-blur-[1px]"
      />
      <div className="relative z-10 w-full max-w-sm rounded-3xl border border-border/60 bg-surface p-5">
        {title && <h2 className="mb-2 text-base font-semibold text-text-primary">{title}</h2>}
        {children}
      </div>
    </div>
  )
}

import { Calendar, Home, ListChecks, Menu, Plus } from 'lucide-react'
import { NavLink, useNavigate } from 'react-router-dom'

const NAV_ITEMS = [
  { to: '/', label: 'Hoje', icon: Home, end: true },
  { to: '/calendario', label: 'Calendário', icon: Calendar, end: false },
]

const NAV_ITEMS_RIGHT = [
  { to: '/agenda', label: 'Agenda', icon: ListChecks, end: false },
  { to: '/mais', label: 'Mais', icon: Menu, end: false },
]

export function BottomNavigation() {
  const navigate = useNavigate()

  return (
    <nav className="fixed inset-x-0 bottom-0 z-40 border-t border-border/60 bg-surface/95 backdrop-blur-md pb-[env(safe-area-inset-bottom)]">
      <div className="mx-auto flex max-w-md items-center justify-between px-2">
        {NAV_ITEMS.map((item) => (
          <NavItem key={item.to} {...item} />
        ))}

        <button
          type="button"
          aria-label="Novo compromisso"
          onClick={() => navigate('/novo-compromisso')}
          className="relative -top-4 flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-primary text-white shadow-[0_8px_20px_rgba(59,130,246,0.45)] active:scale-95"
        >
          <Plus size={26} strokeWidth={2.5} />
        </button>

        {NAV_ITEMS_RIGHT.map((item) => (
          <NavItem key={item.to} {...item} />
        ))}
      </div>
    </nav>
  )
}

function NavItem({
  to,
  label,
  icon: Icon,
  end,
}: {
  to: string
  label: string
  icon: typeof Home
  end: boolean
}) {
  return (
    <NavLink
      to={to}
      end={end}
      className="flex flex-1 flex-col items-center gap-1 py-2.5 text-[11px] font-medium"
    >
      {({ isActive }) => (
        <>
          <Icon size={22} strokeWidth={2} className={isActive ? 'text-primary' : 'text-text-muted'} />
          <span className={isActive ? 'text-primary' : 'text-text-muted'}>{label}</span>
        </>
      )}
    </NavLink>
  )
}

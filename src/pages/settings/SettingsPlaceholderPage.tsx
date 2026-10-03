import { useParams } from 'react-router-dom'
import { AppHeader } from '../../components/layout/AppHeader'
import { AccountSection } from './sections/AccountSection'
import { CategoriesSection } from './sections/CategoriesSection'
import { NotificationsSection } from './sections/NotificationsSection'
import { AppearanceSection } from './sections/AppearanceSection'
import { DataBackupSection } from './sections/DataBackupSection'
import { PwaSection } from './sections/PwaSection'
import { AboutSection } from './sections/AboutSection'

const SECTION_TITLES: Record<string, string> = {
  'minha-conta': 'Minha conta',
  categorias: 'Categorias',
  notificacoes: 'Notificações',
  aparencia: 'Aparência',
  'dados-backup': 'Dados e backup',
  pwa: 'PWA / Instalação',
  sobre: 'Sobre',
}

export function SettingsPlaceholderPage() {
  const { section = '' } = useParams<{ section: string }>()

  return (
    <div className="flex flex-col gap-5 pb-8">
      <AppHeader showBack title={SECTION_TITLES[section] ?? 'Configurações'} />
      <div className="px-5">
        {section === 'minha-conta' && <AccountSection />}
        {section === 'categorias' && <CategoriesSection />}
        {section === 'notificacoes' && <NotificationsSection />}
        {section === 'aparencia' && <AppearanceSection />}
        {section === 'dados-backup' && <DataBackupSection />}
        {section === 'pwa' && <PwaSection />}
        {section === 'sobre' && <AboutSection />}
      </div>
    </div>
  )
}

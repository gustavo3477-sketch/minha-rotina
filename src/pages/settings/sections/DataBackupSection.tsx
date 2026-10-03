import { useRef, useState } from 'react'
import { Download, TriangleAlert, Upload } from 'lucide-react'
import { db } from '../../../lib/db'
import { useAppStore } from '../../../store/appStore'
import { toast } from '../../../store/toastStore'
import { Card } from '../../../components/ui/Card'
import { PrimaryButton } from '../../../components/ui/PrimaryButton'
import { Modal } from '../../../components/ui/Modal'

export function DataBackupSection() {
  const hydrate = useAppStore((s) => s.hydrate)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [confirmResetOpen, setConfirmResetOpen] = useState(false)

  async function handleExport() {
    const backup = {
      exportedAt: new Date().toISOString(),
      dayTypes: await db.dayTypes.toArray(),
      scheduleVersions: await db.scheduleVersions.toArray(),
      scheduleExceptions: await db.scheduleExceptions.toArray(),
      categories: await db.categories.toArray(),
      appointments: await db.appointments.toArray(),
      dayNotes: await db.dayNotes.toArray(),
    }
    const blob = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `minha-rotina-backup-${new Date().toISOString().slice(0, 10)}.json`
    a.click()
    URL.revokeObjectURL(url)
    toast.success('Backup exportado')
  }

  async function handleImportFile(file: File) {
    try {
      const text = await file.text()
      const data = JSON.parse(text)
      await db.transaction(
        'rw',
        [db.dayTypes, db.scheduleVersions, db.scheduleExceptions, db.categories, db.appointments, db.dayNotes],
        async () => {
          await Promise.all([
            db.dayTypes.clear(),
            db.scheduleVersions.clear(),
            db.scheduleExceptions.clear(),
            db.categories.clear(),
            db.appointments.clear(),
            db.dayNotes.clear(),
          ])
          if (data.dayTypes) await db.dayTypes.bulkAdd(data.dayTypes)
          if (data.scheduleVersions) await db.scheduleVersions.bulkAdd(data.scheduleVersions)
          if (data.scheduleExceptions) await db.scheduleExceptions.bulkAdd(data.scheduleExceptions)
          if (data.categories) await db.categories.bulkAdd(data.categories)
          if (data.appointments) await db.appointments.bulkAdd(data.appointments)
          if (data.dayNotes) await db.dayNotes.bulkAdd(data.dayNotes)
        },
      )
      await hydrate()
      toast.success('Backup restaurado')
    } catch {
      toast.error('Arquivo de backup inválido')
    }
  }

  async function handleReset() {
    await db.delete()
    localStorage.removeItem('minha-rotina:userName')
    localStorage.removeItem('minha-rotina:onboardingCompleted')
    window.location.reload()
  }

  return (
    <div className="flex flex-col gap-4">
      <Card padding="lg" className="flex flex-col gap-3">
        <div>
          <p className="text-[15px] font-medium text-text-primary">Exportar backup</p>
          <p className="text-xs text-text-secondary">Salva um arquivo .json com toda a sua escala e compromissos.</p>
        </div>
        <PrimaryButton variant="secondary" onClick={handleExport}>
          <Download size={16} />
          Exportar dados
        </PrimaryButton>
      </Card>

      <Card padding="lg" className="flex flex-col gap-3">
        <div>
          <p className="text-[15px] font-medium text-text-primary">Restaurar backup</p>
          <p className="text-xs text-text-secondary">Substitui os dados atuais pelos dados do arquivo selecionado.</p>
        </div>
        <PrimaryButton variant="secondary" onClick={() => fileInputRef.current?.click()}>
          <Upload size={16} />
          Selecionar arquivo
        </PrimaryButton>
        <input
          ref={fileInputRef}
          type="file"
          accept="application/json"
          className="hidden"
          onChange={(e) => {
            const file = e.target.files?.[0]
            if (file) handleImportFile(file)
            e.target.value = ''
          }}
        />
      </Card>

      <Card padding="lg" className="flex flex-col gap-3 border-danger/30">
        <div>
          <p className="text-[15px] font-medium text-text-primary">Apagar todos os dados</p>
          <p className="text-xs text-text-secondary">Remove permanentemente sua escala, compromissos e preferências deste dispositivo.</p>
        </div>
        <PrimaryButton
          className="!bg-danger/15 !text-danger active:!bg-danger/25"
          variant="secondary"
          onClick={() => setConfirmResetOpen(true)}
        >
          Apagar dados
        </PrimaryButton>
      </Card>

      <Modal open={confirmResetOpen} onClose={() => setConfirmResetOpen(false)} title="Apagar todos os dados?">
        <div className="flex flex-col gap-4">
          <div className="flex gap-3 rounded-2xl bg-danger/10 p-3">
            <TriangleAlert size={18} className="mt-0.5 shrink-0 text-danger" />
            <p className="text-sm text-text-secondary">
              Esta ação não pode ser desfeita. Considere exportar um backup antes.
            </p>
          </div>
          <div className="flex gap-3">
            <PrimaryButton variant="secondary" onClick={() => setConfirmResetOpen(false)}>
              Cancelar
            </PrimaryButton>
            <PrimaryButton className="!bg-danger active:!bg-danger/80" onClick={handleReset}>
              Apagar
            </PrimaryButton>
          </div>
        </div>
      </Modal>
    </div>
  )
}

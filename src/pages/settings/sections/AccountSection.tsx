import { useState } from 'react'
import { User } from 'lucide-react'
import { useAppStore } from '../../../store/appStore'
import { toast } from '../../../store/toastStore'
import { FormField, TextInput } from '../../../components/ui/FormField'
import { Card } from '../../../components/ui/Card'

export function AccountSection() {
  const userName = useAppStore((s) => s.userName)
  const setUserName = useAppStore((s) => s.setUserName)
  const [name, setName] = useState(userName)

  return (
    <div className="flex flex-col gap-4">
      <Card padding="lg" className="flex flex-col items-center gap-3 text-center">
        <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/15 text-primary">
          <User size={28} />
        </div>
        <p className="text-sm text-text-secondary">Seus dados ficam salvos apenas neste dispositivo.</p>
      </Card>

      <FormField label="Nome de exibição">
        <TextInput
          value={name}
          onChange={(e) => setName(e.target.value)}
          onBlur={() => {
            if (name.trim() && name !== userName) {
              setUserName(name.trim())
              toast.success('Salvo')
            }
          }}
        />
      </FormField>
    </div>
  )
}

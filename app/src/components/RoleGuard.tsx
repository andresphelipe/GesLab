import { Navigate } from 'react-router-dom'
import { usePerfil } from '@/hooks/usePerfil'
import type { RolUsuario } from '@/lib/types'

interface Props {
  roles: RolUsuario[]
  children: React.ReactNode
}

export default function RoleGuard({ roles, children }: Props) {
  const { perfil, cargando } = usePerfil()

  if (cargando) return null

  if (!perfil || !roles.includes(perfil.rol)) {
    return <Navigate to="/" replace />
  }

  return <>{children}</>
}

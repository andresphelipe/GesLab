import { useAuth } from '@/hooks/useAuth'
import type { RolUsuario } from '@/lib/types'

export function usePerfil() {
  const { perfil, cargando } = useAuth()

  const tieneRol = (...roles: RolUsuario[]) =>
    perfil ? roles.includes(perfil.rol) : false

  const esPersonal = tieneRol('tecnico', 'admin')
  const esAdmin = tieneRol('admin')
  const esDocente = tieneRol('docente')

  return { perfil, cargando, tieneRol, esPersonal, esAdmin, esDocente }
}

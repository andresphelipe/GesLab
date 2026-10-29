import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { RolUsuario } from '@/lib/types'

export interface UsuarioRow {
  id: string
  nombre: string
  email: string
  celular: string | null
  rol: RolUsuario
  activo: boolean
  creado_en: string
}
export interface InvitacionRow {
  id: string
  email: string
  rol: RolUsuario
  nombre: string | null
  creado_en: string
  usada_en: string | null
}
export interface LabAdminRow {
  id: string
  nombre: string
  ubicacion: string | null
  capacidad: number | null
  activo: boolean
  campus_id: string | null
}

export function useUsuarios() {
  return useQuery<UsuarioRow[]>({
    queryKey: ['admin-usuarios'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('perfiles')
        .select('id, nombre, email, celular, rol, activo, creado_en')
        .order('creado_en', { ascending: false })
        .limit(2000)
      if (error) throw error
      return (data ?? []) as UsuarioRow[]
    },
  })
}

export function useInvitaciones() {
  return useQuery<InvitacionRow[]>({
    queryKey: ['admin-invitaciones'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('invitaciones')
        .select('id, email, rol, nombre, creado_en, usada_en')
        .is('usada_en', null)
        .order('creado_en', { ascending: false })
      if (error) throw error
      return (data ?? []) as InvitacionRow[]
    },
  })
}

export function useAdminMutaciones() {
  const qc = useQueryClient()
  const refrescar = () => {
    for (const k of ['admin-usuarios', 'admin-invitaciones', 'admin-labs', 'laboratorios', 'campus'])
      qc.invalidateQueries({ queryKey: [k] })
  }
  return {
    actualizarUsuario: useMutation({
      mutationFn: async (v: { id: string; cambios: Partial<Pick<UsuarioRow, 'rol' | 'activo' | 'nombre' | 'celular'>> }) => {
        const { error } = await supabase.from('perfiles').update(v.cambios).eq('id', v.id)
        if (error) throw error
      },
      onSuccess: refrescar,
    }),
    invitar: useMutation({
      mutationFn: async (v: { email: string; rol: RolUsuario; nombre?: string }) => {
        const { data, error } = await supabase.rpc('invitar_usuario', { p_email: v.email, p_rol: v.rol, p_nombre: v.nombre ?? null })
        if (error) throw error
        return data as 'actualizado' | 'invitado'
      },
      onSuccess: refrescar,
    }),
    quitarInvitacion: useMutation({
      mutationFn: async (id: string) => {
        const { error } = await supabase.from('invitaciones').delete().eq('id', id)
        if (error) throw error
      },
      onSuccess: refrescar,
    }),
    crearLab: useMutation({
      mutationFn: async (v: { nombre: string; campus_id: string; capacidad: number | null; ubicacion: string | null }) => {
        const { error } = await supabase.from('laboratorios').insert(v)
        if (error) throw error
      },
      onSuccess: refrescar,
    }),
    actualizarLab: useMutation({
      mutationFn: async (v: { id: string; cambios: Partial<Omit<LabAdminRow, 'id'>> }) => {
        const { error } = await supabase.from('laboratorios').update(v.cambios).eq('id', v.id)
        if (error) throw error
      },
      onSuccess: refrescar,
    }),
  }
}

export function useLabsAdmin() {
  return useQuery<LabAdminRow[]>({
    queryKey: ['admin-labs'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('laboratorios')
        .select('id, nombre, ubicacion, capacidad, activo, campus_id')
        .order('nombre')
      if (error) throw error
      return (data ?? []) as LabAdminRow[]
    },
  })
}

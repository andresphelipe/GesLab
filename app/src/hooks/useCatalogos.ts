import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export interface PracticaRow {
  id: string
  nombre: string
  asignatura: string | null
  programa: string | null
  activa: boolean
}

export interface CampusRow {
  id: string
  nombre: string
  orden: number
}

export interface LaboratorioRow {
  id: string
  nombre: string
  ubicacion: string | null
  capacidad: number | null
  activo: boolean
}

export interface GrupoRow {
  id: string
  nombre: string
  periodo: string
  docente_id: string
}

export function usePracticas() {
  return useQuery<PracticaRow[]>({
    queryKey: ['practicas'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('practicas')
        .select('id, nombre, asignatura, programa, activa')
        .eq('activa', true)
        .order('nombre')
      if (error) throw error
      return data ?? []
    },
  })
}

export function useLaboratorios() {
  return useQuery<LaboratorioRow[]>({
    queryKey: ['laboratorios'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('laboratorios')
        .select('id, nombre, ubicacion, capacidad, activo')
        .eq('activo', true)
        .order('nombre')
      if (error) throw error
      return data ?? []
    },
  })
}

export function useGrupos() {
  return useQuery<GrupoRow[]>({
    queryKey: ['grupos'],
    queryFn: async () => {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return []
      const { data, error } = await supabase
        .from('grupos')
        .select('id, nombre, periodo, docente_id')
        .eq('docente_id', user.id)
        .order('nombre')
      if (error) throw error
      return data ?? []
    },
  })
}

export function useCampus() {
  return useQuery<CampusRow[]>({
    queryKey: ['campus'],
    staleTime: 1000 * 60 * 30,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('campus')
        .select('id, nombre, orden')
        .order('orden')
      if (error) throw error
      return data ?? []
    },
  })
}

/** Nombres que el sistema ya reconoce (equivalencias) y nombres del catálogo, para sugerir y validar. */
export function useReconocimiento() {
  return useQuery({
    queryKey: ['reconocimiento'],
    staleTime: 1000 * 60 * 5,
    queryFn: async () => {
      const [ar, am, cr, cm] = await Promise.all([
        supabase.from('alias_reactivos').select('alias').limit(5000),
        supabase.from('alias_materiales').select('alias').limit(5000),
        supabase.from('catalogo_reactivos').select('nombre').eq('activo', true).order('nombre').limit(2000),
        supabase.from('catalogo_materiales').select('nombre').eq('activo', true).order('nombre').limit(2000),
      ])
      for (const r of [ar, am, cr, cm]) if (r.error) throw r.error
      return {
        aliasReactivos: new Set((ar.data ?? []).map((x) => x.alias as string)),
        aliasMateriales: new Set((am.data ?? []).map((x) => x.alias as string)),
        nombresReactivos: (cr.data ?? []).map((x) => x.nombre as string),
        nombresMateriales: (cm.data ?? []).map((x) => x.nombre as string),
      }
    },
  })
}

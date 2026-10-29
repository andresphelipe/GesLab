import { useMutation, useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export type Dominio = {
  id: string
  nombre: string
  descripcion: string | null
  tabla: string
  roles_permitidos: string[]
}

export type Dimension = {
  id: string
  dominio_id: string
  campo_sql: string
  tipo: 'uuid' | 'text' | 'date' | 'timestamp' | 'int' | 'numeric' | 'boolean' | 'text[]'
  etiqueta: string
  roles_permitidos: string[]
  autocomplete_sql: string | null
  orden: number
}

export type Metrica = {
  id: string
  dominio_id: string
  agregacion: 'sum' | 'avg' | 'count' | 'count_distinct' | 'min' | 'max' | 'custom'
  expresion_sql: string
  etiqueta: string
  unidad: string | null
  formato: 'numero' | 'entero' | 'decimal' | 'moneda' | 'porcentaje' | 'duracion'
  roles_permitidos: string[]
  orden: number
}

export type Operador =
  | 'eq' | 'ne' | 'lt' | 'lte' | 'gt' | 'gte'
  | 'in' | 'not_in' | 'between'
  | 'contains' | 'starts_with' | 'ends_with'
  | 'is_null' | 'is_not_null'

export type Filtro = { campo: string; op: Operador; valor?: unknown }
export type OrdenSpec = { campo: string; dir: 'asc' | 'desc' }

export type SpecInforme = {
  dominio: string
  metricas: string[]
  dimensiones: string[]
  filtros: Filtro[]
  orden?: OrdenSpec[]
  limite?: number
}

export type ResultadoInforme = {
  dominio: string
  tabla: string
  filas: Record<string, unknown>[]
  n_filas: number
  ejecutado_en: string
  duracion_ms: number
  spec: SpecInforme
}

export function useDominios() {
  return useQuery({
    queryKey: ['inf-dinamico-dominios'],
    queryFn: async () => {
      const { data, error } = await supabase.from('informes_dominios').select('*').eq('activo', true).order('nombre')
      if (error) throw error
      return (data ?? []) as Dominio[]
    },
    staleTime: 1000 * 60 * 10,
  })
}

export function useDimensiones(dominio: string | null) {
  return useQuery({
    queryKey: ['inf-dinamico-dim', dominio],
    enabled: !!dominio,
    queryFn: async () => {
      const { data, error } = await supabase.from('informes_dimensiones').select('*')
        .eq('dominio_id', dominio!).eq('activo', true).order('orden')
      if (error) throw error
      return (data ?? []) as Dimension[]
    },
    staleTime: 1000 * 60 * 10,
  })
}

export function useMetricas(dominio: string | null) {
  return useQuery({
    queryKey: ['inf-dinamico-met', dominio],
    enabled: !!dominio,
    queryFn: async () => {
      const { data, error } = await supabase.from('informes_metricas').select('*')
        .eq('dominio_id', dominio!).eq('activo', true).order('orden')
      if (error) throw error
      return (data ?? []) as Metrica[]
    },
    staleTime: 1000 * 60 * 10,
  })
}

export function useEjecutarInforme() {
  return useMutation({
    mutationFn: async (spec: SpecInforme) => {
      const { data, error } = await supabase.rpc('informe_dinamico', { p_spec: spec })
      if (error) throw error
      return data as ResultadoInforme
    },
  })
}

export type Favorito = {
  id: string
  usuario_id: string
  nombre: string
  descripcion: string | null
  dominio_id: string
  spec: SpecInforme
  compartido: boolean
  creado_en: string
  actualizado_en: string
}

export function useFavoritos() {
  return useQuery({
    queryKey: ['inf-favoritos'],
    queryFn: async () => {
      const { data, error } = await supabase.from('informes_favoritos').select('*').order('actualizado_en', { ascending: false })
      if (error) throw error
      return (data ?? []) as Favorito[]
    },
  })
}

export function useGuardarFavorito() {
  return useMutation({
    mutationFn: async (f: { nombre: string; descripcion?: string; dominio_id: string; spec: SpecInforme; compartido?: boolean }) => {
      const { data: usuario } = await supabase.auth.getUser()
      const uid = usuario.user?.id
      if (!uid) throw new Error('No hay sesión')
      const payload = { ...f, usuario_id: uid, actualizado_en: new Date().toISOString() }
      const { data, error } = await supabase.from('informes_favoritos').insert(payload).select().single()
      if (error) throw error
      return data as Favorito
    },
  })
}

export function useBorrarFavorito() {
  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from('informes_favoritos').delete().eq('id', id)
      if (error) throw error
      return id
    },
  })
}

// Formateo de valores según el tipo de métrica
export function formatearMetrica(valor: unknown, formato: Metrica['formato'], unidad: string | null): string {
  if (valor == null) return '—'
  const n = Number(valor)
  if (isNaN(n)) return String(valor)
  const base = (() => {
    switch (formato) {
      case 'entero':     return new Intl.NumberFormat('es-CO', { maximumFractionDigits: 0 }).format(n)
      case 'decimal':    return new Intl.NumberFormat('es-CO', { maximumFractionDigits: 2 }).format(n)
      case 'moneda':     return new Intl.NumberFormat('es-CO', { style: 'currency', currency: unidad || 'COP', maximumFractionDigits: 0 }).format(n)
      case 'porcentaje': return `${new Intl.NumberFormat('es-CO', { maximumFractionDigits: 1 }).format(n)}%`
      case 'duracion':   return `${new Intl.NumberFormat('es-CO', { maximumFractionDigits: 1 }).format(n)} h`
      default:           return new Intl.NumberFormat('es-CO', { maximumFractionDigits: 2 }).format(n)
    }
  })()
  if (formato === 'porcentaje' || formato === 'moneda' || formato === 'duracion') return base
  if (unidad) return `${base} ${unidad}`
  return base
}

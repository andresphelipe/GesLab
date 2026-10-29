import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { EstadoSesion } from '@/lib/types'

export interface SesionRow {
  id: string
  practica_id: string | null
  docente_id: string
  laboratorio_id: string | null
  campus_id: string | null
  programa_academico: string | null
  curso: string | null
  agua_destilada_l: number | null
  motivo_rechazo: string | null
  grupo_id: string | null
  num_estudiantes: number | null
  num_grupos_trabajo: number | null
  inicio: string
  fin: string
  estado: EstadoSesion
  observaciones: string | null
  origen: string
  aprobado_por: string | null
  aprobado_en: string | null
  creado_en: string
  practicas: { nombre: string } | null
  docente: { nombre: string; email: string | null; celular: string | null } | null
  laboratorios: { nombre: string } | null
  campus: { nombre: string } | null
  grupos: { nombre: string } | null
  pendientes: { id: string; resuelta: boolean }[] | null
}

export interface FiltrosSesion {
  estado?: EstadoSesion
  campusId?: string
  desde?: string // AAAA-MM-DD (hora de Colombia)
  hasta?: string // AAAA-MM-DD
  soloMias?: boolean
}

const SELECT = `
  *,
  practicas ( nombre ),
  docente:perfiles!sesiones_practica_docente_id_fkey ( nombre, email, celular ),
  laboratorios ( nombre ),
  campus ( nombre ),
  grupos ( nombre ),
  pendientes:lineas_pendientes ( id, resuelta )
`

export const LIMITE_SESIONES = 500

export function useSesiones(filtros?: FiltrosSesion) {
  return useQuery<SesionRow[]>({
    queryKey: ['sesiones', filtros],
    queryFn: async () => {
      let q = supabase
        .from('sesiones_practica')
        .select(SELECT)
        .order('inicio', { ascending: true })
        .limit(LIMITE_SESIONES)

      if (filtros?.estado) q = q.eq('estado', filtros.estado)
      if (filtros?.campusId) q = q.eq('campus_id', filtros.campusId)
      if (filtros?.desde) q = q.gte('inicio', `${filtros.desde}T00:00:00-05:00`)
      if (filtros?.hasta) q = q.lte('inicio', `${filtros.hasta}T23:59:59-05:00`)
      if (filtros?.soloMias) {
        const { data: { user } } = await supabase.auth.getUser()
        if (user) q = q.eq('docente_id', user.id)
      }

      const { data, error } = await q
      if (error) throw error
      return (data ?? []) as unknown as SesionRow[]
    },
  })
}

export function useSesion(id: string | undefined) {
  return useQuery<SesionRow>({
    queryKey: ['sesion', id],
    enabled: !!id,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('sesiones_practica')
        .select(SELECT)
        .eq('id', id!)
        .single()
      if (error) throw error
      return data as unknown as SesionRow
    },
  })
}

export function useReactivosSesion(sesionId: string | undefined) {
  return useQuery({
    queryKey: ['sesion-reactivos', sesionId],
    enabled: !!sesionId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('sesion_reactivos')
        .select('id, reactivo_id, cantidad_prevista, cantidad_consumida, unidad, concentracion, texto_original, catalogo_reactivos ( nombre, formula, unidad )')
        .eq('sesion_id', sesionId!)
      if (error) throw error
      return (data ?? []) as any[]
    },
  })
}

export function useMaterialesSesion(sesionId: string | undefined) {
  return useQuery({
    queryKey: ['sesion-materiales', sesionId],
    enabled: !!sesionId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('sesion_materiales')
        .select('id, material_id, cantidad_prevista, cantidad_consumida, texto_original, catalogo_materiales ( nombre, tipo_item )')
        .eq('sesion_id', sesionId!)
      if (error) throw error
      return (data ?? []) as any[]
    },
  })
}

export function usePendientesSesion(sesionId: string | undefined) {
  return useQuery({
    queryKey: ['sesion-pendientes', sesionId],
    enabled: !!sesionId,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('lineas_pendientes')
        .select('id, tipo, texto_original, cantidad, unidad, concentracion')
        .eq('sesion_id', sesionId!)
        .eq('resuelta', false)
      if (error) throw error
      return (data ?? []) as any[]
    },
  })
}

/* ------------------------------------------------------------------ */
/* Crear solicitud: misma función de la base que usará el Excel        */
/* ------------------------------------------------------------------ */

export interface LineaPayload {
  texto: string
  cantidad?: number
  cantidad_por_mesa?: number
  unidad?: string
  concentracion?: string
}

export interface JornadaPayload {
  fecha: string
  inicio: string
  fin: string
  num_estudiantes?: number | null
  num_grupos_trabajo?: number | null
}

export interface CrearSesionInput {
  estado: 'borrador' | 'solicitada'
  practica_nombre: string
  campus_id: string | null
  programa_academico: string
  curso: string
  agua_destilada_l: number | null
  fecha: string
  inicio: string
  fin: string
  num_estudiantes: number | null
  num_grupos_trabajo: number | null
  observaciones: string
  otras_jornadas: JornadaPayload[]
  reactivos: LineaPayload[]
  materiales: LineaPayload[]
}

export interface ResultadoCrear {
  sesion_id: string
  sesion_ids: string[]
  sesiones_creadas: number
  reactivos_vinculados: number
  reactivos_pendientes: number
  materiales_vinculados: number
  materiales_pendientes: number
}

export function useCrearSesion() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (input: CrearSesionInput) => {
      const { data, error } = await supabase.rpc('importar_formulario', {
        p: { ...input, origen: 'app' },
      })
      if (error) throw error
      return data as ResultadoCrear
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['sesiones'] })
      qc.invalidateQueries({ queryKey: ['alertas-tecnico'] })
      qc.invalidateQueries({ queryKey: ['resumen-docente'] })
    },
  })
}

/* ------------------------------------------------------------------ */
/* Decidir una o varias sesiones                                       */
/* ------------------------------------------------------------------ */

export interface ResultadoDecision {
  aplicadas: number
  resultados: { id: string; ok: boolean; mensaje: string | null; avisos?: { tipo: string; item: string; estado: string; mensaje: string | null }[] }[]
}

export function useDecidirSesiones() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (v: {
      ids: string[]
      decision: 'aprobada' | 'rechazada'
      motivo?: string
      laboratorioId?: string | null
      soloSiDisponible?: boolean
    }) => {
      const { data, error } = await supabase.rpc('decidir_sesiones', {
        p_ids: v.ids,
        p_decision: v.decision,
        p_motivo: v.motivo ?? null,
        p_laboratorio: v.laboratorioId ?? null,
        p_solo_si_disponible: v.soloSiDisponible ?? false,
      })
      if (error) throw error
      return data as ResultadoDecision
    },
    onSuccess: invalidarSesiones(qc),
  })
}

export function useDeshacerDecision() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (ids: string[]) => {
      const { data, error } = await supabase.rpc('deshacer_decision', { p_ids: ids })
      if (error) throw error
      return data as number
    },
    onSuccess: invalidarSesiones(qc),
  })
}

function invalidarSesiones(qc: ReturnType<typeof useQueryClient>) {
  return () => {
    qc.invalidateQueries({ queryKey: ['sesiones'] })
    qc.invalidateQueries({ queryKey: ['sesion'] })
    qc.invalidateQueries({ queryKey: ['alertas-tecnico'] })
    qc.invalidateQueries({ queryKey: ['disponibilidad'] })
  }
}

/* ------------------------------------------------------------------ */
/* Edición por el personal y líneas pendientes                         */
/* ------------------------------------------------------------------ */

export interface EditarSesionInput {
  practica_nombre?: string
  campus_id?: string | null
  laboratorio_id?: string | null
  programa_academico?: string
  curso?: string
  agua_destilada_l?: number | null
  fecha?: string
  inicio?: string
  fin?: string
  num_estudiantes?: number | null
  num_grupos_trabajo?: number | null
  observaciones?: string
  reactivos?: { id?: string; texto?: string; cantidad?: number | null; unidad?: string | null; concentracion?: string | null }[]
  materiales?: { id?: string; texto?: string; cantidad?: number | null }[]
}

export function useEditarSesion() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (v: { id: string; cambios: EditarSesionInput }) => {
      const { data, error } = await supabase.rpc('editar_sesion', { p_id: v.id, p: v.cambios })
      if (error) throw error
      return data as { ok: boolean; pendientes_nuevas: number; avisos: { tipo: string; item: string; estado: string; mensaje: string | null }[] }
    },
    onSuccess: () => {
      for (const k of ['sesiones', 'sesion', 'sesion-reactivos', 'sesion-materiales', 'sesion-pendientes', 'disponibilidad'])
        qc.invalidateQueries({ queryKey: [k] })
    },
  })
}

export function useResolverPendiente() {
  const qc = useQueryClient()
  const refrescar = () => {
    for (const k of ['sesion-reactivos', 'sesion-materiales', 'sesion-pendientes', 'sesiones', 'disponibilidad', 'reconocimiento'])
      qc.invalidateQueries({ queryKey: [k] })
  }
  return {
    vincular: useMutation({
      mutationFn: async (v: { id: string; itemId: string }) => {
        const { error } = await supabase.rpc('vincular_pendiente', { p_id: v.id, p_item: v.itemId })
        if (error) throw error
      },
      onSuccess: refrescar,
    }),
    descartar: useMutation({
      mutationFn: async (id: string) => {
        const { error } = await supabase.rpc('descartar_pendiente', { p_id: id })
        if (error) throw error
      },
      onSuccess: refrescar,
    }),
  }
}

/** Catálogos con id, para vincular líneas pendientes. */
export function useCatalogoItems() {
  return useQuery({
    queryKey: ['catalogo-items'],
    staleTime: 1000 * 60 * 5,
    queryFn: async () => {
      const [r, m] = await Promise.all([
        supabase.from('catalogo_reactivos').select('id, nombre').eq('activo', true).order('nombre').limit(3000),
        supabase.from('catalogo_materiales').select('id, nombre').eq('activo', true).order('nombre').limit(3000),
      ])
      if (r.error) throw r.error
      if (m.error) throw m.error
      return { reactivos: (r.data ?? []) as { id: string; nombre: string }[], materiales: (m.data ?? []) as { id: string; nombre: string }[] }
    },
  })
}

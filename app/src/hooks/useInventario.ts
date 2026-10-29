import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export interface LineaDisponibilidad {
  sesion_id: string
  tipo: 'reactivo' | 'equipo' | 'vidrieria'
  item_id: string
  item: string
  unidad: string | null
  solicitado: number | null
  disponible: number | null
  faltante: number | null
  estado: 'ok' | 'ok_traslado' | 'falta' | 'sin_cantidad' | 'sin_unidad' | 'sin_campus'
  mensaje: string | null
}

/** Compara lo solicitado con lo que hay en la sede (solo personal: la RLS oculta el inventario al resto). */
export function useDisponibilidad(ids: string[], activo = true) {
  const clave = [...ids].sort()
  return useQuery<LineaDisponibilidad[]>({
    queryKey: ['disponibilidad', clave],
    enabled: activo && ids.length > 0,
    staleTime: 15_000,
    queryFn: async () => {
      const { data, error } = await supabase.rpc('disponibilidad_sesiones', { p_ids: clave })
      if (error) throw error
      return (data ?? []) as LineaDisponibilidad[]
    },
  })
}

export function resumenDisponibilidad(lineas: LineaDisponibilidad[] | undefined) {
  const por = new Map<string, LineaDisponibilidad[]>()
  for (const l of lineas ?? []) por.set(l.sesion_id, [...(por.get(l.sesion_id) ?? []), l])
  let conFaltantes = 0
  let conTraslado = 0
  for (const ls of por.values()) {
    if (ls.some((l) => l.estado === 'falta')) conFaltantes++
    else if (ls.some((l) => l.estado === 'ok_traslado')) conTraslado++
  }
  return { porSesion: por, conFaltantes, conTraslado }
}

/** Trae todas las filas (la API devuelve 1000 como máximo por consulta). */
async function traerTodo(construir: () => any): Promise<any[]> {
  const out: any[] = []
  for (let desde = 0; ; desde += 1000) {
    const { data, error } = await construir().range(desde, desde + 999)
    if (error) throw error
    out.push(...(data ?? []))
    if (!data || data.length < 1000) break
  }
  return out
}

export function useEnvases(campusId: string | undefined) {
  return useQuery({
    queryKey: ['inv-envases', campusId],
    enabled: !!campusId,
    queryFn: () =>
      traerTodo(() =>
        supabase
          .from('envases')
          .select('id, id_inventario, lote, cantidad_actual, cantidad_inicial, estado, fecha_caducidad, ubicacion_texto, revisar, motivo_revision, base_existencia, catalogo_reactivos ( nombre, formula, unidad )')
          .eq('campus_id', campusId!)
          .order('id_inventario'),
      ),
  })
}

export function useEquiposInv(campusId: string | undefined) {
  return useQuery({
    queryKey: ['inv-equipos', campusId],
    enabled: !!campusId,
    queryFn: () =>
      traerTodo(() =>
        supabase
          .from('equipos')
          .select('id, id_inventario, nombre, marca, modelo, salon, area, cantidad, estado, condicion, fuera_de_sede, revisar, motivo_revision')
          .eq('campus_id', campusId!)
          .order('id_inventario'),
      ),
  })
}

export function useVidrieriaInv(campusId: string | undefined) {
  return useQuery({
    queryKey: ['inv-vidrieria', campusId],
    enabled: !!campusId,
    queryFn: () =>
      traerTodo(() =>
        supabase
          .from('existencias_material')
          .select('id, id_inventario, cantidad_buena, cantidad_regular, cantidad_danada, ubicacion, catalogo_materiales ( nombre )')
          .eq('campus_id', campusId!)
          .order('id_inventario'),
      ),
  })
}

export interface ConsumoInput {
  sesionId: string
  reactivos: { reactivo_id: string; cantidad: number; unidad?: string }[]
  materiales: { material_id: string; cantidad: number }[]
  finalizar: boolean
}

export function useRegistrarConsumo() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: async (v: ConsumoInput) => {
      const { data, error } = await supabase.rpc('registrar_consumo', {
        p_sesion: v.sesionId,
        p_reactivos: v.reactivos,
        p_materiales: v.materiales,
        p_finalizar: v.finalizar,
      })
      if (error) throw error
      return data
    },
    onSuccess: () => {
      for (const k of ['sesion', 'sesiones', 'sesion-reactivos', 'sesion-materiales', 'disponibilidad', 'inv-envases', 'inv-vidrieria'])
        qc.invalidateQueries({ queryKey: [k] })
    },
  })
}

import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export type Filtro = { desde: string; hasta: string; campus_id: string | null }

export type KPIs = {
  sesiones_total: number
  sesiones_aprobadas: number
  sesiones_borrador: number
  sesiones_rechazadas: number
  docentes_activos: number
  estudiantes: number
  consumo_total: number
  previsto_total: number
  eficiencia: number | null
  incidencias_nuevas: number
  incidencias_abiertas: number
  envases_por_vencer: number
  envases_vigentes: number
  reactivos_catalogo: number
}

const args = (f: Filtro) => ({
  p_desde: f.desde,
  p_hasta: f.hasta,
  p_campus: f.campus_id,
})

async function rpc<T>(fn: string, params: Record<string, unknown>): Promise<T> {
  const r = await supabase.rpc(fn, params)
  if (r.error) throw r.error
  return r.data as T
}

export function useCampusList() {
  return useQuery({
    queryKey: ['campus-list'],
    queryFn: async () => {
      const { data, error } = await supabase.from('campus').select('id, nombre').order('nombre')
      if (error) throw error
      return (data ?? []) as { id: string; nombre: string }[]
    },
    staleTime: 1000 * 60 * 30,
  })
}

export function useKPIs(f: Filtro) {
  return useQuery({
    queryKey: ['inf-kpi', f],
    queryFn: () => rpc<KPIs>('informe_kpis', args(f)),
  })
}

export type SerieMes = {
  mes: string
  sesiones: number
  estudiantes: number
  consumo_g: number
  consumo_ml: number
  consumo_unidad: number
  previsto_g: number
  previsto_ml: number
}
export function useSerieMensual(f: Filtro) {
  return useQuery({
    queryKey: ['inf-serie', f],
    queryFn: () => rpc<SerieMes[]>('informe_serie_mensual', args(f)),
  })
}

export type TopReactivo = {
  reactivo_id: string; reactivo: string; cas: string | null; unidad: string
  sesiones: number; consumo: number; previsto: number; eficiencia: number | null
}
export function useTopReactivos(f: Filtro, limite = 15) {
  return useQuery({
    queryKey: ['inf-top-reac', f, limite],
    queryFn: () => rpc<TopReactivo[]>('informe_top_reactivos', { ...args(f), p_limite: limite }),
  })
}

export type TopMaterial = {
  material_id: string; material: string; tipo: string
  sesiones: number; consumo: number; previsto: number
}
export function useTopMateriales(f: Filtro, limite = 15) {
  return useQuery({
    queryKey: ['inf-top-mat', f, limite],
    queryFn: () => rpc<TopMaterial[]>('informe_top_materiales', { ...args(f), p_limite: limite }),
  })
}

export type TopDocente = {
  docente_id: string; docente: string; programa: string | null
  sesiones: number; estudiantes: number; horas: number
  consumo_g: number; consumo_ml: number
}
export function useTopDocentes(f: Filtro, limite = 15) {
  return useQuery({
    queryKey: ['inf-top-doc', f, limite],
    queryFn: () => rpc<TopDocente[]>('informe_top_docentes', { ...args(f), p_limite: limite }),
  })
}

export type TopPrograma = {
  programa: string; sesiones: number; estudiantes: number
  docentes: number; consumo_g: number; consumo_ml: number
}
export function useTopProgramas(f: Filtro) {
  return useQuery({
    queryKey: ['inf-top-prog', f],
    queryFn: () => rpc<TopPrograma[]>('informe_top_programas', args(f)),
  })
}

export type TopPractica = {
  practica_id: string | null; practica: string; sesiones: number; estudiantes: number
}
export function useTopPracticas(f: Filtro, limite = 15) {
  return useQuery({
    queryKey: ['inf-top-prac', f, limite],
    queryFn: () => rpc<TopPractica[]>('informe_top_practicas', { ...args(f), p_limite: limite }),
  })
}

export type UsoEquipo = {
  equipo_id: string; equipo: string; campus: string | null; laboratorio: string | null
  reservas: number; horas: number; estado: string
}
export function useUsoEquipos(f: Filtro, limite = 20) {
  return useQuery({
    queryKey: ['inf-eq', f, limite],
    queryFn: () => rpc<UsoEquipo[]>('informe_uso_equipos', { ...args(f), p_limite: limite }),
  })
}

export type FilaVidrieria = {
  campus: string; material: string
  buena: number; regular: number; dannada: number
  roturas: number; costo_roturas: number
}
export function useVidrieria(f: Filtro) {
  return useQuery({
    queryKey: ['inf-vid', f],
    queryFn: () => rpc<FilaVidrieria[]>('informe_vidrieria', args(f)),
  })
}

export type Cumplimiento = {
  total: number
  por_estado: Record<string, number>
  pct_aprobadas: number | null
  horas_aprobacion_prom: number | null
  horas_aprobacion_p50: number | null
  consumo_vs_previsto_pct: number | null
}
export function useCumplimiento(f: Filtro) {
  return useQuery({
    queryKey: ['inf-cum', f],
    queryFn: () => rpc<Cumplimiento>('informe_cumplimiento', args(f)),
  })
}

export type ProyFila = {
  mes: string; sesiones_prev: number
  consumo_g_prev: number; consumo_ml_prev: number
  es_proyeccion: boolean
}
export function useProyeccion(f: Filtro, meses = 3) {
  return useQuery({
    queryKey: ['inf-proy', f, meses],
    queryFn: () => rpc<ProyFila[]>('informe_proyeccion', { ...args(f), p_meses: meses }),
  })
}

export type Alertas = {
  por_vencer: { id: string; nombre: string; campus: string; fecha_caducidad: string; cantidad_actual: number; unidad: string }[]
  bajos_minimo: { id: string; nombre: string; unidad: string; stock_minimo: number; stock: number }[]
  alta_demanda: { reactivo_id: string; reactivo: string; unidad: string; consumo: number; consumo_mes: number }[]
}
export function useAlertasInforme(campus_id: string | null, dias = 180) {
  return useQuery({
    queryKey: ['inf-alertas', campus_id, dias],
    queryFn: () => rpc<Alertas>('informe_alertas', { p_campus: campus_id, p_dias_consumo: dias }),
  })
}

export type Heatmap = { dia_semana: number; hora: number; sesiones: number }
export function useHeatmap(f: Filtro) {
  return useQuery({
    queryKey: ['inf-heat', f],
    queryFn: () => rpc<Heatmap[]>('informe_heatmap_horario', args(f)),
  })
}

export type SesionDet = {
  sesion_id: string; fecha: string; campus: string; programa: string | null; curso: string | null
  docente: string | null; practica: string | null; estudiantes: number; estado: string
  reactivos: number; consumo_g: number; consumo_ml: number
}
export function useSesionesDetalle(f: Filtro) {
  return useQuery({
    queryKey: ['inf-det', f],
    queryFn: () => rpc<SesionDet[]>('informe_sesiones_detalle', args(f)),
  })
}

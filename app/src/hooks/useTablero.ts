import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export type SesionSemana = {
  sesion_id: string
  inicio: string
  fin: string
  practica: string
  docente: string
  laboratorio: string
  campus_id: string | null
  campus: string
  programa: string
  curso: string | null
  num_estudiantes: number
  estado: string
  dia_semana: number
  faltantes: number
  pendientes: number
}

export type ResumenInicio = {
  desde: string
  hasta: string
  sesiones: number
  estudiantes: number
  docentes: number
  pendientes: number
  envases_por_vencer: number
}

export function useTableroSemana(fecha: string, campus_id: string | null) {
  return useQuery({
    queryKey: ['tablero-semana', fecha, campus_id],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('tablero_semana', { p_fecha: fecha, p_campus: campus_id })
      if (error) throw error
      return (data ?? []) as SesionSemana[]
    },
  })
}

export function useInicioResumen(fecha: string, campus_id: string | null) {
  return useQuery({
    queryKey: ['inicio-resumen', fecha, campus_id],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('inicio_resumen', { p_fecha: fecha, p_campus: campus_id })
      if (error) throw error
      return data as ResumenInicio
    },
  })
}

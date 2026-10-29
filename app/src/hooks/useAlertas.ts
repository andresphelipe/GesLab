import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import type { AlertasDashboard, ResumenDocente } from '@/lib/types'
import { useAuth } from '@/hooks/useAuth'

export function useAlertasTecnico() {
  const { perfil } = useAuth()
  return useQuery<AlertasDashboard>({
    queryKey: ['alertas-tecnico'],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('obtener_alertas')
      if (error) throw error
      return data as unknown as AlertasDashboard
    },
    enabled: perfil?.rol === 'tecnico' || perfil?.rol === 'admin',
    refetchInterval: 1000 * 60 * 5, // cada 5 min
  })
}

export function useResumenDocente() {
  const { perfil } = useAuth()
  return useQuery<ResumenDocente>({
    queryKey: ['resumen-docente'],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('resumen_docente')
      if (error) throw error
      return data as unknown as ResumenDocente
    },
    enabled: perfil?.rol === 'docente',
    refetchInterval: 1000 * 60 * 5,
  })
}

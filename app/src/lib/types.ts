// Tipos manuales que reflejan el esquema de GesLab.
// En producción se pueden generar con: npx supabase gen types typescript

export type RolUsuario = 'estudiante' | 'docente' | 'tecnico' | 'admin'
export type EstadoSesion = 'borrador' | 'solicitada' | 'aprobada' | 'rechazada' | 'finalizada' | 'cancelada'
export type EstadoReserva = 'solicitada' | 'aprobada' | 'rechazada' | 'cancelada'
export type EstadoEquipo = 'operativo' | 'en_mantenimiento' | 'fuera_de_servicio' | 'baja'
export type EstadoEnvase = 'disponible' | 'en_uso' | 'agotado' | 'vencido' | 'baja'
export type TipoMov = 'entrada' | 'salida' | 'consumo' | 'ajuste_positivo' | 'ajuste_negativo' | 'residuo'
export type EstadoIncidencia = 'abierta' | 'en_proceso' | 'resuelta' | 'descartada'
export type Severidad = 'baja' | 'media' | 'alta' | 'critica'

export interface Perfil {
  id: string
  nombre: string
  email: string
  rol: RolUsuario
  documento?: string
  programa?: string
  celular?: string | null
  activo: boolean
  creado_en: string
}

export interface Laboratorio {
  id: string
  nombre: string
  ubicacion?: string
  capacidad?: number
  activo: boolean
}

export interface Campus {
  id: string
  nombre: string
  orden: number
}

export interface SesionPractica {
  id: string
  practica_id?: string
  docente_id: string
  laboratorio_id?: string          // lo asigna el personal al aprobar
  campus_id?: string
  programa_academico?: string
  curso?: string
  agua_destilada_l?: number
  motivo_rechazo?: string
  grupo_id?: string
  num_estudiantes?: number
  num_grupos_trabajo?: number
  inicio: string
  fin: string
  estado: EstadoSesion
  observaciones?: string
  origen: string
  aprobado_por?: string
  aprobado_en?: string
  creado_en: string
  // joins
  practica?: { nombre: string }
  docente?: { nombre: string }
  laboratorio?: { nombre: string }
}

export interface CatalogoReactivo {
  id: string
  nombre: string
  formula?: string
  cas?: string
  pictogramas: string[]
  clase_almacenamiento: string
  unidad: string
  stock_minimo: number
  es_controlado: boolean
  activo: boolean
}

export interface CatalogoMaterial {
  id: string
  nombre: string
  categoria?: string
  unidad: string
  stock_actual: number
  stock_minimo: number
  activo: boolean
}

export interface LineaPendiente {
  id: string
  sesion_id: string
  tipo: 'reactivo' | 'material'
  texto_original: string
  cantidad?: number
  unidad?: string
  concentracion?: string
  resuelta: boolean
}

export interface AlertasDashboard {
  permitido?: boolean
  stock_bajo_minimo: Array<{
    reactivo_id: string; nombre: string; cas?: string
    unidad: string; stock_total: number; stock_minimo: number
  }>
  materiales_bajo_minimo: Array<{
    id: string; nombre: string; categoria?: string
    stock_actual: number; stock_minimo: number
  }>
  proximos_a_vencer: Array<{
    envase_id: string; codigo: string; reactivo: string
    lote?: string; cantidad_actual: number; unidad: string
    fecha_caducidad: string; dias_restantes: number; ubicacion?: string
  }>
  equipos_mantenimiento: Array<{
    id: string; codigo: string; nombre: string
    estado: string; fecha_limite: string
  }>
  sesiones_pendientes: Array<{
    id: string; practica?: string; docente: string
    laboratorio?: string; campus?: string; inicio: string; fin: string
    num_estudiantes?: number; estado: string
  }>
  lineas_sin_vincular: number
  alertas_almacenamiento: Array<{
    codigo: string; reactivo: string; clase_reactivo: string
    ubicacion: string; clase_ubicacion: string
  }>
}

export interface ResumenDocente {
  sesiones_activas: Array<{
    id: string; practica?: string; laboratorio?: string; campus?: string
    inicio: string; fin: string; estado: string; num_estudiantes?: number
  }>
  proximas_7_dias: number
  mis_practicas: number
  mis_grupos: number
}

// Placeholder para supabase gen types
export type Database = Record<string, unknown>

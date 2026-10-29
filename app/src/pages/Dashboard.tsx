import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { usePerfil } from '@/hooks/usePerfil'
import { useCampusList } from '@/hooks/useInformes'
import { useAlertasInforme } from '@/hooks/useInformes'
import { SesionSemana, useInicioResumen, useTableroSemana } from '@/hooks/useTablero'

/* ---------- utilidades de fecha ---------- */
const DIAS = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
const MESES = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre']
const HORA_INI = 7
const HORA_FIN = 19
const PX_POR_HORA = 42

function lunesDe(d: Date) {
  const r = new Date(d)
  const dow = r.getDay() === 0 ? 7 : r.getDay()
  r.setDate(r.getDate() - (dow - 1))
  r.setHours(0, 0, 0, 0)
  return r
}
function sumarDias(d: Date, n: number) { const r = new Date(d); r.setDate(r.getDate() + n); return r }
function iso(d: Date) { return d.toISOString().slice(0, 10) }
function fmtRango(l: Date) {
  const s = l; const e = sumarDias(l, 5)
  if (s.getMonth() === e.getMonth()) {
    return `Semana del ${s.getDate()} al ${e.getDate()} de ${MESES[s.getMonth()]} de ${s.getFullYear()}`
  }
  return `Semana del ${s.getDate()} de ${MESES[s.getMonth()]} al ${e.getDate()} de ${MESES[e.getMonth()]}, ${s.getFullYear()}`
}
function mismosDia(a: Date, b: Date) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
}

/* color por programa (mismo nombre → mismo color) */
const COLORES_PROG = ['#0e5aa8', '#1b7a3e', '#7c3aed', '#c05621', '#047481', '#b45309']
function colorPrograma(nombre: string) {
  let h = 0; for (let i = 0; i < nombre.length; i++) h = (h * 31 + nombre.charCodeAt(i)) >>> 0
  return COLORES_PROG[h % COLORES_PROG.length]
}

/* ---------- componente principal ---------- */
export default function Dashboard() {
  const { perfil } = useAuth()
  const { tieneRol } = usePerfil()
  const esPersonal = tieneRol('tecnico') || tieneRol('admin')

  const [fecha, setFecha] = useState<Date>(() => new Date())
  const lunes = useMemo(() => lunesDe(fecha), [fecha])
  const hoy = useMemo(() => new Date(), [])

  const { data: campus } = useCampusList()
  const [campusId, setCampusId] = useState<string | null>(null)
  const [vista, setVista] = useState<'semana' | 'agenda' | 'laboratorio'>('semana')

  const sesiones = useTableroSemana(iso(lunes), campusId)
  const resumen  = useInicioResumen(iso(lunes), campusId)
  const alertas  = useAlertasInforme(campusId, 90)

  const bienvenida = perfil?.nombre?.split(' ')[0] ?? ''

  return (
    <div className="space-y-4 pb-20">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold">
            {bienvenida ? `Hola, ${bienvenida}` : 'Inicio'}
          </h1>
          <p className="text-sm text-gray-600">{fmtRango(lunes)}</p>
        </div>
        <div className="flex items-center gap-1">
          <button onClick={() => setFecha(sumarDias(lunes, -7))}
            className="rounded border border-gray-300 bg-white px-3 py-1 text-sm hover:bg-gray-50">◀ Anterior</button>
          <button onClick={() => setFecha(new Date())}
            className={`rounded border px-3 py-1 text-sm ${
              mismosDia(lunes, lunesDe(hoy))
                ? 'border-blue-600 bg-blue-600 text-white'
                : 'border-gray-300 bg-white hover:bg-gray-50'
            }`}>Esta semana</button>
          <button onClick={() => setFecha(sumarDias(lunes, 7))}
            className="rounded border border-gray-300 bg-white px-3 py-1 text-sm hover:bg-gray-50">Siguiente ▶</button>
        </div>
      </header>

      <KPIs resumen={resumen.data} alertas={alertas.data} />

      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap gap-1 text-sm">
          <Chip activo={campusId === null} onClick={() => setCampusId(null)}>Todos los campus</Chip>
          {(campus ?? []).map(c => (
            <Chip key={c.id} activo={campusId === c.id} onClick={() => setCampusId(c.id)}>{c.nombre}</Chip>
          ))}
        </div>
        <div className="inline-flex overflow-hidden rounded border border-gray-300 text-sm">
          {(['semana','agenda','laboratorio'] as const).map(k => (
            <button key={k} onClick={() => setVista(k)}
              className={`px-3 py-1 ${vista === k ? 'bg-blue-600 text-white' : 'bg-white text-gray-700 hover:bg-gray-50'}`}>
              {k === 'semana' ? 'Semana' : k === 'agenda' ? 'Agenda' : 'Por laboratorio'}
            </button>
          ))}
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-[1fr_280px]">
        <div>
          {vista === 'semana' && <VistaSemana sesiones={sesiones.data ?? []} lunes={lunes} hoy={hoy} />}
          {vista === 'agenda' && <VistaAgenda sesiones={sesiones.data ?? []} />}
          {vista === 'laboratorio' && <VistaLaboratorio sesiones={sesiones.data ?? []} />}
          <Leyenda />
        </div>
        <aside className="space-y-3">
          <Pendientes sesiones={sesiones.data ?? []} />
          {esPersonal && <AlertasInv alertas={alertas.data} />}
          <CargaCampus sesiones={sesiones.data ?? []} />
        </aside>
      </div>

      <Link to="/sesiones/nueva"
        className="fixed bottom-6 right-6 rounded-full bg-blue-600 px-5 py-3 font-semibold text-white shadow-lg hover:bg-blue-700">
        + Nueva solicitud
      </Link>
    </div>
  )
}

/* ---------- subcomponentes ---------- */
function Chip({ activo, onClick, children }: { activo: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button onClick={onClick}
      className={`rounded-full border px-3 py-1 ${
        activo ? 'border-blue-600 bg-blue-600 text-white' : 'border-gray-300 bg-white text-gray-600 hover:bg-gray-50'
      }`}>
      {children}
    </button>
  )
}

function KPI({ etiqueta, valor, hint, acento }: {
  etiqueta: string; valor: React.ReactNode; hint?: string; acento?: 'ok' | 'warn' | 'bad'
}) {
  const col = acento === 'ok' ? 'text-green-700' : acento === 'warn' ? 'text-amber-700' : acento === 'bad' ? 'text-red-700' : 'text-gray-900'
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-3">
      <div className="text-xs uppercase tracking-wide text-gray-600">{etiqueta}</div>
      <div className={`mt-0.5 text-2xl font-semibold tabular-nums ${col}`}>{valor}</div>
      {hint && <div className="text-xs text-gray-500">{hint}</div>}
    </div>
  )
}

function KPIs({ resumen, alertas }: {
  resumen: ReturnType<typeof useInicioResumen>['data']
  alertas: ReturnType<typeof useAlertasInforme>['data']
}) {
  const faltanInv = (alertas?.bajos_minimo.length ?? 0)
  return (
    <div className="grid gap-2 grid-cols-2 sm:grid-cols-3 lg:grid-cols-5">
      <KPI etiqueta="Prácticas esta semana" valor={resumen?.sesiones ?? '—'} />
      <KPI etiqueta="Estudiantes" valor={resumen?.estudiantes ?? '—'}
           hint={resumen ? `${resumen.docentes} docentes` : undefined} />
      <KPI etiqueta="Pendientes de aprobación" valor={resumen?.pendientes ?? '—'}
           acento={(resumen?.pendientes ?? 0) > 0 ? 'warn' : undefined} />
      <KPI etiqueta="Reactivos bajo mínimo" valor={faltanInv}
           acento={faltanInv > 0 ? 'bad' : 'ok'} />
      <KPI etiqueta="Envases por vencer" valor={resumen?.envases_por_vencer ?? '—'}
           acento={(resumen?.envases_por_vencer ?? 0) > 0 ? 'warn' : 'ok'}
           hint="próximos 14 días" />
    </div>
  )
}

function VistaSemana({ sesiones, lunes, hoy }: { sesiones: SesionSemana[]; lunes: Date; hoy: Date }) {
  const diaActual = hoy.getDay() === 0 ? 7 : hoy.getDay()
  const estaEnLaSemana = mismosDia(lunesDe(hoy), lunes)
  const altura = PX_POR_HORA * (HORA_FIN - HORA_INI)
  return (
    <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white">
      <div className="grid min-w-[720px]" style={{ gridTemplateColumns: '60px repeat(6, 1fr)' }}>
        <div className="border-b border-r border-gray-200 bg-gray-50"></div>
        {DIAS.map((d, i) => {
          const fecha = sumarDias(lunes, i)
          const esHoy = estaEnLaSemana && (i + 1) === diaActual
          return (
            <div key={d} className={`border-b border-r border-gray-200 px-3 py-2 ${esHoy ? 'bg-blue-50' : ''}`}>
              <div className="text-xs uppercase tracking-wide text-gray-500">{d}</div>
              <div className={`text-xl font-semibold tabular-nums ${esHoy ? 'text-blue-700' : 'text-gray-900'}`}>
                {fecha.getDate()}
                {esHoy && <span className="ml-2 rounded-full bg-blue-600 px-2 py-0.5 text-[10px] font-medium text-white">hoy</span>}
              </div>
            </div>
          )
        })}

        {/* Columna de horas */}
        <div className="border-r border-gray-200 bg-gray-50" style={{ height: altura }}>
          {Array.from({ length: HORA_FIN - HORA_INI }, (_, i) => (
            <div key={i} className="h-[42px] border-t border-dashed border-gray-200 pr-1 text-right text-[10px] text-gray-400 tabular-nums">
              {String(HORA_INI + i).padStart(2, '0')}
            </div>
          ))}
        </div>

        {/* Columnas de días */}
        {DIAS.map((_, i) => {
          const dia = i + 1
          const esHoy = estaEnLaSemana && dia === diaActual
          const delDia = sesiones.filter(s => s.dia_semana === dia)
          return (
            <div key={i} className={`relative border-r border-gray-200 ${esHoy ? 'bg-blue-50/30' : ''}`} style={{ height: altura }}>
              {Array.from({ length: HORA_FIN - HORA_INI }, (_, h) => (
                <div key={h} className="absolute left-0 right-0 border-t border-dashed border-gray-200"
                  style={{ top: h * PX_POR_HORA }} />
              ))}
              {delDia.map(s => <BloqueSesion key={s.sesion_id} s={s} />)}
            </div>
          )
        })}
      </div>
    </div>
  )
}

function BloqueSesion({ s }: { s: SesionSemana }) {
  const ini = new Date(s.inicio); const fin = new Date(s.fin)
  const h0 = ini.getHours() + ini.getMinutes() / 60
  const h1 = fin.getHours() + fin.getMinutes() / 60
  const top = Math.max(0, (h0 - HORA_INI)) * PX_POR_HORA
  const height = Math.max(44, (h1 - h0) * PX_POR_HORA)
  const color = colorPrograma(s.programa)
  const pendiente = s.estado === 'solicitada' || s.estado === 'borrador'
  const problema = s.faltantes > 0

  return (
    <Link to={`/sesiones/${s.sesion_id}`}
      className="absolute left-1 right-1 overflow-hidden rounded-md bg-white px-2 py-1 text-[11px] shadow-sm hover:shadow-md"
      style={{
        top, height,
        borderLeft: `3px solid ${color}`,
        background: problema
          ? 'color-mix(in srgb, var(--danger-soft) 70%, var(--surface))'
          : pendiente
          ? 'repeating-linear-gradient(135deg, var(--surface), var(--surface) 6px, var(--warn-soft) 6px, var(--warn-soft) 12px)'
          : 'var(--surface)',
      }}>
      <div className="truncate text-[12px] font-semibold text-gray-900">{s.practica}</div>
      <div className="text-gray-600">
        <b>{ini.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false })}
          – {fin.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false })}</b> · {s.laboratorio}
      </div>
      <div className="truncate text-gray-500">{s.docente} · {s.num_estudiantes} est.</div>
      <div className="text-gray-500">{s.campus}</div>
      <EstadoPill estado={s.estado} problema={problema} />
    </Link>
  )
}

function EstadoPill({ estado, problema }: { estado: string; problema: boolean }) {
  if (problema) return <span className="mt-1 inline-block rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-800">⚠ inventario</span>
  switch (estado) {
    case 'aprobada':   return <span className="mt-1 inline-block rounded-full bg-green-100 px-2 py-0.5 text-[10px] font-medium text-green-800">✓ aprobada</span>
    case 'finalizada': return <span className="mt-1 inline-block rounded-full bg-gray-200 px-2 py-0.5 text-[10px] font-medium text-gray-700">✓ finalizada</span>
    case 'solicitada': return <span className="mt-1 inline-block rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-medium text-amber-800">⏱ pendiente</span>
    case 'borrador':   return <span className="mt-1 inline-block rounded-full bg-gray-100 px-2 py-0.5 text-[10px] font-medium text-gray-600">borrador</span>
    case 'rechazada':  return <span className="mt-1 inline-block rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-800">rechazada</span>
    default: return null
  }
}

function VistaAgenda({ sesiones }: { sesiones: SesionSemana[] }) {
  if (sesiones.length === 0) return <Vacio />
  const porDia = new Map<number, SesionSemana[]>()
  for (const s of sesiones) {
    const arr = porDia.get(s.dia_semana) ?? []
    arr.push(s); porDia.set(s.dia_semana, arr)
  }
  return (
    <div className="space-y-3">
      {[1,2,3,4,5,6].map(dia => {
        const list = porDia.get(dia) ?? []
        if (list.length === 0) return null
        return (
          <div key={dia} className="rounded-lg border border-gray-200 bg-white">
            <div className="border-b border-gray-200 bg-gray-50 px-4 py-2 text-sm font-semibold text-gray-700">{DIAS[dia - 1]}</div>
            <ul className="divide-y divide-gray-100">
              {list.map(s => (
                <li key={s.sesion_id}>
                  <Link to={`/sesiones/${s.sesion_id}`} className="flex items-center justify-between gap-3 px-4 py-2 hover:bg-gray-50">
                    <div className="flex items-center gap-3">
                      <span className="h-full w-1 rounded" style={{ background: colorPrograma(s.programa), minHeight: 36 }} />
                      <div>
                        <div className="text-sm font-medium">{s.practica}</div>
                        <div className="text-xs text-gray-500">{s.docente} · {s.laboratorio} · {s.campus}</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm tabular-nums">
                        {new Date(s.inicio).toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false })}–
                        {new Date(s.fin).toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false })}
                      </div>
                      <EstadoPill estado={s.estado} problema={s.faltantes > 0} />
                    </div>
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        )
      })}
    </div>
  )
}

function VistaLaboratorio({ sesiones }: { sesiones: SesionSemana[] }) {
  if (sesiones.length === 0) return <Vacio />
  const porLab = new Map<string, SesionSemana[]>()
  for (const s of sesiones) {
    const k = `${s.campus} · ${s.laboratorio}`
    const arr = porLab.get(k) ?? []; arr.push(s); porLab.set(k, arr)
  }
  return (
    <div className="space-y-3">
      {[...porLab.entries()].sort(([a],[b]) => a.localeCompare(b)).map(([lab, list]) => (
        <div key={lab} className="rounded-lg border border-gray-200 bg-white">
          <div className="border-b border-gray-200 bg-gray-50 px-4 py-2 text-sm font-semibold text-gray-700">{lab}</div>
          <ul className="divide-y divide-gray-100">
            {list.map(s => (
              <li key={s.sesion_id}>
                <Link to={`/sesiones/${s.sesion_id}`} className="flex items-center justify-between gap-3 px-4 py-2 hover:bg-gray-50">
                  <div>
                    <div className="text-sm font-medium">{s.practica}</div>
                    <div className="text-xs text-gray-500">{DIAS[s.dia_semana - 1]} · {s.docente} · {s.num_estudiantes} est.</div>
                  </div>
                  <EstadoPill estado={s.estado} problema={s.faltantes > 0} />
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  )
}

function Vacio() {
  return (
    <div className="rounded-lg border border-dashed border-gray-300 bg-white p-10 text-center text-gray-500">
      No hay prácticas programadas esta semana.
    </div>
  )
}

function Leyenda() {
  return (
    <div className="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500">
      <span className="font-medium text-gray-700">Barra lateral:</span>
      <span>programa académico</span>
      <span className="ml-4">Rayado amarillo = pendiente de aprobación</span>
      <span>Fondo rojo = inventario insuficiente</span>
    </div>
  )
}

function Pendientes({ sesiones }: { sesiones: SesionSemana[] }) {
  const list = sesiones.filter(s => s.estado === 'solicitada' || s.estado === 'borrador').slice(0, 6)
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-3">
      <h3 className="mb-2 text-sm font-semibold text-gray-800">⏱ Pendientes de aprobación</h3>
      {list.length === 0 ? (
        <div className="py-2 text-xs text-gray-500">Nada pendiente esta semana.</div>
      ) : (
        <ul className="divide-y divide-gray-100 text-sm">
          {list.map(s => (
            <li key={s.sesion_id}>
              <Link to={`/sesiones/${s.sesion_id}`} className="flex justify-between py-1.5 hover:bg-gray-50 -mx-1 px-1 rounded">
                <div>
                  <div className="text-gray-900">{s.practica}</div>
                  <div className="text-xs text-gray-500">{s.docente} · {DIAS[s.dia_semana - 1]}</div>
                </div>
                <div className="text-xs text-gray-500">{s.campus}</div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function AlertasInv({ alertas }: { alertas: ReturnType<typeof useAlertasInforme>['data'] }) {
  const bajos = alertas?.bajos_minimo ?? []
  const vencer = alertas?.por_vencer ?? []
  if (bajos.length === 0 && vencer.length === 0) return null
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-3">
      <h3 className="mb-2 text-sm font-semibold text-gray-800">⚠ Alertas de inventario</h3>
      <ul className="divide-y divide-gray-100 text-sm">
        {bajos.slice(0, 4).map(r => (
          <li key={r.id} className="flex justify-between py-1.5">
            <div>
              <div className="text-gray-900">{r.nombre}</div>
              <div className="text-xs text-gray-500">bajo de mínimo</div>
            </div>
            <div className="text-xs font-medium text-red-700">
              faltan {(r.stock_minimo - r.stock).toFixed(1)} {r.unidad}
            </div>
          </li>
        ))}
        {vencer.slice(0, 4).map(r => (
          <li key={r.id} className="flex justify-between py-1.5">
            <div>
              <div className="text-gray-900">{r.nombre}</div>
              <div className="text-xs text-gray-500">{r.campus}</div>
            </div>
            <div className="text-xs font-medium text-amber-700">vence {r.fecha_caducidad}</div>
          </li>
        ))}
      </ul>
    </div>
  )
}

function CargaCampus({ sesiones }: { sesiones: SesionSemana[] }) {
  const m = new Map<string, { prac: number; est: number }>()
  for (const s of sesiones) {
    const x = m.get(s.campus) ?? { prac: 0, est: 0 }
    x.prac += 1; x.est += s.num_estudiantes
    m.set(s.campus, x)
  }
  const filas = [...m.entries()]
  if (filas.length === 0) return null
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-3">
      <h3 className="mb-2 text-sm font-semibold text-gray-800">🧪 Carga por campus</h3>
      <ul className="divide-y divide-gray-100 text-sm">
        {filas.map(([k, v]) => (
          <li key={k} className="flex justify-between py-1.5">
            <span className="text-gray-900">{k}</span>
            <span className="text-xs text-gray-500">{v.prac} prácticas · {v.est} est.</span>
          </li>
        ))}
      </ul>
    </div>
  )
}

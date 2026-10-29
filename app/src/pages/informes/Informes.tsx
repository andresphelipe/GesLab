import { useMemo, useState } from 'react'
import {
  Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, ComposedChart,
  Legend, Line, LineChart, PieChart, Pie, ReferenceLine, ResponsiveContainer,
  Tooltip, XAxis, YAxis,
} from 'recharts'
import * as XLSX from 'xlsx'
import { supabase } from '@/lib/supabase'
import QueryBuilder from './QueryBuilder'
import {
  Filtro, useAlertasInforme, useCampusList, useCumplimiento, useHeatmap,
  useKPIs, useProyeccion, useSerieMensual,
  useTopDocentes, useTopMateriales, useTopProgramas, useTopPracticas,
  useTopReactivos, useUsoEquipos, useVidrieria,
} from '@/hooks/useInformes'

const estilosImpresion = `
  @media print {
    .informe-no-print { display: none !important; }
    body { background: white !important; }
    section { break-inside: avoid; page-break-inside: avoid; }
    .recharts-responsive-container { break-inside: avoid; }
  }
`

const COLORES = ['#2563eb','#16a34a','#f59e0b','#ef4444','#7c3aed','#0891b2','#db2777','#65a30d','#ea580c','#4f46e5']
const DIAS = ['Dom','Lun','Mar','Mié','Jue','Vie','Sáb']

function hoy() { return new Date().toISOString().slice(0, 10) }
function haceMeses(n: number) {
  const d = new Date(); d.setMonth(d.getMonth() - n); d.setDate(1)
  return d.toISOString().slice(0, 10)
}
function fmt(n: number | null | undefined, dec = 0) {
  if (n == null) return '—'
  return new Intl.NumberFormat('es-CO', { maximumFractionDigits: dec }).format(n)
}
function fmtMes(m: string) {
  const d = new Date(m); return d.toLocaleDateString('es-CO', { month: 'short', year: '2-digit' })
}

type Tab = 'resumen' | 'reactivos' | 'equipos' | 'vidrieria' | 'docentes' | 'cumplimiento' | 'tendencia' | 'alertas' | 'dinamico'

export default function Informes() {
  const [filtro, setFiltro] = useState<Filtro>({
    desde: haceMeses(6), hasta: hoy(), campus_id: null,
  })
  const [tab, setTab] = useState<Tab>('resumen')
  const { data: campus } = useCampusList()

  return (
    <div className="space-y-4">
      <style>{estilosImpresion}</style>
      <header className="flex flex-wrap items-end justify-between gap-3 informe-no-print">
        <div>
          <h1 className="text-xl font-semibold">Informes y analítica</h1>
          <p className="text-sm text-gray-600">Decisiones a partir del uso real de los laboratorios.</p>
        </div>
        <div className="flex flex-wrap items-end gap-3">
          <Filtros filtro={filtro} setFiltro={setFiltro} campus={campus ?? []} />
          <ExportarInforme filtro={filtro} campus={campus ?? []} />
        </div>
      </header>

      <nav className="flex flex-wrap gap-1 border-b border-gray-200 informe-no-print">
        {([
          ['resumen', 'Resumen'],
          ['reactivos', 'Reactivos'],
          ['equipos', 'Equipos'],
          ['vidrieria', 'Vidriería'],
          ['docentes', 'Docentes y programas'],
          ['cumplimiento', 'Cumplimiento'],
          ['tendencia', 'Tendencia y proyección'],
          ['alertas', 'Alertas e inventario'],
          ['dinamico', 'Informes dinámicos'],
        ] as [Tab, string][]).map(([k, l]) => (
          <button
            key={k} onClick={() => setTab(k)}
            className={`px-3 py-2 text-sm border-b-2 -mb-px ${
              tab === k ? 'border-blue-600 text-blue-700 font-medium' : 'border-transparent text-gray-600 hover:text-gray-900'
            }`}>{l}</button>
        ))}
      </nav>

      {tab === 'resumen' && <TabResumen f={filtro} />}
      {tab === 'reactivos' && <TabReactivos f={filtro} />}
      {tab === 'equipos' && <TabEquipos f={filtro} />}
      {tab === 'vidrieria' && <TabVidrieria f={filtro} />}
      {tab === 'docentes' && <TabDocentes f={filtro} />}
      {tab === 'cumplimiento' && <TabCumplimiento f={filtro} />}
      {tab === 'tendencia' && <TabTendencia f={filtro} />}
      {tab === 'alertas' && <TabAlertas campus_id={filtro.campus_id} />}
      {tab === 'dinamico' && <QueryBuilder />}
    </div>
  )
}

function Filtros({ filtro, setFiltro, campus }:{
  filtro: Filtro; setFiltro: (f: Filtro) => void; campus: { id: string; nombre: string }[]
}) {
  const presets = [
    ['3m', 'Últimos 3 meses', () => setFiltro({ ...filtro, desde: haceMeses(3), hasta: hoy() })],
    ['6m', '6 meses', () => setFiltro({ ...filtro, desde: haceMeses(6), hasta: hoy() })],
    ['12m', '12 meses', () => setFiltro({ ...filtro, desde: haceMeses(12), hasta: hoy() })],
    ['año', 'Año en curso', () => setFiltro({ ...filtro,
      desde: `${new Date().getFullYear()}-01-01`, hasta: hoy() })],
  ] as const
  return (
    <div className="flex flex-wrap items-end gap-2 text-sm">
      <div className="flex gap-1">
        {presets.map(([k, l, fn]) => (
          <button key={k} onClick={fn} className="rounded border border-gray-300 bg-white px-2 py-1 text-xs hover:bg-gray-50">{l}</button>
        ))}
      </div>
      <label className="flex flex-col">
        <span className="text-xs text-gray-600">Desde</span>
        <input type="date" value={filtro.desde} onChange={e => setFiltro({ ...filtro, desde: e.target.value })}
          className="rounded border border-gray-300 px-2 py-1" />
      </label>
      <label className="flex flex-col">
        <span className="text-xs text-gray-600">Hasta</span>
        <input type="date" value={filtro.hasta} onChange={e => setFiltro({ ...filtro, hasta: e.target.value })}
          className="rounded border border-gray-300 px-2 py-1" />
      </label>
      <label className="flex flex-col">
        <span className="text-xs text-gray-600">Campus</span>
        <select value={filtro.campus_id ?? ''} onChange={e => setFiltro({ ...filtro, campus_id: e.target.value || null })}
          className="rounded border border-gray-300 px-2 py-1">
          <option value="">Todos</option>
          {campus.map(c => <option key={c.id} value={c.id}>{c.nombre}</option>)}
        </select>
      </label>
    </div>
  )
}

function KPI({ etiqueta, valor, hint, acento }:{
  etiqueta: string; valor: React.ReactNode; hint?: string; acento?: 'ok' | 'warn' | 'bad'
}) {
  const col = acento === 'ok' ? 'text-green-700' : acento === 'warn' ? 'text-amber-700' : acento === 'bad' ? 'text-red-700' : 'text-gray-900'
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-3">
      <div className="text-xs text-gray-600">{etiqueta}</div>
      <div className={`text-2xl font-semibold ${col}`}>{valor}</div>
      {hint && <div className="text-xs text-gray-500 mt-0.5">{hint}</div>}
    </div>
  )
}

function Card({ titulo, children, extra }:{ titulo: string; children: React.ReactNode; extra?: React.ReactNode }) {
  return (
    <section className="rounded-lg border border-gray-200 bg-white p-4">
      <header className="mb-3 flex items-center justify-between">
        <h2 className="text-sm font-semibold text-gray-800">{titulo}</h2>
        {extra}
      </header>
      {children}
    </section>
  )
}

/* ---------- Resumen ---------- */
function TabResumen({ f }: { f: Filtro }) {
  const kpi = useKPIs(f)
  const serie = useSerieMensual(f)
  const cumpl = useCumplimiento(f)
  const prog = useTopProgramas(f)
  const prac = useTopPracticas(f, 10)

  const porEstado = useMemo(() => {
    if (!cumpl.data) return []
    return Object.entries(cumpl.data.por_estado ?? {}).map(([k, v]) => ({ name: k, value: v }))
  }, [cumpl.data])

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-6">
        <KPI etiqueta="Sesiones" valor={fmt(kpi.data?.sesiones_total)}
             hint={`${fmt(kpi.data?.sesiones_aprobadas)} aprobadas`} />
        <KPI etiqueta="Docentes activos" valor={fmt(kpi.data?.docentes_activos)} />
        <KPI etiqueta="Estudiantes" valor={fmt(kpi.data?.estudiantes)} />
        <KPI etiqueta="Consumo (base)" valor={fmt(kpi.data?.consumo_total, 1)}
             hint={`${fmt(kpi.data?.eficiencia, 1)}% del previsto`} />
        <KPI etiqueta="Envases por vencer" valor={fmt(kpi.data?.envases_por_vencer)}
             acento={kpi.data && kpi.data.envases_por_vencer > 0 ? 'warn' : undefined}
             hint="próximos 60 días" />
        <KPI etiqueta="Incidencias abiertas" valor={fmt(kpi.data?.incidencias_abiertas)}
             acento={kpi.data && kpi.data.incidencias_abiertas > 0 ? 'bad' : 'ok'} />
      </div>

      <Card titulo="Sesiones y consumo por mes">
        <div className="h-72">
          <ResponsiveContainer>
            <ComposedChart data={serie.data ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="mes" tickFormatter={fmtMes} />
              <YAxis yAxisId="l" />
              <YAxis yAxisId="r" orientation="right" />
              <Tooltip labelFormatter={fmtMes as any}
                formatter={((v: number, n: string) => [fmt(v, 1), n]) as any} />
              <Legend />
              <Bar yAxisId="l" dataKey="sesiones" name="Sesiones" fill="#2563eb" />
              <Line yAxisId="r" dataKey="consumo_g" name="Consumo (g)" stroke="#16a34a" strokeWidth={2} />
              <Line yAxisId="r" dataKey="consumo_ml" name="Consumo (mL)" stroke="#f59e0b" strokeWidth={2} />
            </ComposedChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card titulo="Sesiones por estado">
          <div className="h-60">
            <ResponsiveContainer>
              <PieChart>
                <Pie data={porEstado} dataKey="value" nameKey="name" outerRadius={90} label>
                  {porEstado.map((_, i) => <Cell key={i} fill={COLORES[i % COLORES.length]} />)}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </Card>
        <Card titulo="Programas académicos">
          <div className="h-60">
            <ResponsiveContainer>
              <BarChart data={prog.data ?? []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis type="number" />
                <YAxis type="category" dataKey="programa" width={160} tick={{ fontSize: 12 }} />
                <Tooltip />
                <Bar dataKey="sesiones" fill="#2563eb" name="Sesiones" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <Card titulo="Prácticas más demandadas">
        <Tabla columnas={['Práctica', 'Sesiones', 'Estudiantes']}
          filas={(prac.data ?? []).map(p => [p.practica, fmt(p.sesiones), fmt(p.estudiantes)])} />
      </Card>
    </div>
  )
}

/* ---------- Reactivos ---------- */
function TabReactivos({ f }: { f: Filtro }) {
  const top = useTopReactivos(f, 20)
  const mats = useTopMateriales(f, 15)
  const serie = useSerieMensual(f)

  return (
    <div className="space-y-4">
      <div className="grid gap-4 lg:grid-cols-2">
        <Card titulo="Top reactivos por consumo"
          extra={<BotonExportar nombre="top-reactivos" filas={top.data ?? []} />}>
          <div className="h-80">
            <ResponsiveContainer>
              <BarChart data={top.data ?? []} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis type="number" />
                <YAxis type="category" dataKey="reactivo" width={160} tick={{ fontSize: 11 }} />
                <Tooltip formatter={((v: number, _n: any, p: any) => [`${fmt(v, 2)} ${p?.payload?.unidad ?? ''}`, 'Consumo']) as any} />
                <Bar dataKey="consumo" fill="#2563eb" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
        <Card titulo="Previsto vs. consumido">
          <div className="h-80">
            <ResponsiveContainer>
              <BarChart data={top.data?.slice(0, 10) ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="reactivo" tick={{ fontSize: 10 }} angle={-25} textAnchor="end" height={70} />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="previsto" fill="#94a3b8" name="Previsto" />
                <Bar dataKey="consumo" fill="#2563eb" name="Consumido" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>

      <Card titulo="Consumo acumulado por mes">
        <div className="h-64">
          <ResponsiveContainer>
            <AreaChart data={serie.data ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="mes" tickFormatter={fmtMes} />
              <YAxis />
              <Tooltip labelFormatter={fmtMes as any} formatter={((v: number) => fmt(v, 1)) as any} />
              <Legend />
              <Area dataKey="consumo_g" stackId="1" stroke="#16a34a" fill="#86efac" name="g" />
              <Area dataKey="consumo_ml" stackId="1" stroke="#f59e0b" fill="#fde68a" name="mL" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </Card>

      <Card titulo="Materiales / vidriería / consumibles"
        extra={<BotonExportar nombre="top-materiales" filas={mats.data ?? []} />}>
        <Tabla columnas={['Material', 'Tipo', 'Sesiones', 'Previsto', 'Consumido']}
          filas={(mats.data ?? []).map(m => [m.material, m.tipo, fmt(m.sesiones), fmt(m.previsto, 1), fmt(m.consumo, 1)])} />
      </Card>
    </div>
  )
}

/* ---------- Equipos ---------- */
function TabEquipos({ f }: { f: Filtro }) {
  const eq = useUsoEquipos(f, 30)
  const total = useMemo(() => (eq.data ?? []).reduce((a, e) => a + e.horas, 0), [eq.data])
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-3 gap-3">
        <KPI etiqueta="Equipos listados" valor={fmt(eq.data?.length)} />
        <KPI etiqueta="Reservas totales" valor={fmt((eq.data ?? []).reduce((a, e) => a + e.reservas, 0))} />
        <KPI etiqueta="Horas de uso" valor={fmt(total, 1)} />
      </div>
      <Card titulo="Uso por equipo (horas)"
        extra={<BotonExportar nombre="equipos" filas={eq.data ?? []} />}>
        <div className="h-96">
          <ResponsiveContainer>
            <BarChart data={eq.data ?? []} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis type="number" />
              <YAxis type="category" dataKey="equipo" width={200} tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="horas" fill="#2563eb" name="Horas" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>
      <Card titulo="Detalle">
        <Tabla columnas={['Equipo', 'Campus', 'Laboratorio', 'Estado', 'Reservas', 'Horas']}
          filas={(eq.data ?? []).map(e => [e.equipo, e.campus ?? '—', e.laboratorio ?? '—', e.estado, fmt(e.reservas), fmt(e.horas, 1)])} />
      </Card>
    </div>
  )
}

/* ---------- Vidriería ---------- */
function TabVidrieria({ f }: { f: Filtro }) {
  const vid = useVidrieria(f)
  const porCampus = useMemo(() => {
    const m = new Map<string, { campus: string; buena: number; regular: number; dannada: number; roturas: number }>()
    for (const r of vid.data ?? []) {
      const x = m.get(r.campus) ?? { campus: r.campus, buena: 0, regular: 0, dannada: 0, roturas: 0 }
      x.buena += r.buena; x.regular += r.regular; x.dannada += r.dannada; x.roturas += r.roturas
      m.set(r.campus, x)
    }
    return [...m.values()]
  }, [vid.data])
  return (
    <div className="space-y-4">
      <Card titulo="Estado por campus">
        <div className="h-72">
          <ResponsiveContainer>
            <BarChart data={porCampus}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="campus" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="buena" stackId="s" fill="#16a34a" name="Buena" />
              <Bar dataKey="regular" stackId="s" fill="#f59e0b" name="Regular" />
              <Bar dataKey="dannada" stackId="s" fill="#ef4444" name="Dañada" />
              <Bar dataKey="roturas" fill="#7c3aed" name="Roturas" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>
      <Card titulo="Detalle por material"
        extra={<BotonExportar nombre="vidrieria" filas={vid.data ?? []} />}>
        <Tabla columnas={['Campus', 'Material', 'Buena', 'Regular', 'Dañada', 'Roturas']}
          filas={(vid.data ?? []).map(r => [r.campus, r.material, fmt(r.buena), fmt(r.regular), fmt(r.dannada), fmt(r.roturas)])} />
      </Card>
    </div>
  )
}

/* ---------- Docentes / programas ---------- */
function TabDocentes({ f }: { f: Filtro }) {
  const docs = useTopDocentes(f, 20)
  const progs = useTopProgramas(f)
  return (
    <div className="space-y-4">
      <Card titulo="Docentes por volumen de sesiones"
        extra={<BotonExportar nombre="docentes" filas={docs.data ?? []} />}>
        <div className="h-96">
          <ResponsiveContainer>
            <BarChart data={docs.data ?? []} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis type="number" />
              <YAxis type="category" dataKey="docente" width={200} tick={{ fontSize: 11 }} />
              <Tooltip />
              <Legend />
              <Bar dataKey="sesiones" fill="#2563eb" name="Sesiones" />
              <Bar dataKey="horas" fill="#16a34a" name="Horas" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </Card>
      <Card titulo="Programas académicos"
        extra={<BotonExportar nombre="programas" filas={progs.data ?? []} />}>
        <Tabla columnas={['Programa', 'Sesiones', 'Estudiantes', 'Docentes', 'Consumo g', 'Consumo mL']}
          filas={(progs.data ?? []).map(p => [p.programa, fmt(p.sesiones), fmt(p.estudiantes), fmt(p.docentes), fmt(p.consumo_g, 1), fmt(p.consumo_ml, 1)])} />
      </Card>
    </div>
  )
}

/* ---------- Cumplimiento ---------- */
function TabCumplimiento({ f }: { f: Filtro }) {
  const c = useCumplimiento(f)
  const heat = useHeatmap(f)
  const d = c.data
  const matriz = useMemo(() => {
    const m: number[][] = Array.from({ length: 7 }, () => Array(24).fill(0))
    let max = 0
    for (const r of heat.data ?? []) {
      m[r.dia_semana][r.hora] = r.sesiones
      if (r.sesiones > max) max = r.sesiones
    }
    return { m, max }
  }, [heat.data])
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <KPI etiqueta="Solicitudes" valor={fmt(d?.total)} />
        <KPI etiqueta="% Aprobadas" valor={d?.pct_aprobadas != null ? `${fmt(d.pct_aprobadas, 1)}%` : '—'}
             acento={(d?.pct_aprobadas ?? 0) >= 80 ? 'ok' : 'warn'} />
        <KPI etiqueta="Aprobación promedio" valor={d?.horas_aprobacion_prom != null ? `${fmt(d.horas_aprobacion_prom, 1)} h` : '—'}
             hint={`mediana: ${d?.horas_aprobacion_p50 != null ? `${fmt(d.horas_aprobacion_p50, 1)} h` : '—'}`} />
        <KPI etiqueta="Consumo / Previsto" valor={d?.consumo_vs_previsto_pct != null ? `${fmt(d.consumo_vs_previsto_pct, 1)}%` : '—'} />
      </div>

      <Card titulo="Mapa de calor — día de semana × hora">
        <div className="overflow-x-auto">
          <table className="min-w-full text-center text-xs">
            <thead>
              <tr><th></th>{Array.from({ length: 24 }, (_, h) => <th key={h} className="px-1">{h}</th>)}</tr>
            </thead>
            <tbody>
              {matriz.m.map((fila, dia) => (
                <tr key={dia}>
                  <th className="pr-2 text-right">{DIAS[dia]}</th>
                  {fila.map((v, h) => {
                    const alpha = matriz.max ? v / matriz.max : 0
                    return (
                      <td key={h} className="h-6 w-6"
                        style={{ background: `rgba(37,99,235,${0.08 + alpha * 0.92})`, color: alpha > 0.5 ? '#fff' : '#374151' }}
                        title={`${DIAS[dia]} ${h}:00 — ${v} sesiones`}>
                        {v || ''}
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  )
}

/* ---------- Tendencia ---------- */
function TabTendencia({ f }: { f: Filtro }) {
  const [meses, setMeses] = useState(3)
  const proy = useProyeccion(f, meses)
  const datos = proy.data ?? []
  const corte = datos.find(d => d.es_proyeccion)?.mes
  return (
    <div className="space-y-4">
      <Card titulo="Proyección a futuro (regresión lineal)"
        extra={
          <label className="text-xs text-gray-600">
            Horizonte:
            <select value={meses} onChange={e => setMeses(Number(e.target.value))}
              className="ml-1 rounded border border-gray-300 px-1 py-0.5">
              {[1,2,3,6,12].map(n => <option key={n} value={n}>{n} meses</option>)}
            </select>
          </label>
        }>
        <div className="h-72">
          <ResponsiveContainer>
            <LineChart data={datos}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="mes" tickFormatter={fmtMes} />
              <YAxis />
              <Tooltip labelFormatter={fmtMes as any} />
              <Legend />
              {corte && <ReferenceLine x={corte} stroke="#ef4444" strokeDasharray="4 2" label="Proyección" />}
              <Line dataKey="sesiones_prev" stroke="#2563eb" name="Sesiones" strokeWidth={2} dot={{ r: 3 }} />
              <Line dataKey="consumo_g_prev" stroke="#16a34a" name="Consumo (g)" strokeWidth={2} dot={{ r: 3 }} />
              <Line dataKey="consumo_ml_prev" stroke="#f59e0b" name="Consumo (mL)" strokeWidth={2} dot={{ r: 3 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
        <p className="mt-3 text-xs text-gray-500">
          La línea de proyección usa regresión lineal sobre la serie histórica del rango seleccionado. Es un
          indicador de tendencia, no una predicción exacta: funciona mejor con 6+ meses de datos.
        </p>
      </Card>
    </div>
  )
}

/* ---------- Alertas ---------- */
function TabAlertas({ campus_id }: { campus_id: string | null }) {
  const a = useAlertasInforme(campus_id, 180)
  return (
    <div className="space-y-4">
      <Card titulo={`Envases próximos a vencer — próximos 90 días (${fmt(a.data?.por_vencer.length)})`}
        extra={a.data && <BotonExportar nombre="por-vencer" filas={a.data.por_vencer} />}>
        <Tabla columnas={['Reactivo', 'Campus', 'Caduca', 'Cantidad']}
          filas={(a.data?.por_vencer ?? []).map(r => [r.nombre, r.campus, r.fecha_caducidad, `${fmt(r.cantidad_actual, 2)} ${r.unidad}`])} />
      </Card>
      <Card titulo={`Reactivos bajo mínimo (${fmt(a.data?.bajos_minimo.length)})`}
        extra={a.data && <BotonExportar nombre="bajos-minimo" filas={a.data.bajos_minimo} />}>
        <Tabla columnas={['Reactivo', 'Stock', 'Mínimo', 'Déficit']}
          filas={(a.data?.bajos_minimo ?? []).map(r => [
            r.nombre, `${fmt(r.stock, 2)} ${r.unidad}`, `${fmt(r.stock_minimo, 2)} ${r.unidad}`,
            `${fmt(r.stock_minimo - r.stock, 2)} ${r.unidad}`,
          ])} />
      </Card>
      <Card titulo="Alta demanda (consumo mensual estimado)"
        extra={a.data && <BotonExportar nombre="alta-demanda" filas={a.data.alta_demanda} />}>
        <Tabla columnas={['Reactivo', 'Unidad', 'Consumo 180 d', 'Consumo mensual']}
          filas={(a.data?.alta_demanda ?? []).map(r => [r.reactivo, r.unidad, fmt(r.consumo, 2), fmt(r.consumo_mes, 2)])} />
      </Card>
    </div>
  )
}

/* ---------- Utilidades ---------- */
function Tabla({ columnas, filas }: { columnas: string[]; filas: React.ReactNode[][] }) {
  if (filas.length === 0) {
    return <div className="rounded border border-dashed border-gray-200 p-4 text-center text-sm text-gray-500">Sin datos en este rango.</div>
  }
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200 text-sm">
        <thead className="bg-gray-50 text-xs uppercase text-gray-600">
          <tr>{columnas.map(c => <th key={c} className="px-3 py-2 text-left font-medium">{c}</th>)}</tr>
        </thead>
        <tbody className="divide-y divide-gray-100 bg-white">
          {filas.map((f, i) => (
            <tr key={i}>{f.map((c, j) => <td key={j} className="px-3 py-2">{c}</td>)}</tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function BotonExportar<T extends object>({ nombre, filas }: { nombre: string; filas: T[] }) {
  if (!filas || filas.length === 0) return null
  const descargar = () => {
    const wb = XLSX.utils.book_new()
    const ws = XLSX.utils.json_to_sheet(filas)
    XLSX.utils.book_append_sheet(wb, ws, 'Datos')
    XLSX.writeFile(wb, `informe-${nombre}-${hoy()}.xlsx`)
  }
  return (
    <button onClick={descargar} className="rounded border border-gray-300 bg-white px-2 py-1 text-xs text-gray-700 hover:bg-gray-50">
      Exportar Excel
    </button>
  )
}

function ExportarInforme({ filtro, campus }:{ filtro: Filtro; campus: { id: string; nombre: string }[] }) {
  const [abierto, setAbierto] = useState(false)
  const sedeTxt = filtro.campus_id
    ? (campus.find(c => c.id === filtro.campus_id)?.nombre ?? 'Campus')
    : 'Todos los campus'

  function imprimirPDF() {
    setAbierto(false)
    setTimeout(() => window.print(), 50)
  }

  function descargarWord() {
    setAbierto(false)
    const main = document.querySelector('main') || document.body
    const clon = main.cloneNode(true) as HTMLElement
    clon.querySelectorAll('.informe-no-print, button').forEach(n => n.remove())
    const encabezado = `
      <h1 style="font-family:Arial,sans-serif;color:#0f172a;margin:0 0 4px">GesLab · Informe de laboratorios</h1>
      <p style="font-family:Arial,sans-serif;color:#475569;margin:0 0 20px">
        Rango: <b>${filtro.desde}</b> a <b>${filtro.hasta}</b> · Sede: <b>${sedeTxt}</b> ·
        Generado: ${new Date().toLocaleString('es-CO')}
      </p>`
    const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Informe GesLab</title></head>
      <body>${encabezado}${clon.innerHTML}</body></html>`
    const blob = new Blob(['﻿', html], { type: 'application/msword' })
    const a = document.createElement('a')
    a.href = URL.createObjectURL(blob)
    a.download = `informe-geslab-${hoy()}.doc`
    document.body.appendChild(a); a.click()
    URL.revokeObjectURL(a.href); a.remove()
  }

  async function descargarExcelCompleto() {
    setAbierto(false)
    const args = { p_desde: filtro.desde, p_hasta: filtro.hasta, p_campus: filtro.campus_id }
    const [kpis, serie, reactivos, materiales, docentes, programas, practicas, equipos, vidrieria, alertas] =
      await Promise.all([
        supabase.rpc('informe_kpis', args),
        supabase.rpc('informe_serie_mensual', args),
        supabase.rpc('informe_top_reactivos', { ...args, p_limite: 50 }),
        supabase.rpc('informe_top_materiales', { ...args, p_limite: 50 }),
        supabase.rpc('informe_top_docentes',   { ...args, p_limite: 50 }),
        supabase.rpc('informe_top_programas',  args),
        supabase.rpc('informe_top_practicas',  { ...args, p_limite: 50 }),
        supabase.rpc('informe_uso_equipos',    { ...args, p_limite: 100 }),
        supabase.rpc('informe_vidrieria',      args),
        supabase.rpc('informe_alertas', { p_campus: filtro.campus_id, p_dias_consumo: 180 }),
      ])
    const wb = XLSX.utils.book_new()
    const portada = [
      { Campo: 'Rango', Valor: `${filtro.desde} a ${filtro.hasta}` },
      { Campo: 'Sede', Valor: sedeTxt },
      { Campo: 'Generado', Valor: new Date().toLocaleString('es-CO') },
    ]
    const kpiRows = kpis.data
      ? Object.entries(kpis.data as Record<string, unknown>).map(([Indicador, Valor]) => ({ Indicador, Valor }))
      : []
    const add = (nombre: string, filas: unknown[]) => {
      if (!filas || filas.length === 0) return
      XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(filas), nombre.slice(0, 31))
    }
    add('Portada', portada)
    add('KPIs', kpiRows)
    add('Serie mensual',  (serie.data as unknown[])      ?? [])
    add('Reactivos',      (reactivos.data as unknown[])  ?? [])
    add('Materiales',     (materiales.data as unknown[]) ?? [])
    add('Docentes',       (docentes.data as unknown[])   ?? [])
    add('Programas',      (programas.data as unknown[])  ?? [])
    add('Prácticas',      (practicas.data as unknown[])  ?? [])
    add('Equipos',        (equipos.data as unknown[])    ?? [])
    add('Vidriería',      (vidrieria.data as unknown[])  ?? [])
    const al = alertas.data as { por_vencer: unknown[]; bajos_minimo: unknown[]; alta_demanda: unknown[] } | null
    if (al) {
      add('Por vencer',      al.por_vencer   ?? [])
      add('Bajos de mínimo', al.bajos_minimo ?? [])
      add('Alta demanda',    al.alta_demanda ?? [])
    }
    XLSX.writeFile(wb, `informe-geslab-${hoy()}.xlsx`)
  }

  return (
    <div className="relative">
      <button onClick={() => setAbierto(v => !v)}
        className="rounded border border-blue-600 bg-blue-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-blue-700">
        Descargar informe ▾
      </button>
      {abierto && (
        <div className="absolute right-0 top-full z-20 mt-1 w-56 rounded-md border border-gray-200 bg-white py-1 shadow-lg">
          <button onClick={descargarExcelCompleto} className="block w-full px-3 py-2 text-left text-sm hover:bg-gray-50">
            📊 Excel completo (.xlsx)
          </button>
          <button onClick={imprimirPDF} className="block w-full px-3 py-2 text-left text-sm hover:bg-gray-50">
            📄 PDF (imprimir / guardar)
          </button>
          <button onClick={descargarWord} className="block w-full px-3 py-2 text-left text-sm hover:bg-gray-50">
            📝 Word (.doc)
          </button>
        </div>
      )}
    </div>
  )
}


import { useEffect, useMemo, useState } from 'react'
import { useCampus } from '@/hooks/useCatalogos'
import { useEnvases, useEquiposInv, useVidrieriaInv } from '@/hooks/useInventario'

type Pestana = 'reactivos' | 'equipos' | 'vidrieria'
const hoyISO = () => new Date().toISOString().slice(0, 10)
const en90 = () => new Date(Date.now() + 90 * 864e5).toISOString().slice(0, 10)
const num = (n: number | null | undefined) => (n == null ? '—' : Number(Number(n).toFixed(3)).toLocaleString('es-CO'))

function Tarjeta({ titulo, valor, tono = '' }: { titulo: string; valor: number | string; tono?: string }) {
  return (
    <div className={`rounded-lg border bg-white p-3 ${tono}`}>
      <p className="text-xs text-gray-500">{titulo}</p>
      <p className="text-xl font-semibold">{valor}</p>
    </div>
  )
}

export default function Inventario() {
  const { data: campus } = useCampus()
  const [campusId, setCampusId] = useState('')
  const [pestana, setPestana] = useState<Pestana>('reactivos')
  const [q, setQ] = useState('')
  const [soloRevisar, setSoloRevisar] = useState(false)
  const [filtroVenc, setFiltroVenc] = useState<'todos' | 'vencidos' | 'porvencer'>('todos')

  useEffect(() => {
    if (!campusId && campus?.length) setCampusId(campus[0].id)
  }, [campus, campusId])

  const { data: envases, isLoading: l1, error: e1 } = useEnvases(campusId)
  const { data: equipos, isLoading: l2, error: e2 } = useEquiposInv(campusId)
  const { data: vidrio, isLoading: l3, error: e3 } = useVidrieriaInv(campusId)
  const nq = q.trim().toLowerCase()
  const hoy = hoyISO(); const lim = en90()

  const rea = useMemo(() => {
    return (envases ?? []).filter((e: any) => {
      const venc = e.fecha_caducidad && e.fecha_caducidad < hoy
      const por = e.fecha_caducidad && !venc && e.fecha_caducidad < lim
      if (filtroVenc === 'vencidos' && !venc) return false
      if (filtroVenc === 'porvencer' && !por) return false
      if (soloRevisar && !e.revisar) return false
      return !nq || `${e.catalogo_reactivos?.nombre} ${e.lote ?? ''} ${e.id_inventario} ${e.ubicacion_texto ?? ''}`.toLowerCase().includes(nq)
    })
  }, [envases, nq, soloRevisar, filtroVenc, hoy, lim])
  const eq = useMemo(
    () => (equipos ?? []).filter((e: any) => (!soloRevisar || e.revisar) && (!nq || `${e.nombre} ${e.marca ?? ''} ${e.salon ?? ''} ${e.id_inventario}`.toLowerCase().includes(nq))),
    [equipos, nq, soloRevisar],
  )
  const vi = useMemo(
    () => (vidrio ?? []).filter((v: any) => !nq || `${v.catalogo_materiales?.nombre} ${v.id_inventario}`.toLowerCase().includes(nq)),
    [vidrio, nq],
  )

  const nVenc = (envases ?? []).filter((e: any) => e.fecha_caducidad && e.fecha_caducidad < hoy).length
  const nPor = (envases ?? []).filter((e: any) => e.fecha_caducidad && e.fecha_caducidad >= hoy && e.fecha_caducidad < lim).length
  const nRevR = (envases ?? []).filter((e: any) => e.revisar).length
  const nRevE = (equipos ?? []).filter((e: any) => e.revisar).length
  const nFuera = (equipos ?? []).filter((e: any) => e.fuera_de_sede).length
  const nOper = (equipos ?? []).filter((e: any) => e.estado === 'operativo').reduce((a: number, e: any) => a + (e.cantidad ?? 1), 0)

  const err = (e1 || e2 || e3) as Error | null
  const cargando = pestana === 'reactivos' ? l1 : pestana === 'equipos' ? l2 : l3
  const th = 'px-3 py-2'
  const MAX = 400
  const tab = (p: Pestana, t: string) => (
    <button onClick={() => setPestana(p)} className={`rounded-lg px-4 py-1.5 text-sm font-medium ${pestana === p ? 'bg-brand-600 text-white' : 'bg-white text-gray-600 border hover:bg-gray-50'}`}>{t}</button>
  )

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold text-gray-800">Inventario</h1>
        <select value={campusId} onChange={(e) => setCampusId(e.target.value)} className="rounded-lg border border-gray-300 px-3 py-1.5 text-sm">
          {campus?.map((c) => <option key={c.id} value={c.id}>{c.nombre}</option>)}
        </select>
      </div>

      <div className="flex flex-wrap gap-2">{tab('reactivos', 'Reactivos')}{tab('equipos', 'Equipos')}{tab('vidrieria', 'Vidriería')}</div>

      {pestana === 'reactivos' && (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Tarjeta titulo="Envases" valor={(envases ?? []).length} />
          <Tarjeta titulo="Vencidos" valor={nVenc} tono={nVenc ? 'border-red-300' : ''} />
          <Tarjeta titulo="Vencen en 90 días" valor={nPor} tono={nPor ? 'border-amber-300' : ''} />
          <Tarjeta titulo="Por revisar" valor={nRevR} tono={nRevR ? 'border-amber-300' : ''} />
        </div>
      )}
      {pestana === 'equipos' && (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <Tarjeta titulo="Registros" valor={(equipos ?? []).length} />
          <Tarjeta titulo="Unidades operativas" valor={nOper} />
          <Tarjeta titulo="En otra sede (traslado)" valor={nFuera} tono={nFuera ? 'border-amber-300' : ''} />
          <Tarjeta titulo="Por revisar" valor={nRevE} tono={nRevE ? 'border-amber-300' : ''} />
        </div>
      )}

      <div className="flex flex-wrap items-center gap-3">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Buscar…" className="w-64 rounded-lg border border-gray-300 px-3 py-1.5 text-sm" />
        {pestana !== 'vidrieria' && (
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" checked={soloRevisar} onChange={(e) => setSoloRevisar(e.target.checked)} /> Solo por revisar
          </label>
        )}
        {pestana === 'reactivos' && (
          <select value={filtroVenc} onChange={(e) => setFiltroVenc(e.target.value as any)} className="rounded-lg border border-gray-300 px-3 py-1.5 text-sm">
            <option value="todos">Todos</option><option value="vencidos">Vencidos</option><option value="porvencer">Vencen en 90 días</option>
          </select>
        )}
      </div>

      {err && <p className="rounded-md bg-red-50 p-3 text-sm text-red-600">No se pudo cargar: {err.message}. ¿Ya ejecutó los scripts 04 y 05 y las cargas?</p>}
      {cargando && <p className="text-gray-500">Cargando…</p>}

      {pestana === 'reactivos' && !cargando && (
        <div className="overflow-x-auto rounded-lg border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b bg-gray-50 text-gray-600"><tr>
              <th className={th}>ID</th><th className={th}>Reactivo</th><th className={`${th} text-right`}>Existencia</th><th className={th}>Vencimiento</th><th className={th}>Lote</th><th className={th}>Ubicación</th><th className={th}>Estado</th>
            </tr></thead>
            <tbody>
              {rea.slice(0, MAX).map((e: any) => {
                const venc = e.fecha_caducidad && e.fecha_caducidad < hoy
                const por = e.fecha_caducidad && !venc && e.fecha_caducidad < lim
                return (
                  <tr key={e.id} className={`border-b last:border-0 ${e.revisar ? 'bg-yellow-50' : ''}`} title={e.motivo_revision ?? ''}>
                    <td className="px-3 py-1.5 font-mono text-xs">{e.id_inventario}</td>
                    <td className="px-3 py-1.5 font-medium">{e.catalogo_reactivos?.nombre}</td>
                    <td className="px-3 py-1.5 text-right">{num(e.cantidad_actual)} {e.catalogo_reactivos?.unidad}</td>
                    <td className="px-3 py-1.5">{e.fecha_caducidad ?? '—'}{venc && <span className="ml-2 rounded-full bg-red-100 px-2 py-0.5 text-xs text-red-700">Vencido</span>}{por && <span className="ml-2 rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-800">Por vencer</span>}</td>
                    <td className="px-3 py-1.5">{e.lote ?? '—'}</td>
                    <td className="px-3 py-1.5">{e.ubicacion_texto ?? '—'}</td>
                    <td className="px-3 py-1.5">{e.revisar ? <span className="text-amber-700" title={e.motivo_revision ?? ''}>Revisar</span> : e.estado}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
          {rea.length > MAX && <p className="p-3 text-xs text-gray-500">Mostrando {MAX} de {rea.length}. Use la búsqueda para acotar.</p>}
        </div>
      )}

      {pestana === 'equipos' && !cargando && (
        <div className="overflow-x-auto rounded-lg border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b bg-gray-50 text-gray-600"><tr>
              <th className={th}>ID</th><th className={th}>Equipo</th><th className={th}>Salón</th><th className={`${th} text-right`}>Cant.</th><th className={th}>Estado</th><th className={th}>Ubicación</th>
            </tr></thead>
            <tbody>
              {eq.slice(0, MAX).map((e: any) => (
                <tr key={e.id} className={`border-b last:border-0 ${e.revisar ? 'bg-yellow-50' : ''}`} title={e.motivo_revision ?? ''}>
                  <td className="px-3 py-1.5 font-mono text-xs">{e.id_inventario}</td>
                  <td className="px-3 py-1.5 font-medium">{e.nombre}<span className="ml-2 text-xs text-gray-400">{[e.marca, e.modelo].filter(Boolean).join(' ')}</span></td>
                  <td className="px-3 py-1.5">{e.salon ?? '—'}</td>
                  <td className="px-3 py-1.5 text-right">{e.cantidad}</td>
                  <td className="px-3 py-1.5">{e.estado.replaceAll('_', ' ')}</td>
                  <td className="px-3 py-1.5">{e.fuera_de_sede ? <span className="rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-800">En {e.fuera_de_sede}: hacer traslado</span> : 'En la sede'}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {eq.length > MAX && <p className="p-3 text-xs text-gray-500">Mostrando {MAX} de {eq.length}.</p>}
        </div>
      )}

      {pestana === 'vidrieria' && !cargando && (
        vi.length === 0 ? (
          <p className="rounded-lg border bg-white p-4 text-sm text-gray-500">Aún no hay vidriería cargada en esta sede. Se diligencia en la hoja «Vidriería» del libro de Excel y se carga con el generador.</p>
        ) : (
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600"><tr>
                <th className={th}>ID</th><th className={th}>Ítem</th><th className={`${th} text-right`}>Buenas</th><th className={`${th} text-right`}>Regulares</th><th className={`${th} text-right`}>Dañadas</th><th className={th}>Ubicación</th>
              </tr></thead>
              <tbody>
                {vi.map((v: any) => (
                  <tr key={v.id} className="border-b last:border-0">
                    <td className="px-3 py-1.5 font-mono text-xs">{v.id_inventario}</td>
                    <td className="px-3 py-1.5 font-medium">{v.catalogo_materiales?.nombre}</td>
                    <td className="px-3 py-1.5 text-right">{v.cantidad_buena}</td><td className="px-3 py-1.5 text-right">{v.cantidad_regular}</td><td className="px-3 py-1.5 text-right">{v.cantidad_danada}</td>
                    <td className="px-3 py-1.5">{v.ubicacion ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )
      )}
    </div>
  )
}

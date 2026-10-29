import { useMemo, useState } from 'react'
import { Link, useLocation, useSearchParams } from 'react-router-dom'
import {
  useSesiones,
  useDecidirSesiones,
  useDeshacerDecision,
  useReactivosSesion,
  useMaterialesSesion,
  LIMITE_SESIONES,
  type SesionRow,
} from '@/hooks/useSesiones'
import { useCampus, useLaboratorios } from '@/hooks/useCatalogos'
import { useDisponibilidad, resumenDisponibilidad } from '@/hooks/useInventario'
import { TablaDisponibilidad } from '@/components/Disponibilidad'
import { usePerfil } from '@/hooks/usePerfil'
import type { EstadoSesion } from '@/lib/types'
import { addDays, endOfMonth, format, parseISO, startOfMonth } from 'date-fns'
import { es } from 'date-fns/locale'

const ESTADOS: { valor: string; label: string }[] = [
  { valor: 'todos', label: 'Todos los estados' },
  { valor: 'borrador', label: 'Borrador' },
  { valor: 'solicitada', label: 'Solicitada' },
  { valor: 'aprobada', label: 'Aprobada' },
  { valor: 'rechazada', label: 'Rechazada' },
  { valor: 'finalizada', label: 'Finalizada' },
  { valor: 'cancelada', label: 'Cancelada' },
]

const MOTIVOS = [
  'Falta información de reactivos',
  'Cruce de horario',
  'Laboratorio no disponible',
  'Cantidades inconsistentes',
]

const estadoColor: Record<string, string> = {
  borrador: 'bg-gray-100 text-gray-600',
  solicitada: 'bg-amber-100 text-amber-700',
  aprobada: 'bg-green-100 text-green-700',
  rechazada: 'bg-red-100 text-red-700',
  finalizada: 'bg-blue-100 text-blue-700',
  cancelada: 'bg-gray-200 text-gray-500',
}

const fechaCorta = (iso: string) => {
  try { return format(parseISO(iso), 'd MMM yyyy', { locale: es }) } catch { return iso }
}
const hora = (iso: string) => {
  try { return format(parseISO(iso), 'HH:mm') } catch { return '' }
}
const hoy = () => format(new Date(), 'yyyy-MM-dd')

function alertasDe(s: SesionRow): string[] {
  const a: string[] = []
  const n = (s.pendientes ?? []).filter((p) => !p.resuelta).length
  if (n > 0) a.push(`${n} línea${n > 1 ? 's' : ''} sin vincular al catálogo`)
  if (!s.campus_id) a.push('Sin campus')
  return a
}

export default function ListaSesiones() {
  const { esPersonal, esDocente } = usePerfil()
  const [params, setParams] = useSearchParams()
  const location = useLocation()

  // Los filtros viven en la dirección de la página: se pueden guardar o compartir
  const estadoParam = params.get('estado') ?? (esPersonal ? 'solicitada' : 'todos')
  const campusId = params.get('campus') ?? ''
  const desde = params.get('desde') ?? ''
  const hasta = params.get('hasta') ?? ''
  const texto = params.get('q') ?? ''
  const soloMias = params.get('mias') === '1' || (!esPersonal && params.get('mias') !== '0')

  const setFiltro = (cambios: Record<string, string>) => {
    const p = new URLSearchParams(params)
    Object.entries(cambios).forEach(([k, v]) => (v ? p.set(k, v) : p.delete(k)))
    setParams(p, { replace: true })
  }

  const { data: campus } = useCampus()
  const { data: laboratorios } = useLaboratorios()
  const { data: sesiones, isLoading, error } = useSesiones({
    estado: estadoParam === 'todos' ? undefined : (estadoParam as EstadoSesion),
    campusId: campusId || undefined,
    desde: desde || undefined,
    hasta: hasta || undefined,
    soloMias,
  })

  const decidir = useDecidirSesiones()
  const deshacer = useDeshacerDecision()

  const [sel, setSel] = useState<Set<string>>(new Set())
  const [abiertas, setAbiertas] = useState<Set<string>>(new Set())
  const [rechazando, setRechazando] = useState(false)
  const [motivo, setMotivo] = useState('')
  const [laboratorioId, setLaboratorioId] = useState('')
  const [soloDisp, setSoloDisp] = useState(true)
  const [verDisp, setVerDisp] = useState(false)
  const avisoInicial = (location.state as { aviso?: string } | null)?.aviso
  const [aviso, setAviso] = useState<{ texto: string; ids: string[]; errores: string[] } | null>(
    avisoInicial ? { texto: avisoInicial, ids: [], errores: [] } : null,
  )

  const visibles = useMemo(() => {
    const q = texto.trim().toLowerCase()
    if (!sesiones) return []
    return sesiones.filter(
      (s) =>
        !q ||
        `${s.practicas?.nombre ?? ''} ${s.docente?.nombre ?? ''} ${s.curso ?? ''} ${s.programa_academico ?? ''}`
          .toLowerCase()
          .includes(q),
    )
  }, [sesiones, texto])

  const decidibles = visibles.filter((s) => s.estado === 'solicitada')
  const seleccionadas = visibles.filter((s) => sel.has(s.id))
  const sinLab = seleccionadas.filter((s) => !s.laboratorio_id).length
  const idsSel = seleccionadas.map((s) => s.id)
  const { data: disp, isFetching: verificando } = useDisponibilidad(idsSel, esPersonal && idsSel.length > 0 && idsSel.length <= 80)
  const rd = resumenDisponibilidad(disp)
  const todasMarcadas = decidibles.length > 0 && decidibles.every((s) => sel.has(s.id))

  const alternar = (id: string) =>
    setSel((prev) => {
      const n = new Set(prev)
      n.has(id) ? n.delete(id) : n.add(id)
      return n
    })

  const marcarTodas = () => setSel(todasMarcadas ? new Set() : new Set(decidibles.map((s) => s.id)))
  const marcarSinAlertas = () =>
    setSel(new Set(decidibles.filter((s) => alertasDe(s).length === 0).map((s) => s.id)))

  const atajo = (tipo: '7' | 'mes' | 'quitar') => {
    if (tipo === '7') setFiltro({ desde: hoy(), hasta: format(addDays(new Date(), 7), 'yyyy-MM-dd') })
    if (tipo === 'mes')
      setFiltro({
        desde: format(startOfMonth(new Date()), 'yyyy-MM-dd'),
        hasta: format(endOfMonth(new Date()), 'yyyy-MM-dd'),
      })
    if (tipo === 'quitar') setFiltro({ desde: '', hasta: '' })
  }

  const aplicar = async (decision: 'aprobada' | 'rechazada') => {
    const ids = seleccionadas.map((s) => s.id)
    try {
      const r = await decidir.mutateAsync({
        ids,
        decision,
        motivo: decision === 'rechazada' ? motivo : undefined,
        laboratorioId: laboratorioId || null,
        soloSiDisponible: decision === 'aprobada' && soloDisp,
      })
      const ok = r.resultados.filter((x) => x.ok).map((x) => x.id)
      const errores = r.resultados.filter((x) => !x.ok).map((x) => x.mensaje ?? 'Error')
      setAviso({
        texto: `${r.aplicadas} sesión${r.aplicadas === 1 ? '' : 'es'} ${decision === 'aprobada' ? 'aprobada' : 'rechazada'}${r.aplicadas === 1 ? '' : 's'}.`,
        ids: ok,
        errores,
      })
      setSel(new Set())
      setRechazando(false)
      setMotivo('')
      setLaboratorioId('')
    } catch (e) {
      setAviso({ texto: (e as Error).message, ids: [], errores: [] })
    }
  }

  const inputCss =
    'rounded-lg border border-gray-300 px-3 py-1.5 text-sm focus:border-brand-500 focus:outline-none'

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold text-gray-800">Sesiones de práctica</h1>
        {(esDocente || esPersonal) && (
          <Link
            to="/sesiones/nueva"
            className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700"
          >
            + Nueva sesión
          </Link>
        )}
      </div>

      {/* Filtros */}
      <div className="flex flex-wrap items-end gap-3">
        <label className="flex flex-col gap-1 text-xs text-gray-500">
          Estado
          <select value={estadoParam} onChange={(e) => setFiltro({ estado: e.target.value })} className={inputCss}>
            {ESTADOS.map((e) => (
              <option key={e.valor} value={e.valor}>{e.label}</option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs text-gray-500">
          Campus
          <select value={campusId} onChange={(e) => setFiltro({ campus: e.target.value })} className={inputCss}>
            <option value="">Todos</option>
            {campus?.map((c) => (
              <option key={c.id} value={c.id}>{c.nombre}</option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-xs text-gray-500">
          Desde
          <input type="date" value={desde} onChange={(e) => setFiltro({ desde: e.target.value })} className={inputCss} />
        </label>
        <label className="flex flex-col gap-1 text-xs text-gray-500">
          Hasta
          <input type="date" value={hasta} onChange={(e) => setFiltro({ hasta: e.target.value })} className={inputCss} />
        </label>
        <label className="flex min-w-[10rem] flex-1 flex-col gap-1 text-xs text-gray-500">
          Buscar
          <input
            type="search"
            placeholder="Práctica, docente o curso"
            value={texto}
            onChange={(e) => setFiltro({ q: e.target.value })}
            className={inputCss}
          />
        </label>
        {esPersonal && (
          <label className="flex items-center gap-2 pb-2 text-sm text-gray-600">
            <input
              type="checkbox"
              checked={soloMias}
              onChange={(e) => setFiltro({ mias: e.target.checked ? '1' : '0' })}
              className="rounded border-gray-300"
            />
            Solo mis sesiones
          </label>
        )}
      </div>

      <div className="flex flex-wrap gap-2 text-sm">
        <button onClick={() => atajo('7')} className="rounded-full border border-gray-300 px-3 py-1 hover:border-brand-500">
          Próximos 7 días
        </button>
        <button onClick={() => atajo('mes')} className="rounded-full border border-gray-300 px-3 py-1 hover:border-brand-500">
          Este mes
        </button>
        {(desde || hasta) && (
          <button onClick={() => atajo('quitar')} className="rounded-full px-3 py-1 text-gray-500 hover:text-gray-800">
            Quitar fechas
          </button>
        )}
        {esPersonal && decidibles.length > 0 && (
          <button
            onClick={marcarSinAlertas}
            className="rounded-full border border-brand-500 px-3 py-1 text-brand-700 hover:bg-brand-50"
          >
            Seleccionar las que no tienen alertas
          </button>
        )}
      </div>

      {/* Barra de decisión en bloque */}
      {esPersonal && seleccionadas.length > 0 && (
        <div className="sticky top-2 z-10 space-y-3 rounded-lg bg-gray-900 p-3 text-white shadow-lg">
          <div className="flex flex-wrap items-center gap-3">
            <span className="text-sm font-medium">
              {seleccionadas.length} seleccionada{seleccionadas.length > 1 ? 's' : ''}
            </span>
            {sinLab > 0 && (
              <label className="flex items-center gap-2 text-sm">
                Laboratorio para las {sinLab} sin asignar:
                <select
                  value={laboratorioId}
                  onChange={(e) => setLaboratorioId(e.target.value)}
                  className="rounded border-0 px-2 py-1 text-sm text-gray-900"
                >
                  <option value="">Seleccionar…</option>
                  {laboratorios?.map((l) => (
                    <option key={l.id} value={l.id}>{l.nombre}</option>
                  ))}
                </select>
              </label>
            )}
            <button
              onClick={() => aplicar('aprobada')}
              disabled={decidir.isPending || (sinLab > 0 && !laboratorioId)}
              className="rounded-lg bg-green-600 px-4 py-1.5 text-sm font-medium hover:bg-green-700 disabled:opacity-40"
            >
              Aprobar
            </button>
            <button
              onClick={() => setRechazando((v) => !v)}
              className="rounded-lg bg-white/10 px-4 py-1.5 text-sm font-medium hover:bg-white/20"
            >
              Rechazar…
            </button>
            <button onClick={() => setSel(new Set())} className="text-sm text-gray-300 hover:text-white">
              Limpiar
            </button>
          </div>
          <div className="flex flex-wrap items-center gap-4 text-sm">
            <span>
              {idsSel.length > 80 ? 'Existencias: seleccione 80 o menos para verificar'
                : verificando ? 'Verificando existencias…'
                : rd.conFaltantes === 0 && rd.conTraslado === 0 ? '✓ Existencias suficientes en las sedes'
                : `${rd.conFaltantes > 0 ? `⚠ ${rd.conFaltantes} con faltantes` : ''}${rd.conFaltantes > 0 && rd.conTraslado > 0 ? ' · ' : ''}${rd.conTraslado > 0 ? `${rd.conTraslado} con traslado de equipos` : ''}`}
            </span>
            {(rd.conFaltantes > 0 || rd.conTraslado > 0) && (
              <button onClick={() => setVerDisp((v) => !v)} className="text-teal-300 hover:underline">
                {verDisp ? 'Ocultar detalle' : 'Ver detalle'}
              </button>
            )}
            <label className="flex items-center gap-2">
              <input type="checkbox" checked={soloDisp} onChange={(e) => setSoloDisp(e.target.checked)} />
              Aprobar solo las que tengan todo
            </label>
          </div>
          {verDisp && (
            <div className="max-h-72 space-y-3 overflow-y-auto rounded-lg bg-white p-3 text-gray-800">
              {seleccionadas
                .filter((s) => rd.porSesion.get(s.id)?.some((l) => l.estado === 'falta' || l.estado === 'ok_traslado'))
                .map((s) => (
                  <div key={s.id}>
                    <p className="mb-1 text-sm font-medium">
                      {s.practicas?.nombre ?? 'Práctica'} · {s.campus?.nombre ?? 'sin campus'} · {s.inicio.slice(0, 10)}
                    </p>
                    <TablaDisponibilidad
                      lineas={(rd.porSesion.get(s.id) ?? []).filter((l) => l.estado === 'falta' || l.estado === 'ok_traslado')}
                    />
                  </div>
                ))}
            </div>
          )}
          {rechazando && (
            <div className="space-y-2 rounded-lg bg-white p-3 text-gray-800">
              <p className="text-sm font-medium">
                Motivo del rechazo para las {seleccionadas.length} sesiones (se guarda en cada una)
              </p>
              <div className="flex flex-wrap gap-2">
                {MOTIVOS.map((m) => (
                  <button
                    key={m}
                    type="button"
                    onClick={() => setMotivo(m)}
                    className="rounded-full border border-gray-300 px-3 py-1 text-xs hover:border-brand-500"
                  >
                    {m}
                  </button>
                ))}
              </div>
              <input
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                placeholder="Motivo"
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              />
              <button
                onClick={() => aplicar('rechazada')}
                disabled={decidir.isPending || !motivo.trim()}
                className="rounded-lg bg-red-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-40"
              >
                Confirmar rechazo
              </button>
            </div>
          )}
        </div>
      )}

      {aviso && (
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg bg-gray-900 px-4 py-3 text-sm text-white">
          <div>
            <p>{aviso.texto}</p>
            {aviso.errores.length > 0 && (
              <p className="mt-1 text-amber-300">No se aplicó a {aviso.errores.length}: {[...new Set(aviso.errores)].join('; ')}</p>
            )}
          </div>
          <div className="flex gap-3">
            {aviso.ids.length > 0 && (
              <button
                onClick={async () => {
                  await deshacer.mutateAsync(aviso.ids)
                  setAviso(null)
                }}
                className="font-medium text-teal-300 hover:underline"
              >
                Deshacer
              </button>
            )}
            <button onClick={() => setAviso(null)} className="text-gray-300 hover:text-white">Cerrar</button>
          </div>
        </div>
      )}

      {isLoading && <p className="text-gray-500">Cargando…</p>}
      {error && <p className="text-red-500">Error: {(error as Error).message}</p>}
      {sesiones && visibles.length === 0 && (
        <p className="py-8 text-center text-gray-400">No hay sesiones con estos filtros.</p>
      )}

      {visibles.length > 0 && (
        <>
          <p className="text-xs text-gray-500">
            {visibles.length} sesión{visibles.length > 1 ? 'es' : ''}
            {sesiones && sesiones.length >= LIMITE_SESIONES && ` (se muestran las primeras ${LIMITE_SESIONES}; afine los filtros)`}
          </p>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600">
                <tr>
                  {esPersonal && (
                    <th className="w-10 px-3 py-2">
                      <input
                        type="checkbox"
                        checked={todasMarcadas}
                        disabled={decidibles.length === 0}
                        onChange={marcarTodas}
                        aria-label="Seleccionar todas las solicitadas visibles"
                      />
                    </th>
                  )}
                  <th className="px-3 py-2">Práctica de laboratorio</th>
                  <th className="px-3 py-2">Docente</th>
                  <th className="px-3 py-2">Campus</th>
                  <th className="px-3 py-2">Fecha</th>
                  <th className="px-3 py-2">Horario</th>
                  <th className="px-3 py-2">Laboratorio</th>
                  <th className="px-3 py-2">Est.</th>
                  <th className="px-3 py-2">Estado</th>
                </tr>
              </thead>
              <tbody>
                {visibles.map((s) => {
                  const al = alertasDe(s)
                  const abierta = abiertas.has(s.id)
                  return (
                    <FilaSesion
                      key={s.id}
                      s={s}
                      alertas={al}
                      abierta={abierta}
                      esPersonal={esPersonal}
                      marcada={sel.has(s.id)}
                      onMarcar={() => alternar(s.id)}
                      onAbrir={() =>
                        setAbiertas((prev) => {
                          const n = new Set(prev)
                          n.has(s.id) ? n.delete(s.id) : n.add(s.id)
                          return n
                        })
                      }
                    />
                  )
                })}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  )
}

function FilaSesion(props: {
  s: SesionRow
  alertas: string[]
  abierta: boolean
  esPersonal: boolean
  marcada: boolean
  onMarcar: () => void
  onAbrir: () => void
}) {
  const { s, alertas, abierta, esPersonal, marcada, onMarcar, onAbrir } = props
  const puedeMarcar = esPersonal && s.estado === 'solicitada'
  return (
    <>
      <tr className="border-b hover:bg-gray-50">
        {esPersonal && (
          <td className="px-3 py-2">
            <input
              type="checkbox"
              checked={marcada}
              disabled={!puedeMarcar}
              onChange={onMarcar}
              aria-label={`Seleccionar ${s.practicas?.nombre ?? 'sesión'}`}
            />
          </td>
        )}
        <td className="px-3 py-2">
          <button onClick={onAbrir} aria-expanded={abierta} className="text-left font-medium text-brand-700 hover:underline">
            {s.practicas?.nombre ?? '(sin práctica)'}
          </button>
          {alertas.length > 0 && (
            <span className="ml-2 rounded-full bg-amber-100 px-2 py-0.5 text-xs text-amber-700">
              {alertas.length} alerta{alertas.length > 1 ? 's' : ''}
            </span>
          )}
        </td>
        <td className="px-3 py-2">{s.docente?.nombre ?? '—'}</td>
        <td className="px-3 py-2">{s.campus?.nombre ?? '—'}</td>
        <td className="whitespace-nowrap px-3 py-2">{fechaCorta(s.inicio)}</td>
        <td className="whitespace-nowrap px-3 py-2">{hora(s.inicio)}–{hora(s.fin)}</td>
        <td className="px-3 py-2">{s.laboratorios?.nombre ?? <span className="text-gray-400">Por asignar</span>}</td>
        <td className="px-3 py-2 text-center">{s.num_estudiantes ?? '—'}</td>
        <td className="px-3 py-2">
          <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium ${estadoColor[s.estado] ?? ''}`}>
            {s.estado}
          </span>
        </td>
      </tr>
      {abierta && (
        <tr className="border-b bg-gray-50">
          <td colSpan={esPersonal ? 9 : 8} className="px-4 py-3">
            <VistaRapida s={s} alertas={alertas} />
          </td>
        </tr>
      )}
    </>
  )
}

function VistaRapida({ s, alertas }: { s: SesionRow; alertas: string[] }) {
  const { data: reactivos } = useReactivosSesion(s.id)
  const { data: materiales } = useMaterialesSesion(s.id)
  return (
    <div className="space-y-2 text-sm">
      <p className="text-gray-700">
        <b>Programa:</b> {s.programa_academico ?? '—'} · <b>Curso:</b> {s.curso ?? '—'} ·{' '}
        <b>Grupos de trabajo:</b> {s.num_grupos_trabajo ?? '—'} · <b>Agua destilada estimada:</b>{' '}
        {s.agua_destilada_l != null ? `${s.agua_destilada_l} L` : '—'}
      </p>
      <p className="text-gray-700">
        <b>Reactivos vinculados:</b> {reactivos?.length ?? '…'} · <b>Materiales vinculados:</b> {materiales?.length ?? '…'}
      </p>
      {alertas.length > 0 && <p className="text-amber-700"><b>Alertas:</b> {alertas.join(' · ')}</p>}
      {s.motivo_rechazo && <p className="text-red-700"><b>Motivo del rechazo:</b> {s.motivo_rechazo}</p>}
      {s.observaciones && <p className="whitespace-pre-wrap text-gray-600"><b>Observaciones:</b> {s.observaciones}</p>}
      <Link to={`/sesiones/${s.id}`} className="inline-block text-brand-700 hover:underline">
        Abrir detalle completo →
      </Link>
    </div>
  )
}

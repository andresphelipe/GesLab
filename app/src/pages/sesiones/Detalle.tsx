import { useState } from 'react'
import { useParams, useNavigate, useLocation, Link } from 'react-router-dom'
import {
  useSesion,
  useDecidirSesiones,
  useReactivosSesion,
  useMaterialesSesion,
  usePendientesSesion,
  useResolverPendiente,
  useCatalogoItems,
} from '@/hooks/useSesiones'
import { useLaboratorios } from '@/hooks/useCatalogos'
import { useDisponibilidad, useRegistrarConsumo } from '@/hooks/useInventario'
import { TablaDisponibilidad } from '@/components/Disponibilidad'
import { usePerfil } from '@/hooks/usePerfil'
import { format, parseISO } from 'date-fns'
import { es } from 'date-fns/locale'

function fmt(iso: string) {
  try {
    return format(parseISO(iso), "EEEE d 'de' MMMM yyyy, HH:mm", { locale: es })
  } catch {
    return iso
  }
}

const estadoColor: Record<string, string> = {
  borrador: 'bg-gray-100 text-gray-600',
  solicitada: 'bg-amber-100 text-amber-700',
  aprobada: 'bg-green-100 text-green-700',
  rechazada: 'bg-red-100 text-red-700',
  finalizada: 'bg-blue-100 text-blue-700',
  cancelada: 'bg-gray-200 text-gray-500',
}

const MOTIVOS = [
  'Falta información de reactivos',
  'Cruce de horario',
  'Laboratorio no disponible',
  'Cantidades inconsistentes',
]

const cant = (c: number | null | undefined, u?: string | null) =>
  c == null ? '—' : `${c}${u ? ' ' + u : ''}`

export default function DetalleSesion() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const location = useLocation()
  const aviso = location.state as { aviso?: string; avisos?: { item: string; estado: string; mensaje: string | null }[] } | null
  const { vincular, descartar } = useResolverPendiente()
  const { data: items } = useCatalogoItems()
  const [elegido, setElegido] = useState<Record<string, string>>({})
  const { esPersonal } = usePerfil()
  const { data: sesion, isLoading, error } = useSesion(id)
  const { data: reactivos } = useReactivosSesion(id)
  const { data: materiales } = useMaterialesSesion(id)
  const { data: pendientes } = usePendientesSesion(id)
  const { data: laboratorios } = useLaboratorios()
  const decidir = useDecidirSesiones()
  const registrar = useRegistrarConsumo()
  const { data: disp } = useDisponibilidad(id ? [id] : [], esPersonal && !!sesion && ['solicitada', 'aprobada'].includes(sesion.estado))
  const [usado, setUsado] = useState<Record<string, string>>({})
  const [rotas, setRotas] = useState<Record<string, string>>({})
  const [msgConsumo, setMsgConsumo] = useState<{ ok: boolean; texto: string } | null>(null)
  const [motivo, setMotivo] = useState('')
  const [mostrarRechazo, setMostrarRechazo] = useState(false)
  const [laboratorioId, setLaboratorioId] = useState('')
  const [fallo, setFallo] = useState<string | null>(null)
  const [soloDisp, setSoloDisp] = useState(false)

  if (isLoading) return <p className="text-gray-500">Cargando…</p>
  if (error) return <p className="text-red-500">Error: {(error as Error).message}</p>
  if (!sesion) return <p className="text-gray-500">Sesión no encontrada.</p>

  const puedeConsumo = esPersonal && ['aprobada', 'finalizada'].includes(sesion.estado)
  const guardarConsumo = async (finalizar: boolean) => {
    setMsgConsumo(null)
    try {
      await registrar.mutateAsync({
        sesionId: sesion.id,
        finalizar,
        reactivos: (reactivos ?? [])
          .filter((r: any) => usado[r.id] !== undefined && usado[r.id] !== '')
          .map((r: any) => ({ reactivo_id: r.reactivo_id, cantidad: Number(usado[r.id]), unidad: r.unidad ?? undefined })),
        materiales: (materiales ?? [])
          .filter((m: any) => rotas[m.id] !== undefined && rotas[m.id] !== '' && m.catalogo_materiales?.tipo_item !== 'equipo')
          .map((m: any) => ({ material_id: m.material_id, cantidad: Number(rotas[m.id]) })),
      })
      setUsado({}); setRotas({})
      setMsgConsumo({ ok: true, texto: finalizar ? 'Consumo guardado y sesión finalizada.' : 'Consumo guardado; el inventario se actualizó.' })
    } catch (e) {
      setMsgConsumo({ ok: false, texto: (e as Error).message })
    }
  }
  const copiarPrevisto = () => {
    const u: Record<string, string> = {}
    for (const r of reactivos ?? []) if (r.cantidad_prevista != null) u[r.id] = String(r.cantidad_prevista)
    setUsado(u)
  }
  const puedeDecidir = esPersonal && sesion.estado === 'solicitada'
  const necesitaLab = !sesion.laboratorio_id

  const aplicar = async (decision: 'aprobada' | 'rechazada') => {
    setFallo(null)
    try {
      const r = await decidir.mutateAsync({
        ids: [sesion.id],
        decision,
        motivo: decision === 'rechazada' ? motivo : undefined,
        laboratorioId: laboratorioId || null,
        soloSiDisponible: decision === 'aprobada' && soloDisp,
      })
      const res = r.resultados[0]
      if (!res?.ok) setFallo(res?.mensaje ?? 'No se pudo aplicar la decisión')
      else setMostrarRechazo(false)
    } catch (e) {
      setFallo((e as Error).message)
    }
  }

  const dato = (titulo: string, valor: React.ReactNode, ancho = false) => (
    <div className={ancho ? 'sm:col-span-2' : ''}>
      <dt className="font-medium text-gray-500">{titulo}</dt>
      <dd className="text-gray-800">{valor}</dd>
    </div>
  )

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <button onClick={() => navigate('/sesiones')} className="mb-1 text-sm text-brand-600 hover:underline">
            ← Volver a sesiones
          </button>
          <h1 className="text-xl font-bold text-gray-800">{sesion.practicas?.nombre ?? 'Sesión de práctica'}</h1>
        </div>
        <div className="flex items-center gap-3">
          {esPersonal && ['solicitada', 'aprobada'].includes(sesion.estado) && (
            <Link to={`/sesiones/${sesion.id}/editar`} className="rounded-lg border border-brand-500 px-3 py-1 text-sm font-medium text-brand-600 hover:bg-brand-50">
              Editar solicitud
            </Link>
          )}
          <span className={`rounded-full px-3 py-1 text-sm font-medium ${estadoColor[sesion.estado] ?? ''}`}>
            {sesion.estado}
          </span>
        </div>
      </div>

      {aviso?.aviso && (
        <div className="rounded-lg bg-green-50 p-3 text-sm text-green-800">
          <p>{aviso.aviso}</p>
          {aviso.avisos && aviso.avisos.length > 0 && (
            <ul className="mt-1 list-disc pl-5 text-amber-800">
              {aviso.avisos.map((a, i) => <li key={i}>{a.item}: {a.mensaje ?? a.estado}</li>)}
            </ul>
          )}
        </div>
      )}

      <div className="rounded-xl border bg-white p-5 shadow-sm">
        <dl className="grid gap-x-6 gap-y-3 text-sm sm:grid-cols-2">
          {dato('Docente', sesion.docente?.nombre ?? '—')}
          {esPersonal && dato('Contacto del docente', <span>{sesion.docente?.email ?? '—'} · {sesion.docente?.celular ?? 'sin celular'}</span>)}
          {dato('Campus', sesion.campus?.nombre ?? '—')}
          {dato('Programa académico', sesion.programa_academico ?? '—')}
          {dato('Curso', sesion.curso ?? '—')}
          {dato('Inicio', fmt(sesion.inicio))}
          {dato('Fin', fmt(sesion.fin))}
          {dato('Estudiantes / Grupos de trabajo', `${sesion.num_estudiantes ?? '—'} / ${sesion.num_grupos_trabajo ?? '—'}`)}
          {dato('Agua destilada estimada', sesion.agua_destilada_l != null ? `${sesion.agua_destilada_l} L` : '—')}
          {dato('Laboratorio', sesion.laboratorios?.nombre ?? <span className="text-gray-400">Por asignar</span>)}
          {sesion.motivo_rechazo && dato('Motivo del rechazo', <span className="text-red-700">{sesion.motivo_rechazo}</span>, true)}
          {sesion.observaciones && dato('Observaciones', <span className="whitespace-pre-wrap">{sesion.observaciones}</span>, true)}
        </dl>
      </div>

      {pendientes && pendientes.length > 0 && (
        <div className="rounded-lg border border-amber-300 bg-amber-50 p-4 text-sm text-amber-900">
          <p className="font-medium">
            {pendientes.length} línea{pendientes.length > 1 ? 's' : ''} sin vincular al catálogo
          </p>
          <ul className="mt-2 space-y-2">
            {pendientes.map((p: any) => {
              const opciones = (p.tipo === 'reactivo' ? items?.reactivos : items?.materiales) ?? []
              return (
                <li key={p.id} className="flex flex-wrap items-center gap-2">
                  <span>
                    {p.tipo === 'reactivo' ? 'Reactivo' : 'Material'}: <b>{p.texto_original}</b>
                    {p.cantidad != null ? ` (${cant(p.cantidad, p.unidad)})` : ''}
                  </span>
                  {esPersonal && (
                    <>
                      <select value={elegido[p.id] ?? ''} onChange={(e) => setElegido((x) => ({ ...x, [p.id]: e.target.value }))}
                        className="max-w-[16rem] rounded border border-amber-300 bg-white px-2 py-1 text-xs">
                        <option value="">Vincular con…</option>
                        {opciones.map((o) => <option key={o.id} value={o.id}>{o.nombre}</option>)}
                      </select>
                      <button disabled={!elegido[p.id] || vincular.isPending}
                        onClick={() => vincular.mutate({ id: p.id, itemId: elegido[p.id] })}
                        className="rounded bg-amber-600 px-2 py-1 text-xs font-medium text-white disabled:opacity-40">Vincular</button>
                      <button onClick={() => descartar.mutate(p.id)} className="text-xs text-amber-800 underline">Descartar</button>
                    </>
                  )}
                </li>
              )
            })}
          </ul>
          {(vincular.error || descartar.error) && <p className="mt-2 text-red-700">{((vincular.error || descartar.error) as Error).message}</p>}
          {esPersonal && <p className="mt-2 text-xs">Al vincular, el sistema recuerda ese nombre y lo reconocerá la próxima vez.</p>}
        </div>
      )}

      {esPersonal && ['solicitada', 'aprobada'].includes(sesion.estado) && disp && (
        <section>
          <h2 className="mb-2 text-lg font-semibold text-gray-800">¿Hay lo que se pide en {sesion.campus?.nombre ?? 'la sede'}?</h2>
          <TablaDisponibilidad lineas={disp} />
        </section>
      )}

      {reactivos && reactivos.length > 0 && (
        <section>
          <h2 className="mb-2 text-lg font-semibold text-gray-800">Reactivos</h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600">
                <tr>
                  <th className="px-4 py-2">Reactivo</th>
                  <th className="px-4 py-2">Fórmula</th>
                  <th className="px-4 py-2 text-right">Previsto</th>
                  <th className="px-4 py-2 text-right">Consumido</th>
                  <th className="px-4 py-2">Concentración</th>
                </tr>
              </thead>
              <tbody>
                {reactivos.map((r: any) => (
                  <tr key={r.id} className="border-b last:border-0">
                    <td className="px-4 py-2 font-medium">{r.catalogo_reactivos?.nombre}</td>
                    <td className="px-4 py-2 font-mono text-xs">{r.catalogo_reactivos?.formula ?? '—'}</td>
                    <td className="px-4 py-2 text-right">{cant(r.cantidad_prevista, r.unidad)}</td>
                    <td className="px-4 py-2 text-right">
                      {puedeConsumo ? (
                        <input type="number" min="0" step="any" value={usado[r.id] ?? ''} placeholder={r.cantidad_consumida != null ? String(r.cantidad_consumida) : '0'}
                          onChange={(e) => setUsado((p) => ({ ...p, [r.id]: e.target.value }))}
                          className="w-24 rounded border border-gray-300 px-2 py-1 text-right text-sm" />
                      ) : cant(r.cantidad_consumida, r.unidad)}
                    </td>
                    <td className="px-4 py-2">{r.concentracion ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {materiales && materiales.length > 0 && (
        <section>
          <h2 className="mb-2 text-lg font-semibold text-gray-800">Equipos y vidriería</h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600">
                <tr>
                  <th className="px-4 py-2">Material</th>
                  <th className="px-4 py-2 text-right">Previsto</th>
                  <th className="px-4 py-2 text-right">{puedeConsumo ? 'Rotas' : 'Consumido'}</th>
                </tr>
              </thead>
              <tbody>
                {materiales.map((m: any) => (
                  <tr key={m.id} className="border-b last:border-0">
                    <td className="px-4 py-2 font-medium">{m.catalogo_materiales?.nombre}</td>
                    <td className="px-4 py-2 text-right">{cant(m.cantidad_prevista)}</td>
                    <td className="px-4 py-2 text-right">
                      {puedeConsumo && m.catalogo_materiales?.tipo_item !== 'equipo' ? (
                        <input type="number" min="0" step="1" value={rotas[m.id] ?? ''} placeholder={m.cantidad_consumida != null ? String(m.cantidad_consumida) : '0'}
                          onChange={(e) => setRotas((p) => ({ ...p, [m.id]: e.target.value }))}
                          className="w-20 rounded border border-gray-300 px-2 py-1 text-right text-sm" />
                      ) : cant(m.cantidad_consumida)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {puedeConsumo && (
        <div className="space-y-3 rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-800">Reporte de consumo</h2>
          <p className="text-sm text-gray-600">
            Escriba el <b>total</b> usado en la sesión (en la unidad de cada línea) y las piezas de vidriería rotas. Solo se descuenta la diferencia con lo ya reportado, del envase que vence primero en esta sede.
          </p>
          {msgConsumo && (
            <p className={`rounded-md p-2 text-sm ${msgConsumo.ok ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>{msgConsumo.texto}</p>
          )}
          <div className="flex flex-wrap gap-3">
            <button type="button" onClick={copiarPrevisto} className="rounded-lg border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50">
              Usar lo previsto
            </button>
            <button onClick={() => guardarConsumo(false)} disabled={registrar.isPending}
              className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">
              Guardar consumo
            </button>
            {sesion.estado === 'aprobada' && (
              <button onClick={() => guardarConsumo(true)} disabled={registrar.isPending}
                className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50">
                Guardar y finalizar sesión
              </button>
            )}
          </div>
        </div>
      )}

      {puedeDecidir && (
        <div className="space-y-3 rounded-xl border bg-white p-5 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-800">Aprobar o rechazar</h2>

          {necesitaLab && (
            <label className="block text-sm text-gray-700">
              Laboratorio asignado (obligatorio para aprobar)
              <select
                value={laboratorioId}
                onChange={(e) => setLaboratorioId(e.target.value)}
                className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              >
                <option value="">Seleccionar…</option>
                {laboratorios?.map((l) => (
                  <option key={l.id} value={l.id}>{l.nombre}</option>
                ))}
              </select>
            </label>
          )}

          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" checked={soloDisp} onChange={(e) => setSoloDisp(e.target.checked)} />
            Aprobar solo si hay todo lo solicitado
          </label>

          {fallo && <p className="rounded-md bg-red-50 p-2 text-sm text-red-600">{fallo}</p>}

          {mostrarRechazo ? (
            <div className="space-y-3">
              <div className="flex flex-wrap gap-2">
                {MOTIVOS.map((m) => (
                  <button key={m} type="button" onClick={() => setMotivo(m)}
                    className="rounded-full border border-gray-300 px-3 py-1 text-xs hover:border-brand-500">{m}</button>
                ))}
              </div>
              <textarea
                placeholder="Motivo del rechazo"
                rows={2}
                value={motivo}
                onChange={(e) => setMotivo(e.target.value)}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none"
              />
              <div className="flex gap-3">
                <button
                  onClick={() => aplicar('rechazada')}
                  disabled={decidir.isPending || !motivo.trim()}
                  className="rounded-lg bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-50"
                >
                  Confirmar rechazo
                </button>
                <button onClick={() => setMostrarRechazo(false)} className="text-sm text-gray-500 hover:text-gray-700">
                  Cancelar
                </button>
              </div>
            </div>
          ) : (
            <div className="flex gap-3">
              <button
                onClick={() => aplicar('aprobada')}
                disabled={decidir.isPending || (necesitaLab && !laboratorioId)}
                className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50"
              >
                Aprobar sesión
              </button>
              <button
                onClick={() => setMostrarRechazo(true)}
                className="rounded-lg border border-red-300 px-4 py-2 text-sm font-medium text-red-600 hover:bg-red-50"
              >
                Rechazar
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useSesion, useReactivosSesion, useMaterialesSesion, useEditarSesion } from '@/hooks/useSesiones'
import { useCampus, useLaboratorios, useReconocimiento } from '@/hooks/useCatalogos'
import { supabase } from '@/lib/supabase'

const UNIDADES = ['mL', 'L', 'g', 'kg', 'mg', 'unidad', 'frasco lavador', 'gotero']
const num = (v: string) => (v.trim() === '' || isNaN(Number(v)) ? null : Number(v))
const bogota = (iso: string) => {
  const s = new Date(iso).toLocaleString('sv-SE', { timeZone: 'America/Bogota' }) // 2026-03-05 09:00:00
  return { fecha: s.slice(0, 10), hora: s.slice(11, 16) }
}

type LineaR = { id?: string; nombre: string; texto: string; conc: string; cant: string; unidad: string; consumida: boolean }
type LineaM = { id?: string; nombre: string; texto: string; cant: string; consumida: boolean }

export default function EditarSesion() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { data: s } = useSesion(id)
  const { data: reac } = useReactivosSesion(id)
  const { data: mat } = useMaterialesSesion(id)
  const { data: campus } = useCampus()
  const { data: labs } = useLaboratorios()
  const { data: rec } = useReconocimiento()
  const editar = useEditarSesion()

  const [f, setF] = useState<Record<string, string> | null>(null)
  const [rs, setRs] = useState<LineaR[] | null>(null)
  const [ms, setMs] = useState<LineaM[] | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (s && !f) {
      const i = bogota(s.inicio), e = bogota(s.fin)
      setF({
        practica: s.practicas?.nombre ?? '', campus_id: s.campus_id ?? '', laboratorio_id: s.laboratorio_id ?? '',
        programa: s.programa_academico ?? '', curso: s.curso ?? '', agua: s.agua_destilada_l != null ? String(s.agua_destilada_l) : '',
        fecha: i.fecha, inicio: i.hora, fin: e.hora, estudiantes: s.num_estudiantes != null ? String(s.num_estudiantes) : '',
        mesas: s.num_grupos_trabajo != null ? String(s.num_grupos_trabajo) : '', observaciones: s.observaciones ?? '',
        doc_nombre: s.docente?.nombre ?? '', doc_celular: s.docente?.celular ?? '',
      })
    }
  }, [s, f])
  useEffect(() => {
    if (reac && !rs)
      setRs(reac.map((r: any) => ({ id: r.id, nombre: r.catalogo_reactivos?.nombre ?? '', texto: '', conc: r.concentracion ?? '',
        cant: r.cantidad_prevista != null ? String(r.cantidad_prevista) : '', unidad: r.unidad ?? '', consumida: r.cantidad_consumida != null })))
  }, [reac, rs])
  useEffect(() => {
    if (mat && !ms)
      setMs(mat.map((m: any) => ({ id: m.id, nombre: m.catalogo_materiales?.nombre ?? '', texto: '',
        cant: m.cantidad_prevista != null ? String(m.cantidad_prevista) : '', consumida: m.cantidad_consumida != null })))
  }, [mat, ms])

  if (!s || !f || !rs || !ms) return <p className="text-gray-500">Cargando…</p>
  if (!['solicitada', 'aprobada'].includes(s.estado))
    return <p className="text-gray-600">Solo se editan solicitudes enviadas o aprobadas.</p>

  const set = (k: string, v: string) => setF((p) => ({ ...p!, [k]: v }))
  const css = 'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none'
  const lbl = 'mb-1 block text-sm font-medium text-gray-700'
  const CEL = /^\+?[0-9 ]{7,15}$/
  const celularMal = f.doc_celular.trim() !== '' && !CEL.test(f.doc_celular.trim())
  const invalido = celularMal || !f.doc_nombre.trim() || !f.fecha || !f.inicio || !f.fin || f.fin <= f.inicio

  const guardar = async () => {
    setError(null)
    try {
      if (f.doc_nombre.trim() !== (s.docente?.nombre ?? '') || f.doc_celular.trim() !== (s.docente?.celular ?? '')) {
        const { error: ec } = await supabase.rpc('actualizar_contacto_docente', {
          p_docente: s.docente_id, p_nombre: f.doc_nombre, p_celular: f.doc_celular,
        })
        if (ec) throw ec
      }
      const r = await editar.mutateAsync({
        id: s.id,
        cambios: {
          practica_nombre: f.practica.trim() || undefined,
          campus_id: f.campus_id || null,
          laboratorio_id: f.laboratorio_id || null,
          programa_academico: f.programa.trim(),
          curso: f.curso.trim(),
          agua_destilada_l: num(f.agua),
          fecha: f.fecha, inicio: f.inicio, fin: f.fin,
          num_estudiantes: num(f.estudiantes),
          num_grupos_trabajo: num(f.mesas),
          observaciones: f.observaciones.trim(),
          reactivos: rs.filter((l) => l.id || l.texto.trim()).map((l) => ({
            id: l.id, texto: l.texto.trim() || undefined, cantidad: num(l.cant), unidad: l.unidad || null, concentracion: l.conc.trim() || null })),
          materiales: ms.filter((l) => l.id || l.texto.trim()).map((l) => ({ id: l.id, texto: l.texto.trim() || undefined, cantidad: num(l.cant) })),
        },
      })
      navigate(`/sesiones/${s.id}`, {
        state: { aviso: 'Cambios guardados.' + (r.pendientes_nuevas ? ` ${r.pendientes_nuevas} línea(s) nuevas quedaron pendientes de vincular.` : ''), avisos: r.avisos },
      })
    } catch (e) {
      setError((e as Error).message)
    }
  }

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <div>
        <button onClick={() => navigate(`/sesiones/${s.id}`)} className="mb-1 text-sm text-brand-600 hover:underline">← Volver al detalle</button>
        <h1 className="text-xl font-bold text-gray-800">Editar solicitud</h1>
        <p className="text-sm text-gray-500">
          Docente: {s.docente?.nombre ?? '—'} · Estado: {s.estado}. Cada cambio queda registrado (quién, cuándo y qué había antes).
        </p>
      </div>

      <datalist id="ed-reactivos">{rec?.nombresReactivos.map((n) => <option key={n} value={n} />)}</datalist>
      <datalist id="ed-materiales">{rec?.nombresMateriales.map((n) => <option key={n} value={n} />)}</datalist>

      <div className="space-y-4 rounded-xl border bg-white p-6 shadow-sm">
        <div className="rounded-lg bg-gray-50 p-4">
          <p className="mb-2 text-sm font-medium text-gray-700">Datos del docente</p>
          <div className="grid gap-4 sm:grid-cols-3">
            <div><label className={lbl}>Nombre completo</label><input value={f.doc_nombre} onChange={(e) => set('doc_nombre', e.target.value)} className={css} /></div>
            <div><label className={lbl}>Correo electrónico</label><input value={s.docente?.email ?? ''} readOnly className={`${css} bg-gray-100 text-gray-500`} /></div>
            <div>
              <label className={lbl}>Celular</label>
              <input value={f.doc_celular} onChange={(e) => set('doc_celular', e.target.value)} inputMode="tel" className={css} />
              {celularMal && <p className="mt-1 text-xs text-red-600">Solo números, de 7 a 15 dígitos.</p>}
            </div>
          </div>
          <p className="mt-2 text-xs text-gray-500">Se guardan en el perfil del docente y se verán en todas sus solicitudes. El correo es el de su cuenta y no se cambia aquí.</p>
        </div>
        <div>
          <label className={lbl}>Nombre de la práctica de laboratorio</label>
          <input value={f.practica} onChange={(e) => set('practica', e.target.value)} className={css} />
        </div>
        <div className="grid gap-4 sm:grid-cols-3">
          <div>
            <label className={lbl}>Campus</label>
            <select value={f.campus_id} onChange={(e) => set('campus_id', e.target.value)} className={css}>
              <option value="">Sin campus</option>
              {campus?.map((c) => <option key={c.id} value={c.id}>{c.nombre}</option>)}
            </select>
          </div>
          <div>
            <label className={lbl}>Programa académico</label>
            <input value={f.programa} onChange={(e) => set('programa', e.target.value)} className={css} />
          </div>
          <div>
            <label className={lbl}>Nombre del curso</label>
            <input value={f.curso} onChange={(e) => set('curso', e.target.value)} className={css} />
          </div>
        </div>
        <div className="grid gap-4 sm:grid-cols-4">
          <div><label className={lbl}>Fecha</label><input type="date" value={f.fecha} onChange={(e) => set('fecha', e.target.value)} className={css} /></div>
          <div><label className={lbl}>Hora de inicio</label><input type="time" value={f.inicio} onChange={(e) => set('inicio', e.target.value)} className={css} /></div>
          <div><label className={lbl}>Hora de fin</label><input type="time" value={f.fin} onChange={(e) => set('fin', e.target.value)} className={css} /></div>
          <div><label className={lbl}>Agua destilada (L)</label><input type="number" min="0" step="any" value={f.agua} onChange={(e) => set('agua', e.target.value)} className={css} /></div>
        </div>
        <div className="grid gap-4 sm:grid-cols-3">
          <div><label className={lbl}>Estudiantes</label><input type="number" min="0" value={f.estudiantes} onChange={(e) => set('estudiantes', e.target.value)} className={css} /></div>
          <div><label className={lbl}>Mesas o grupos de trabajo</label><input type="number" min="0" value={f.mesas} onChange={(e) => set('mesas', e.target.value)} className={css} /></div>
          <div>
            <label className={lbl}>Laboratorio</label>
            <select value={f.laboratorio_id} onChange={(e) => set('laboratorio_id', e.target.value)} className={css}>
              <option value="">Por asignar</option>
              {labs?.map((l) => <option key={l.id} value={l.id}>{l.nombre}</option>)}
            </select>
          </div>
        </div>
        <div>
          <label className={lbl}>Observaciones</label>
          <textarea rows={2} value={f.observaciones} onChange={(e) => set('observaciones', e.target.value)} className={css} />
        </div>
      </div>

      <section className="space-y-2">
        <h2 className="text-lg font-semibold text-gray-800">Reactivos</h2>
        <div className="overflow-x-auto rounded-lg border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b bg-gray-50 text-gray-600"><tr>
              <th className="px-2 py-2">Reactivo</th><th className="px-2 py-2">Concentración</th><th className="px-2 py-2">Cantidad</th><th className="px-2 py-2">Unidad</th><th className="px-2 py-2" />
            </tr></thead>
            <tbody>
              {rs.map((l, i) => (
                <tr key={i} className="border-b last:border-0">
                  <td className="min-w-[14rem] px-2 py-1.5">
                    {l.id ? <span className="font-medium">{l.nombre}</span> : (
                      <input list="ed-reactivos" value={l.texto} placeholder="Nuevo reactivo" onChange={(e) => setRs(rs.map((x, j) => j === i ? { ...x, texto: e.target.value } : x))} className={css} />
                    )}
                  </td>
                  <td className="px-2 py-1.5"><input value={l.conc} onChange={(e) => setRs(rs.map((x, j) => j === i ? { ...x, conc: e.target.value } : x))} className={`${css} w-24`} /></td>
                  <td className="px-2 py-1.5"><input type="number" min="0" step="any" value={l.cant} onChange={(e) => setRs(rs.map((x, j) => j === i ? { ...x, cant: e.target.value } : x))} className={`${css} w-24`} /></td>
                  <td className="px-2 py-1.5">
                    <select value={l.unidad} onChange={(e) => setRs(rs.map((x, j) => j === i ? { ...x, unidad: e.target.value } : x))} className={`${css} w-32`}>
                      <option value="">—</option>
                      {[...new Set([...UNIDADES, l.unidad].filter(Boolean))].map((u) => <option key={u} value={u}>{u}</option>)}
                    </select>
                  </td>
                  <td className="px-2 py-1.5 text-right">
                    <button type="button" disabled={l.consumida} title={l.consumida ? 'Ya tiene consumo reportado' : 'Quitar'} onClick={() => setRs(rs.filter((_, j) => j !== i))}
                      className="text-red-600 hover:underline disabled:cursor-not-allowed disabled:text-gray-300">Quitar</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <button type="button" onClick={() => setRs([...rs, { nombre: '', texto: '', conc: '', cant: '', unidad: 'mL', consumida: false }])} className="text-sm text-brand-600 hover:underline">+ Agregar reactivo</button>
      </section>

      <section className="space-y-2">
        <h2 className="text-lg font-semibold text-gray-800">Equipos y vidriería</h2>
        <div className="overflow-x-auto rounded-lg border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b bg-gray-50 text-gray-600"><tr><th className="px-2 py-2">Ítem</th><th className="px-2 py-2">Cantidad</th><th className="px-2 py-2" /></tr></thead>
            <tbody>
              {ms.map((l, i) => (
                <tr key={i} className="border-b last:border-0">
                  <td className="min-w-[14rem] px-2 py-1.5">
                    {l.id ? <span className="font-medium">{l.nombre}</span> : (
                      <input list="ed-materiales" value={l.texto} placeholder="Nuevo ítem" onChange={(e) => setMs(ms.map((x, j) => j === i ? { ...x, texto: e.target.value } : x))} className={css} />
                    )}
                  </td>
                  <td className="px-2 py-1.5"><input type="number" min="0" step="any" value={l.cant} onChange={(e) => setMs(ms.map((x, j) => j === i ? { ...x, cant: e.target.value } : x))} className={`${css} w-24`} /></td>
                  <td className="px-2 py-1.5 text-right">
                    <button type="button" disabled={l.consumida} onClick={() => setMs(ms.filter((_, j) => j !== i))}
                      className="text-red-600 hover:underline disabled:cursor-not-allowed disabled:text-gray-300">Quitar</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <button type="button" onClick={() => setMs([...ms, { nombre: '', texto: '', cant: '', consumida: false }])} className="text-sm text-brand-600 hover:underline">+ Agregar equipo o vidriería</button>
      </section>

      {error && <p className="rounded-md bg-red-50 p-3 text-sm text-red-600">{error}</p>}
      <div className="flex gap-3">
        <button onClick={guardar} disabled={editar.isPending || invalido}
          className="rounded-lg bg-brand-600 px-5 py-2 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">Guardar cambios</button>
        <button onClick={() => navigate(`/sesiones/${s.id}`)} className="text-sm text-gray-500 hover:text-gray-700">Cancelar</button>
      </div>
    </div>
  )
}

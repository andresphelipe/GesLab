import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useCrearSesion, type LineaPayload } from '@/hooks/useSesiones'
import { usePracticas, useCampus, useReconocimiento } from '@/hooks/useCatalogos'
import { normalizar, sinConcentracion } from '@/lib/texto'
import { useAuth } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase'

const CELULAR_OK = /^\+?[0-9 ]{7,15}$/

type Linea = { texto: string; conc: string; total: string; mesa: string; unidad: string }
type Jornada = { fecha: string; inicio: string; fin: string; est: string; mesas: string }

const UNIDADES = ['mL', 'L', 'g', 'kg', 'mg', 'unidad', 'frasco lavador', 'gotero']
const lineaVacia = (): Linea => ({ texto: '', conc: '', total: '', mesa: '', unidad: 'mL' })
const jornadaVacia = (): Jornada => ({ fecha: '', inicio: '', fin: '', est: '', mesas: '' })

const redondear = (n: number) => String(Math.round(n * 100) / 100)
const num = (v: string) => (v.trim() === '' || isNaN(Number(v)) ? null : Number(v))

export default function NuevaSesion() {
  const navigate = useNavigate()
  const crear = useCrearSesion()
  const { data: practicas } = usePracticas()
  const { data: campus } = useCampus()
  const { data: rec } = useReconocimiento()
  const { perfil, recargarPerfil } = useAuth()
  const [nombreDoc, setNombreDoc] = useState('')
  const [celular, setCelular] = useState('')
  const [editandoContacto, setEditandoContacto] = useState(false)
  useEffect(() => {
    if (perfil) {
      setNombreDoc((v) => v || perfil.nombre || '')
      setCelular((v) => v || perfil.celular || '')
    }
  }, [perfil])
  const contactoCompleto = !!perfil?.nombre?.trim() && !!perfil?.celular?.trim()

  const [f, setF] = useState({
    practica: '',
    campus_id: '',
    programa: '',
    curso: '',
    fecha: '',
    inicio: '',
    fin: '',
    estudiantes: '',
    mesas: '',
    agua: '',
    observaciones: '',
  })
  const [otras, setOtras] = useState<Jornada[]>([])
  const [reactivos, setReactivos] = useState<Linea[]>([lineaVacia(), lineaVacia()])
  const [materiales, setMateriales] = useState<Linea[]>([lineaVacia()])
  const [mensaje, setMensaje] = useState<string | null>(null)

  const set = (campo: keyof typeof f, valor: string) => setF((p) => ({ ...p, [campo]: valor }))
  const mesasN = num(f.mesas) ?? 0

  // Sugerencias a partir de lo ya registrado
  const cursos = useMemo(
    () => [...new Set((practicas ?? []).map((p) => p.asignatura).filter(Boolean) as string[])],
    [practicas],
  )
  const programas = useMemo(
    () => [...new Set((practicas ?? []).map((p) => p.programa).filter(Boolean) as string[])],
    [practicas],
  )

  // Totales y cantidad por mesa se mantienen coherentes entre sí
  const editarLinea = (
    tipo: 'r' | 'm',
    i: number,
    campo: keyof Linea,
    valor: string,
  ) => {
    const setter = tipo === 'r' ? setReactivos : setMateriales
    setter((prev) =>
      prev.map((l, idx) => {
        if (idx !== i) return l
        const n = { ...l, [campo]: valor }
        const v = num(valor)
        if (campo === 'total') n.mesa = v !== null && mesasN > 0 ? redondear(v / mesasN) : n.mesa
        if (campo === 'mesa') n.total = v !== null && mesasN > 0 ? redondear(v * mesasN) : n.total
        return n
      }),
    )
  }

  const cambiarMesas = (valor: string) => {
    set('mesas', valor)
    const m = num(valor) ?? 0
    const recalcular = (ls: Linea[]) =>
      ls.map((l) => {
        const t = num(l.total)
        return t !== null && m > 0 ? { ...l, mesa: redondear(t / m) } : l
      })
    setReactivos(recalcular)
    setMateriales(recalcular)
  }

  const estado = (tipo: 'r' | 'm', texto: string) => {
    const n = normalizar(texto)
    if (!n || !rec) return null
    const set = tipo === 'r' ? rec.aliasReactivos : rec.aliasMateriales
    const ok = set.has(n) || (tipo === 'r' && set.has(sinConcentracion(n)))
    return ok ? 'ok' : 'nuevo'
  }

  // Lo mínimo para enviar y para guardar un borrador
  const faltan: string[] = []
  if (!f.practica.trim()) faltan.push('nombre de la práctica de laboratorio')
  if (!f.fecha) faltan.push('fecha')
  if (!f.inicio) faltan.push('hora de inicio')
  if (!f.fin) faltan.push('hora de fin')
  if (f.inicio && f.fin && f.fin <= f.inicio) faltan.push('hora de fin posterior al inicio')
  const faltanEnvio = [...faltan]
  if (!nombreDoc.trim()) faltanEnvio.push('nombre del docente')
  if (!CELULAR_OK.test(celular.trim())) faltanEnvio.push('celular del docente (solo números, 7 a 15 dígitos)')
  if (!f.campus_id) faltanEnvio.push('campus')
  if (!f.programa.trim()) faltanEnvio.push('programa académico')
  if (!f.curso.trim()) faltanEnvio.push('nombre del curso')
  if (num(f.agua) === null || (num(f.agua) ?? 0) < 0) faltanEnvio.push('agua destilada estimada')
  const jornadasIncompletas = otras.some((j) => j.fecha && (!j.inicio || !j.fin || j.fin <= j.inicio))
  if (jornadasIncompletas) faltanEnvio.push('hora de inicio y fin en las otras jornadas')

  const aPayload = (ls: Linea[], conUnidad: boolean): LineaPayload[] =>
    ls
      .filter((l) => l.texto.trim())
      .map((l) => ({
        texto: l.texto.trim(),
        cantidad: num(l.total) ?? undefined,
        cantidad_por_mesa: num(l.total) === null ? num(l.mesa) ?? undefined : undefined,
        unidad: conUnidad ? l.unidad || undefined : undefined,
        concentracion: conUnidad ? l.conc.trim() || undefined : undefined,
      }))

  const guardar = async (estadoSesion: 'borrador' | 'solicitada') => {
    setMensaje(null)
    try {
      // El contacto se guarda una sola vez en el perfil y se reutiliza en las próximas solicitudes
      if (perfil && nombreDoc.trim() && CELULAR_OK.test(celular.trim()) &&
          (nombreDoc.trim() !== (perfil.nombre ?? '') || celular.trim() !== (perfil.celular ?? ''))) {
        const { error: ep } = await supabase.from('perfiles').update({ nombre: nombreDoc.trim(), celular: celular.trim() }).eq('id', perfil.id)
        if (ep) throw ep
        await recargarPerfil()
      }
      const r = await crear.mutateAsync({
        estado: estadoSesion,
        practica_nombre: f.practica.trim(),
        campus_id: f.campus_id || null,
        programa_academico: f.programa.trim(),
        curso: f.curso.trim(),
        agua_destilada_l: num(f.agua),
        fecha: f.fecha,
        inicio: f.inicio,
        fin: f.fin,
        num_estudiantes: num(f.estudiantes),
        num_grupos_trabajo: num(f.mesas),
        observaciones: f.observaciones.trim(),
        otras_jornadas: otras
          .filter((j) => j.fecha)
          .map((j) => ({
            fecha: j.fecha,
            inicio: j.inicio,
            fin: j.fin,
            num_estudiantes: num(j.est),
            num_grupos_trabajo: num(j.mesas),
          })),
        reactivos: aPayload(reactivos, true),
        materiales: aPayload(materiales, false),
      })
      const pend = r.reactivos_pendientes + r.materiales_pendientes
      navigate('/sesiones', {
        state: {
          aviso:
            `${r.sesiones_creadas} sesión${r.sesiones_creadas > 1 ? 'es creadas' : ' creada'}.` +
            (pend ? ` ${pend} línea${pend > 1 ? 's' : ''} quedaron para que el técnico las vincule.` : ''),
        },
      })
    } catch (e) {
      setMensaje((e as Error).message)
    }
  }

  const inputCss =
    'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500'
  const req = <span className="text-red-500"> *</span>
  const lbl = 'mb-1 block text-sm font-medium text-gray-700'

  const tablaLineas = (tipo: 'r' | 'm', ls: Linea[]) => (
    <div className="overflow-x-auto rounded-lg border">
      <table className="w-full text-left text-sm">
        <thead className="border-b bg-gray-50 text-gray-600">
          <tr>
            <th className="px-2 py-2">{tipo === 'r' ? 'Reactivo' : 'Equipo o vidriería'}</th>
            {tipo === 'r' && <th className="px-2 py-2">Concentración</th>}
            <th className="px-2 py-2">Cantidad total</th>
            <th className="px-2 py-2">Cantidad x mesa</th>
            {tipo === 'r' && <th className="px-2 py-2">Unidad</th>}
            <th className="px-2 py-2" />
          </tr>
        </thead>
        <tbody>
          {ls.map((l, i) => {
            const st = estado(tipo, l.texto)
            return (
              <tr key={i} className="border-b last:border-0 align-top">
                <td className="min-w-[14rem] px-2 py-1.5">
                  <input
                    list={tipo === 'r' ? 'sug-reactivos' : 'sug-materiales'}
                    value={l.texto}
                    onChange={(e) => editarLinea(tipo, i, 'texto', e.target.value)}
                    placeholder={tipo === 'r' ? 'Ej.: HCl, NaOH, etanol' : 'Ej.: pipeta graduada'}
                    className={inputCss}
                  />
                  {st === 'ok' && <span className="mt-1 inline-block text-xs text-green-700">Reconocido</span>}
                  {st === 'nuevo' && (
                    <span className="mt-1 inline-block text-xs text-amber-700">Nuevo: lo vincula el técnico</span>
                  )}
                </td>
                {tipo === 'r' && (
                  <td className="px-2 py-1.5">
                    <input
                      value={l.conc}
                      onChange={(e) => editarLinea(tipo, i, 'conc', e.target.value)}
                      placeholder="2 M"
                      className={`${inputCss} w-24`}
                    />
                  </td>
                )}
                <td className="px-2 py-1.5">
                  <input type="number" min="0" step="any" value={l.total}
                    onChange={(e) => editarLinea(tipo, i, 'total', e.target.value)} className={`${inputCss} w-24`} />
                </td>
                <td className="px-2 py-1.5">
                  <input type="number" min="0" step="any" value={l.mesa}
                    onChange={(e) => editarLinea(tipo, i, 'mesa', e.target.value)} className={`${inputCss} w-24`} />
                </td>
                {tipo === 'r' && (
                  <td className="px-2 py-1.5">
                    <select value={l.unidad} onChange={(e) => editarLinea(tipo, i, 'unidad', e.target.value)} className={inputCss}>
                      {UNIDADES.map((u) => <option key={u}>{u}</option>)}
                    </select>
                  </td>
                )}
                <td className="px-2 py-1.5">
                  <button
                    type="button"
                    aria-label="Quitar línea"
                    onClick={() => (tipo === 'r' ? setReactivos : setMateriales)((p) => p.filter((_, k) => k !== i))}
                    className="px-2 text-gray-400 hover:text-red-600"
                  >
                    ✕
                  </button>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <h1 className="text-xl font-bold text-gray-800">Nueva solicitud de práctica</h1>

      <datalist id="sug-practicas">{practicas?.map((p) => <option key={p.id} value={p.nombre} />)}</datalist>
      <datalist id="sug-cursos">{cursos.map((c) => <option key={c} value={c} />)}</datalist>
      <datalist id="sug-programas">{programas.map((c) => <option key={c} value={c} />)}</datalist>
      <datalist id="sug-reactivos">{rec?.nombresReactivos.map((n) => <option key={n} value={n} />)}</datalist>
      <datalist id="sug-materiales">{rec?.nombresMateriales.map((n) => <option key={n} value={n} />)}</datalist>

      <form className="space-y-6 rounded-xl border bg-white p-6 shadow-sm" onSubmit={(e) => e.preventDefault()}>
        <div className="rounded-lg bg-gray-50 p-4">
          <p className="mb-2 text-sm font-medium text-gray-700">Datos del docente</p>
          {contactoCompleto && !editandoContacto ? (
            <div className="flex flex-wrap items-center justify-between gap-2 text-sm text-gray-700">
              <span>{perfil?.nombre} · {perfil?.email} · {perfil?.celular}</span>
              <button type="button" onClick={() => setEditandoContacto(true)} className="text-brand-600 hover:underline">Cambiar</button>
            </div>
          ) : (
            <div className="grid gap-4 sm:grid-cols-3">
              <div>
                <label className={lbl}>Nombre completo{req}</label>
                <input value={nombreDoc} onChange={(e) => setNombreDoc(e.target.value)} className={inputCss} />
              </div>
              <div>
                <label className={lbl}>Correo electrónico</label>
                <input value={perfil?.email ?? ''} readOnly className={`${inputCss} bg-gray-100 text-gray-500`} />
              </div>
              <div>
                <label className={lbl}>Celular{req}</label>
                <input value={celular} onChange={(e) => setCelular(e.target.value)} inputMode="tel" placeholder="3001234567" className={inputCss} />
              </div>
              <p className="text-xs text-gray-500 sm:col-span-3">Se guarda en su perfil: solo lo escribe esta vez.</p>
            </div>
          )}
        </div>

        <div>
          <label className={lbl}>Nombre de la práctica de laboratorio{req}</label>
          <input list="sug-practicas" value={f.practica} onChange={(e) => set('practica', e.target.value)}
            placeholder="Escriba el nombre o elija una práctica anterior" className={inputCss} />
        </div>

        <div className="grid gap-4 sm:grid-cols-3">
          <div>
            <label className={lbl}>Campus{req}</label>
            <select value={f.campus_id} onChange={(e) => set('campus_id', e.target.value)} className={inputCss}>
              <option value="">Seleccionar…</option>
              {campus?.map((c) => <option key={c.id} value={c.id}>{c.nombre}</option>)}
            </select>
          </div>
          <div>
            <label className={lbl}>Programa académico{req}</label>
            <input list="sug-programas" value={f.programa} onChange={(e) => set('programa', e.target.value)} className={inputCss} />
          </div>
          <div>
            <label className={lbl}>Nombre del curso{req}</label>
            <input list="sug-cursos" value={f.curso} onChange={(e) => set('curso', e.target.value)} className={inputCss} />
          </div>
        </div>

        <div className="grid gap-4 sm:grid-cols-3">
          <div>
            <label className={lbl}>Fecha de realización{req}</label>
            <input type="date" value={f.fecha} onChange={(e) => set('fecha', e.target.value)} className={inputCss} />
          </div>
          <div>
            <label className={lbl}>Hora de inicio{req}</label>
            <input type="time" value={f.inicio} onChange={(e) => set('inicio', e.target.value)} className={inputCss} />
          </div>
          <div>
            <label className={lbl}>Hora de fin{req}</label>
            <input type="time" value={f.fin} onChange={(e) => set('fin', e.target.value)} className={inputCss} />
          </div>
        </div>

        {otras.map((j, i) => (
          <div key={i} className="grid items-end gap-3 rounded-lg bg-gray-50 p-3 sm:grid-cols-6">
            <div className="sm:col-span-2">
              <label className={lbl}>Otra jornada: fecha</label>
              <input type="date" value={j.fecha} className={inputCss}
                onChange={(e) => setOtras((p) => p.map((x, k) => (k === i ? { ...x, fecha: e.target.value } : x)))} />
            </div>
            <div>
              <label className={lbl}>Inicio</label>
              <input type="time" value={j.inicio} className={inputCss}
                onChange={(e) => setOtras((p) => p.map((x, k) => (k === i ? { ...x, inicio: e.target.value } : x)))} />
            </div>
            <div>
              <label className={lbl}>Fin</label>
              <input type="time" value={j.fin} className={inputCss}
                onChange={(e) => setOtras((p) => p.map((x, k) => (k === i ? { ...x, fin: e.target.value } : x)))} />
            </div>
            <div>
              <label className={lbl}>Estudiantes</label>
              <input type="number" min="0" value={j.est} className={inputCss}
                onChange={(e) => setOtras((p) => p.map((x, k) => (k === i ? { ...x, est: e.target.value } : x)))} />
            </div>
            <div className="flex gap-2">
              <div className="flex-1">
                <label className={lbl}>Mesas</label>
                <input type="number" min="0" value={j.mesas} placeholder={f.mesas} className={inputCss}
                  onChange={(e) => setOtras((p) => p.map((x, k) => (k === i ? { ...x, mesas: e.target.value } : x)))} />
              </div>
              <button type="button" aria-label="Quitar jornada" className="pb-2 text-gray-400 hover:text-red-600"
                onClick={() => setOtras((p) => p.filter((_, k) => k !== i))}>✕</button>
            </div>
          </div>
        ))}
        <button type="button" onClick={() => setOtras((p) => [...p, jornadaVacia()])}
          className="text-sm font-medium text-brand-700 hover:underline">
          + Añadir otra jornada (por ejemplo, la tarde)
        </button>

        <div className="grid gap-4 sm:grid-cols-3">
          <div>
            <label className={lbl}>Número de estudiantes</label>
            <input type="number" min="0" value={f.estudiantes} onChange={(e) => set('estudiantes', e.target.value)} className={inputCss} />
          </div>
          <div>
            <label className={lbl}>Número de grupos de trabajo (mesas)</label>
            <input type="number" min="0" value={f.mesas} onChange={(e) => cambiarMesas(e.target.value)} className={inputCss} />
          </div>
          <div>
            <label className={lbl}>Agua destilada estimada por sesión (litros){req}</label>
            <input type="number" min="0" step="any" value={f.agua} onChange={(e) => set('agua', e.target.value)} className={inputCss} />
          </div>
        </div>

        <section className="space-y-2">
          <h2 className="text-base font-semibold text-gray-800">Reactivos</h2>
          <p className="text-xs text-gray-500">
            Escriba el nombre como lo conoce (HCl, NaOH, etanol). Si el sistema no lo reconoce, se acepta y el técnico lo
            vincula una sola vez. Escriba la cantidad total o la cantidad por mesa; la otra se calcula con el número de mesas.
          </p>
          {tablaLineas('r', reactivos)}
          <button type="button" onClick={() => setReactivos((p) => [...p, lineaVacia()])}
            className="text-sm font-medium text-brand-700 hover:underline">+ Añadir reactivo</button>
        </section>

        <section className="space-y-2">
          <h2 className="text-base font-semibold text-gray-800">Equipos o vidriería</h2>
          {tablaLineas('m', materiales)}
          <button type="button" onClick={() => setMateriales((p) => [...p, lineaVacia()])}
            className="text-sm font-medium text-brand-700 hover:underline">+ Añadir equipo o vidriería</button>
        </section>

        <div>
          <label className={lbl}>Observaciones</label>
          <textarea rows={3} value={f.observaciones} onChange={(e) => set('observaciones', e.target.value)} className={inputCss} />
        </div>

        <p className="text-xs text-gray-500">
          El laboratorio no se solicita: lo asigna la persona líder de laboratorios o el técnico al aprobar.
        </p>

        {mensaje && <p className="rounded-md bg-red-50 p-2 text-sm text-red-600">{mensaje}</p>}
        {faltanEnvio.length > 0 && (
          <p className="text-xs text-gray-500">Para enviar falta: {faltanEnvio.join(', ')}.</p>
        )}

        <div className="flex flex-wrap gap-3 pt-1">
          <button type="button" onClick={() => guardar('borrador')}
            disabled={crear.isPending || faltan.length > 0}
            className="rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50">
            Guardar borrador
          </button>
          <button type="button" onClick={() => guardar('solicitada')}
            disabled={crear.isPending || faltanEnvio.length > 0}
            className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">
            Enviar solicitud
          </button>
          <button type="button" onClick={() => navigate('/sesiones')}
            className="rounded-lg px-4 py-2 text-sm text-gray-500 hover:text-gray-700">Cancelar</button>
        </div>
      </form>
    </div>
  )
}

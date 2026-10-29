import { useMemo, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/hooks/useAuth'
import { usePerfil } from '@/hooks/usePerfil'
import { leerFormulario, aPayload, type ArchivoLeido } from '@/lib/lectorFormulario'
import type { ResultadoCrear } from '@/hooks/useSesiones'

const CEL = /^\+?[0-9 ]{7,15}$/

interface DocenteOpcion { id: string; nombre: string; email: string; celular: string | null }

function useDocentesElegibles(activo: boolean) {
  return useQuery<DocenteOpcion[]>({
    queryKey: ['docentes-elegibles'],
    enabled: activo,
    staleTime: 1000 * 60 * 5,
    queryFn: async () => {
      const { data, error } = await supabase
        .from('perfiles')
        .select('id, nombre, email, celular')
        .in('rol', ['docente', 'tecnico', 'admin'])
        .eq('activo', true)
        .order('nombre')
        .limit(1000)
      if (error) throw error
      return (data ?? []) as DocenteOpcion[]
    },
  })
}

type Resultado = { hoja: string; ok: boolean; texto: string }

export default function Importar() {
  const { perfil, recargarPerfil } = useAuth()
  const { esPersonal } = usePerfil()
  const qc = useQueryClient()
  const { data: docentes } = useDocentesElegibles(esPersonal)
  const entrada = useRef<HTMLInputElement>(null)

  const [nombreArchivo, setNombreArchivo] = useState('')
  const [lectura, setLectura] = useState<ArchivoLeido | null>(null)
  const [errorLectura, setErrorLectura] = useState<string | null>(null)
  const [elegidas, setElegidas] = useState<Set<string>>(new Set())
  const [docenteId, setDocenteId] = useState('')
  const [duplicadas, setDuplicadas] = useState<Set<string>>(new Set())
  const [importando, setImportando] = useState(false)
  const [resultados, setResultados] = useState<Resultado[] | null>(null)

  const destinoId = esPersonal ? docenteId : perfil?.id ?? ''
  const destino = useMemo(
    () => (esPersonal ? docentes?.find((d) => d.id === docenteId) : perfil ? { id: perfil.id, nombre: perfil.nombre, email: perfil.email, celular: perfil.celular ?? null } : undefined),
    [esPersonal, docentes, docenteId, perfil],
  )

  const cargar = async (file: File) => {
    setErrorLectura(null); setResultados(null); setLectura(null); setDuplicadas(new Set())
    try {
      const r = leerFormulario(await file.arrayBuffer())
      if (r.hojas.length === 0) throw new Error('No se encontró ninguna hoja de práctica con datos. Use el formulario v3 (una hoja por práctica).')
      setNombreArchivo(file.name)
      setLectura(r)
      setElegidas(new Set(r.hojas.filter((h) => h.faltan.length === 0).map((h) => h.hoja)))
      // Cuenta del docente: por correo del archivo (personal) o la propia
      if (esPersonal) {
        const m = docentes?.find((d) => d.email.toLowerCase() === r.docente?.correo)
        setDocenteId(m?.id ?? '')
      }
    } catch (e) {
      setErrorLectura((e as Error).message || 'No se pudo leer el archivo')
    }
  }

  // Posibles duplicados: mismo docente y misma hora de inicio
  const verificarDuplicados = async (id: string, r: ArchivoLeido) => {
    if (!id) return setDuplicadas(new Set())
    const iso = (f: string, h: string) => new Date(`${f}T${h}:00-05:00`).getTime()
    const horas = r.hojas.flatMap((h) => [{ hoja: h.hoja, t: iso(h.fecha, h.inicio) }, ...h.otras_jornadas.map((j) => ({ hoja: h.hoja, t: iso(j.fecha, j.inicio) }))]).filter((x) => !isNaN(x.t))
    if (!horas.length) return
    const { data } = await supabase.from('sesiones_practica').select('inicio').eq('docente_id', id).in('estado', ['borrador', 'solicitada', 'aprobada', 'finalizada']).in('inicio', horas.map((x) => new Date(x.t).toISOString()))
    const existentes = new Set((data ?? []).map((s: any) => new Date(s.inicio).getTime()))
    setDuplicadas(new Set(horas.filter((x) => existentes.has(x.t)).map((x) => x.hoja)))
  }

  const cambiarDocente = (id: string) => {
    setDocenteId(id)
    if (lectura) verificarDuplicados(id, lectura)
  }

  // Verificar duplicados cuando ya hay destino
  useMemo(() => {
    if (lectura && destinoId) verificarDuplicados(destinoId, lectura)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lectura, destinoId])

  const faltaDestino = esPersonal && !docenteId
  const aImportar = lectura?.hojas.filter((h) => elegidas.has(h.hoja)) ?? []

  const importar = async () => {
    if (!lectura || !destino) return
    setImportando(true)
    const out: Resultado[] = []
    // El contacto del archivo completa el perfil solo si está vacío (no pisa lo ya guardado)
    try {
      const d = lectura.docente
      const nombreNuevo = !destino.nombre?.trim() && d?.nombre ? d.nombre : null
      const celNuevo = !destino.celular?.trim() && d?.celular && CEL.test(d.celular) ? d.celular : null
      if (nombreNuevo || celNuevo) {
        if (esPersonal) {
          await supabase.rpc('actualizar_contacto_docente', { p_docente: destino.id, p_nombre: nombreNuevo ?? destino.nombre, p_celular: celNuevo ?? destino.celular })
        } else {
          await supabase.from('perfiles').update({ ...(nombreNuevo ? { nombre: nombreNuevo } : {}), ...(celNuevo ? { celular: celNuevo } : {}) }).eq('id', destino.id)
          await recargarPerfil()
        }
      }
    } catch { /* el contacto es accesorio: no frena la importación */ }

    for (const h of aImportar) {
      try {
        const { data, error } = await supabase.rpc('importar_formulario', {
          p: aPayload(h, { archivo: `${nombreArchivo} · ${h.hoja}`, docente_id: esPersonal ? destino.id : undefined }),
        })
        if (error) throw error
        const r = data as ResultadoCrear
        const pend = r.reactivos_pendientes + r.materiales_pendientes
        out.push({ hoja: h.hoja, ok: true, texto: `${r.sesiones_creadas} sesión${r.sesiones_creadas > 1 ? 'es' : ''} creada${r.sesiones_creadas > 1 ? 's' : ''}${pend ? ` · ${pend} línea${pend > 1 ? 's' : ''} pendientes de vincular` : ''}` })
      } catch (e) {
        out.push({ hoja: h.hoja, ok: false, texto: (e as Error).message })
      }
    }
    setResultados(out)
    setImportando(false)
    for (const k of ['sesiones', 'alertas-tecnico', 'resumen-docente', 'disponibilidad']) qc.invalidateQueries({ queryKey: [k] })
  }

  const alternar = (hoja: string) =>
    setElegidas((p) => { const n = new Set(p); n.has(hoja) ? n.delete(hoja) : n.add(hoja); return n })

  return (
    <div className="mx-auto max-w-4xl space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-800">Importar formulario de Excel</h1>
        <p className="text-sm text-gray-500">Suba el «Formulario de insumos por práctica» (versión 3). Cada hoja de práctica se convierte en una solicitud; revise antes de importar.</p>
      </div>

      <div
        onDragOver={(e) => e.preventDefault()}
        onDrop={(e) => { e.preventDefault(); const f = e.dataTransfer.files[0]; if (f) cargar(f) }}
        className="cursor-pointer rounded-xl border-2 border-dashed border-gray-300 bg-white p-8 text-center hover:border-brand-500"
        onClick={() => entrada.current?.click()}
      >
        <p className="font-medium text-gray-700">{nombreArchivo || 'Arrastre el archivo aquí o haga clic para elegirlo'}</p>
        <p className="text-xs text-gray-400">.xlsx</p>
        <input ref={entrada} type="file" accept=".xlsx" className="hidden" onChange={(e) => { const f = e.target.files?.[0]; if (f) cargar(f); e.target.value = '' }} />
      </div>

      {errorLectura && <p className="rounded-md bg-red-50 p-3 text-sm text-red-600">{errorLectura}</p>}

      {lectura && !resultados && (
        <>
          <div className="space-y-2 rounded-xl border bg-white p-4 shadow-sm">
            <p className="text-sm font-medium text-gray-700">Docente de las solicitudes</p>
            {lectura.docente ? (
              <p className="text-sm text-gray-600">En el archivo: {lectura.docente.nombre || '—'} · {lectura.docente.correo || 'sin correo'} · {lectura.docente.celular || 'sin celular'}</p>
            ) : (
              <p className="text-sm text-amber-700">El archivo no trae la hoja «Docente» con datos (usa el formulario anterior a la v3).</p>
            )}
            {esPersonal ? (
              <div>
                <select value={docenteId} onChange={(e) => cambiarDocente(e.target.value)} className="w-full max-w-md rounded-lg border border-gray-300 px-3 py-2 text-sm">
                  <option value="">Elija el docente de estas solicitudes…</option>
                  {docentes?.map((d) => <option key={d.id} value={d.id}>{d.nombre || d.email} · {d.email}</option>)}
                </select>
                {faltaDestino && lectura.docente?.correo && (
                  <p className="mt-1 text-xs text-amber-700">No hay una cuenta con el correo {lectura.docente.correo}. Elija al docente de la lista (debe haberse registrado en GesLab).</p>
                )}
              </div>
            ) : (
              <p className="text-sm text-gray-600">Las solicitudes quedarán a su nombre ({perfil?.nombre || perfil?.email}).</p>
            )}
          </div>

          <div className="space-y-3">
            {lectura.hojas.map((h) => {
              const bloqueada = h.faltan.length > 0
              return (
                <div key={h.hoja} className={`rounded-xl border bg-white p-4 shadow-sm ${bloqueada ? 'border-red-200' : ''}`}>
                  <label className="flex items-start gap-3">
                    <input type="checkbox" className="mt-1" disabled={bloqueada} checked={elegidas.has(h.hoja)} onChange={() => alternar(h.hoja)} />
                    <div className="flex-1 text-sm">
                      <p className="font-semibold text-gray-800">{h.hoja}: {h.practica_nombre || '(sin nombre)'}</p>
                      <p className="text-gray-600">
                        {h.campus || '—'} · {h.curso || '—'} · {h.fecha || '—'} {h.inicio}–{h.fin}
                        {h.otras_jornadas.length > 0 && ` · +${h.otras_jornadas.length} jornada${h.otras_jornadas.length > 1 ? 's' : ''}`}
                        {` · ${h.reactivos.length} reactivos · ${h.materiales.length} equipos o vidriería`}
                        {h.agua_destilada_l != null && ` · agua ${h.agua_destilada_l} L`}
                      </p>
                      {duplicadas.has(h.hoja) && <p className="mt-1 text-amber-700">⚠ Este docente ya tiene una sesión a esa misma hora: puede ser un duplicado.</p>}
                      {h.faltan.length > 0 && <p className="mt-1 text-red-600">Falta o es inválido: {h.faltan.join('; ')}. Corrija el Excel y vuelva a subirlo.</p>}
                      {h.avisos.length > 0 && <p className="mt-1 text-xs text-gray-500">Avisos: {h.avisos.join('; ')}</p>}
                    </div>
                  </label>
                </div>
              )
            })}
            {lectura.ignoradas.length > 0 && <p className="text-xs text-gray-500">Hojas vacías omitidas: {lectura.ignoradas.join(', ')}.</p>}
          </div>

          <div className="flex items-center gap-3">
            <button onClick={importar} disabled={importando || aImportar.length === 0 || faltaDestino}
              className="rounded-lg bg-brand-600 px-5 py-2 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">
              {importando ? 'Importando…' : `Importar ${aImportar.length} hoja${aImportar.length === 1 ? '' : 's'}`}
            </button>
            {faltaDestino && <span className="text-sm text-amber-700">Elija primero el docente.</span>}
          </div>
        </>
      )}

      {resultados && (
        <div className="space-y-3 rounded-xl border bg-white p-4 shadow-sm">
          <p className="font-semibold text-gray-800">Resultado</p>
          <ul className="space-y-1 text-sm">
            {resultados.map((r) => (
              <li key={r.hoja} className={r.ok ? 'text-green-700' : 'text-red-600'}>{r.ok ? '✓' : '✗'} {r.hoja}: {r.texto}</li>
            ))}
          </ul>
          <div className="flex gap-4 text-sm">
            <Link to="/sesiones" className="font-medium text-brand-600 hover:underline">Ir a las sesiones</Link>
            <button onClick={() => { setLectura(null); setResultados(null); setNombreArchivo('') }} className="text-gray-500 hover:text-gray-700">Importar otro archivo</button>
          </div>
        </div>
      )}
    </div>
  )
}

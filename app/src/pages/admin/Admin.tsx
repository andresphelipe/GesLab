import { useMemo, useState } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { useCampus } from '@/hooks/useCatalogos'
import { useUsuarios, useInvitaciones, useLabsAdmin, useAdminMutaciones, type UsuarioRow } from '@/hooks/useAdmin'
import type { RolUsuario } from '@/lib/types'

const ROLES: { valor: RolUsuario; etiqueta: string }[] = [
  { valor: 'docente', etiqueta: 'Docente' },
  { valor: 'tecnico', etiqueta: 'Técnico' },
  { valor: 'admin', etiqueta: 'Líder de laboratorios (administrador)' },
  { valor: 'estudiante', etiqueta: 'Sin rol asignado (sin acceso)' },
]
const CEL = /^\+?[0-9 ]{7,15}$/
const css = 'rounded-lg border border-gray-300 px-3 py-1.5 text-sm focus:border-brand-500 focus:outline-none'

function Usuarios() {
  const { perfil } = useAuth()
  const { data: usuarios, isLoading, error } = useUsuarios()
  const { data: invitaciones } = useInvitaciones()
  const m = useAdminMutaciones()
  const [q, setQ] = useState('')
  const [soloPendientes, setSoloPendientes] = useState(false)
  const [editando, setEditando] = useState<string | null>(null)
  const [borrador, setBorrador] = useState({ nombre: '', celular: '' })
  const [inv, setInv] = useState({ email: '', nombre: '', rol: 'docente' as RolUsuario })
  const [msg, setMsg] = useState<{ ok: boolean; texto: string } | null>(null)

  const pendientes = (usuarios ?? []).filter((u) => u.rol === 'estudiante' && u.activo).length
  const visibles = useMemo(() => {
    const t = q.trim().toLowerCase()
    return (usuarios ?? []).filter(
      (u) => (!soloPendientes || u.rol === 'estudiante') && (!t || `${u.nombre} ${u.email}`.toLowerCase().includes(t)),
    )
  }, [usuarios, q, soloPendientes])

  const cambiar = async (u: UsuarioRow, cambios: Parameters<typeof m.actualizarUsuario.mutateAsync>[0]['cambios']) => {
    setMsg(null)
    try {
      await m.actualizarUsuario.mutateAsync({ id: u.id, cambios })
    } catch (e) {
      setMsg({ ok: false, texto: (e as Error).message })
    }
  }

  const invitar = async () => {
    setMsg(null)
    try {
      const r = await m.invitar.mutateAsync({ email: inv.email, rol: inv.rol, nombre: inv.nombre })
      setMsg({ ok: true, texto: r === 'actualizado' ? 'La persona ya tenía cuenta: su rol quedó actualizado.' : 'Invitación guardada. Al crear su cuenta recibirá ese rol automáticamente.' })
      setInv({ email: '', nombre: '', rol: 'docente' })
    } catch (e) {
      setMsg({ ok: false, texto: (e as Error).message })
    }
  }

  const guardarContacto = async (u: UsuarioRow) => {
    if (!borrador.nombre.trim()) return setMsg({ ok: false, texto: 'El nombre no puede quedar vacío' })
    if (borrador.celular.trim() && !CEL.test(borrador.celular.trim())) return setMsg({ ok: false, texto: 'Celular: solo números, de 7 a 15 dígitos' })
    await cambiar(u, { nombre: borrador.nombre.trim(), celular: borrador.celular.trim() || null })
    setEditando(null)
  }

  return (
    <div className="space-y-5">
      {pendientes > 0 && (
        <div className="rounded-lg border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
          {pendientes} persona{pendientes > 1 ? 's' : ''} con cuenta y sin rol asignado.{' '}
          <button onClick={() => setSoloPendientes(true)} className="font-medium underline">Verlas</button>
        </div>
      )}

      <div className="space-y-3 rounded-xl border bg-white p-4 shadow-sm">
        <p className="text-sm font-medium text-gray-700">Asignar rol por correo</p>
        <p className="text-xs text-gray-500">
          Si la persona ya tiene cuenta, se le cambia el rol. Si aún no, queda registrada y recibe el rol cuando usted cree su cuenta en Supabase (Authentication → Add user).
        </p>
        <div className="flex flex-wrap gap-3">
          <input value={inv.email} onChange={(e) => setInv({ ...inv, email: e.target.value })} placeholder="correo@udea.edu.co" className={`${css} w-64`} />
          <input value={inv.nombre} onChange={(e) => setInv({ ...inv, nombre: e.target.value })} placeholder="Nombre (opcional)" className={`${css} w-56`} />
          <select value={inv.rol} onChange={(e) => setInv({ ...inv, rol: e.target.value as RolUsuario })} className={css}>
            {ROLES.filter((r) => r.valor !== 'estudiante').map((r) => <option key={r.valor} value={r.valor}>{r.etiqueta}</option>)}
          </select>
          <button onClick={invitar} disabled={!inv.email.trim() || m.invitar.isPending} className="rounded-lg bg-brand-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">Guardar</button>
        </div>
        {invitaciones && invitaciones.length > 0 && (
          <ul className="space-y-1 border-t pt-2 text-sm text-gray-600">
            {invitaciones.map((i) => (
              <li key={i.id} className="flex items-center justify-between gap-3">
                <span>{i.email} · {ROLES.find((r) => r.valor === i.rol)?.etiqueta} · esperando que cree su cuenta</span>
                <button onClick={() => m.quitarInvitacion.mutate(i.id)} className="text-red-600 hover:underline">Quitar</button>
              </li>
            ))}
          </ul>
        )}
      </div>

      {msg && <p className={`rounded-md p-2 text-sm ${msg.ok ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>{msg.texto}</p>}

      <div className="flex flex-wrap items-center gap-3">
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Buscar por nombre o correo…" className={`${css} w-64`} />
        <label className="flex items-center gap-2 text-sm text-gray-700">
          <input type="checkbox" checked={soloPendientes} onChange={(e) => setSoloPendientes(e.target.checked)} /> Solo sin rol asignado
        </label>
      </div>

      {error && <p className="text-sm text-red-600">{(error as Error).message}</p>}
      {isLoading ? <p className="text-gray-500">Cargando…</p> : (
        <div className="overflow-x-auto rounded-lg border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b bg-gray-50 text-gray-600"><tr>
              <th className="px-3 py-2">Persona</th><th className="px-3 py-2">Celular</th><th className="px-3 py-2">Rol</th><th className="px-3 py-2">Estado</th><th className="px-3 py-2" />
            </tr></thead>
            <tbody>
              {visibles.map((u) => {
                const yo = u.id === perfil?.id
                return (
                  <tr key={u.id} className={`border-b last:border-0 ${!u.activo ? 'bg-gray-50 text-gray-400' : u.rol === 'estudiante' ? 'bg-yellow-50' : ''}`}>
                    <td className="px-3 py-2">
                      {editando === u.id ? (
                        <input value={borrador.nombre} onChange={(e) => setBorrador({ ...borrador, nombre: e.target.value })} className={`${css} w-56`} />
                      ) : <span className="font-medium">{u.nombre || '(sin nombre)'}{yo && ' (usted)'}</span>}
                      <div className="text-xs text-gray-500">{u.email}</div>
                    </td>
                    <td className="px-3 py-2">
                      {editando === u.id ? <input value={borrador.celular} onChange={(e) => setBorrador({ ...borrador, celular: e.target.value })} className={`${css} w-36`} /> : (u.celular ?? '—')}
                    </td>
                    <td className="px-3 py-2">
                      <select value={u.rol} disabled={yo} onChange={(e) => cambiar(u, { rol: e.target.value as RolUsuario })} className={css} title={yo ? 'No puede cambiar su propio rol' : ''}>
                        {ROLES.map((r) => <option key={r.valor} value={r.valor}>{r.etiqueta}</option>)}
                      </select>
                    </td>
                    <td className="px-3 py-2">
                      <button disabled={yo} onClick={() => cambiar(u, { activo: !u.activo })} className={`rounded-full px-3 py-0.5 text-xs font-medium disabled:opacity-40 ${u.activo ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}>
                        {u.activo ? 'Activo' : 'Inactivo'}
                      </button>
                    </td>
                    <td className="px-3 py-2 text-right">
                      {editando === u.id ? (
                        <>
                          <button onClick={() => guardarContacto(u)} className="mr-3 text-brand-600 hover:underline">Guardar</button>
                          <button onClick={() => setEditando(null)} className="text-gray-500 hover:underline">Cancelar</button>
                        </>
                      ) : (
                        <button onClick={() => { setEditando(u.id); setBorrador({ nombre: u.nombre, celular: u.celular ?? '' }) }} className="text-brand-600 hover:underline">Editar datos</button>
                      )}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
          {visibles.length === 0 && <p className="p-4 text-sm text-gray-500">No hay personas con ese filtro.</p>}
        </div>
      )}
    </div>
  )
}

function Laboratorios() {
  const { data: campus } = useCampus()
  const { data: labs, isLoading } = useLabsAdmin()
  const m = useAdminMutaciones()
  const [nuevo, setNuevo] = useState({ campus_id: '', numero: '', capacidad: '', ubicacion: '' })
  const [msg, setMsg] = useState<{ ok: boolean; texto: string } | null>(null)
  const [verInactivos, setVerInactivos] = useState(false)

  const crear = async () => {
    setMsg(null)
    const c = campus?.find((x) => x.id === nuevo.campus_id)
    if (!c || !nuevo.numero.trim()) return setMsg({ ok: false, texto: 'Elija la sede y escriba el número o nombre del laboratorio' })
    try {
      await m.crearLab.mutateAsync({
        nombre: `${c.nombre} · ${nuevo.numero.trim()}`,
        campus_id: c.id,
        capacidad: nuevo.capacidad.trim() === '' ? null : Number(nuevo.capacidad),
        ubicacion: nuevo.ubicacion.trim() || null,
      })
      setNuevo({ campus_id: nuevo.campus_id, numero: '', capacidad: '', ubicacion: '' })
      setMsg({ ok: true, texto: 'Laboratorio creado.' })
    } catch (e) {
      const t = (e as Error).message
      setMsg({ ok: false, texto: t.includes('duplicate') ? 'Ya existe un laboratorio con ese nombre en esa sede.' : t })
    }
  }

  const editar = async (id: string, cambios: Parameters<typeof m.actualizarLab.mutateAsync>[0]['cambios']) => {
    setMsg(null)
    try { await m.actualizarLab.mutateAsync({ id, cambios }) } catch (e) { setMsg({ ok: false, texto: (e as Error).message }) }
  }

  return (
    <div className="space-y-5">
      <div className="space-y-3 rounded-xl border bg-white p-4 shadow-sm">
        <p className="text-sm font-medium text-gray-700">Agregar laboratorio</p>
        <div className="flex flex-wrap gap-3">
          <select value={nuevo.campus_id} onChange={(e) => setNuevo({ ...nuevo, campus_id: e.target.value })} className={css}>
            <option value="">Sede…</option>
            {campus?.map((c) => <option key={c.id} value={c.id}>{c.nombre}</option>)}
          </select>
          <input value={nuevo.numero} onChange={(e) => setNuevo({ ...nuevo, numero: e.target.value })} placeholder="Número (p. ej. 106)" className={`${css} w-40`} />
          <input type="number" min="0" value={nuevo.capacidad} onChange={(e) => setNuevo({ ...nuevo, capacidad: e.target.value })} placeholder="Capacidad" className={`${css} w-28`} />
          <input value={nuevo.ubicacion} onChange={(e) => setNuevo({ ...nuevo, ubicacion: e.target.value })} placeholder="Ubicación (opcional)" className={`${css} w-56`} />
          <button onClick={crear} disabled={m.crearLab.isPending} className="rounded-lg bg-brand-600 px-4 py-1.5 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">Agregar</button>
        </div>
        <p className="text-xs text-gray-500">El nombre queda como «Sede · número», igual que los salones del inventario.</p>
      </div>

      {msg && <p className={`rounded-md p-2 text-sm ${msg.ok ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>{msg.texto}</p>}
      <label className="flex items-center gap-2 text-sm text-gray-700"><input type="checkbox" checked={verInactivos} onChange={(e) => setVerInactivos(e.target.checked)} /> Mostrar inactivos</label>

      {isLoading ? <p className="text-gray-500">Cargando…</p> : (
        <>
          {[...(campus ?? []), { id: '', nombre: 'Sin sede asignada', orden: 99 }].map((c) => {
            const ls = (labs ?? []).filter((l) => (l.campus_id ?? '') === c.id && (verInactivos || l.activo))
            if (ls.length === 0) return null
            return (
              <div key={c.id || 'sin'}>
                <h3 className="mb-1 font-semibold text-gray-800">{c.nombre}</h3>
                <div className="overflow-x-auto rounded-lg border bg-white">
                  <table className="w-full text-left text-sm">
                    <thead className="border-b bg-gray-50 text-gray-600"><tr>
                      <th className="px-3 py-2">Laboratorio</th><th className="px-3 py-2">Capacidad</th><th className="px-3 py-2">Ubicación</th><th className="px-3 py-2">Sede</th><th className="px-3 py-2">Estado</th>
                    </tr></thead>
                    <tbody>
                      {ls.map((l) => (
                        <tr key={l.id} className={`border-b last:border-0 ${!l.activo ? 'bg-gray-50 text-gray-400' : ''}`}>
                          <td className="px-3 py-1.5">
                            <input defaultValue={l.nombre} onBlur={(e) => e.target.value.trim() && e.target.value.trim() !== l.nombre && editar(l.id, { nombre: e.target.value.trim() })} className={`${css} w-48`} />
                          </td>
                          <td className="px-3 py-1.5">
                            <input type="number" min="0" defaultValue={l.capacidad ?? ''} onBlur={(e) => { const v = e.target.value === '' ? null : Number(e.target.value); if (v !== l.capacidad) editar(l.id, { capacidad: v }) }} className={`${css} w-24`} />
                          </td>
                          <td className="px-3 py-1.5">
                            <input defaultValue={l.ubicacion ?? ''} onBlur={(e) => { const v = e.target.value.trim() || null; if (v !== l.ubicacion) editar(l.id, { ubicacion: v }) }} className={`${css} w-52`} />
                          </td>
                          <td className="px-3 py-1.5">
                            <select value={l.campus_id ?? ''} onChange={(e) => editar(l.id, { campus_id: e.target.value || null })} className={css}>
                              <option value="">—</option>
                              {campus?.map((x) => <option key={x.id} value={x.id}>{x.nombre}</option>)}
                            </select>
                          </td>
                          <td className="px-3 py-1.5">
                            <button onClick={() => editar(l.id, { activo: !l.activo })} className={`rounded-full px-3 py-0.5 text-xs font-medium ${l.activo ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'}`}>{l.activo ? 'Activo' : 'Inactivo'}</button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )
          })}
        </>
      )}
    </div>
  )
}

export default function Admin() {
  const [pestana, setPestana] = useState<'usuarios' | 'labs'>('usuarios')
  const tab = (p: 'usuarios' | 'labs', t: string) => (
    <button onClick={() => setPestana(p)} className={`rounded-lg px-4 py-1.5 text-sm font-medium ${pestana === p ? 'bg-brand-600 text-white' : 'border bg-white text-gray-600 hover:bg-gray-50'}`}>{t}</button>
  )
  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-xl font-bold text-gray-800">Administración</h1>
      <div className="flex gap-2">{tab('usuarios', 'Usuarios')}{tab('labs', 'Laboratorios')}</div>
      {pestana === 'usuarios' ? <Usuarios /> : <Laboratorios />}
    </div>
  )
}

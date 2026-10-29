import { useEffect, useState, type FormEvent } from 'react'
import { useAuth } from '@/hooks/useAuth'
import { supabase } from '@/lib/supabase'

const CEL = /^\+?[0-9 ]{7,15}$/

export default function Cuenta() {
  const { perfil, recargarPerfil, cambiarClave } = useAuth()
  const [nombre, setNombre] = useState('')
  const [celular, setCelular] = useState('')
  const [clave, setClave] = useState('')
  const [confirmar, setConfirmar] = useState('')
  const [m1, setM1] = useState<{ ok: boolean; t: string } | null>(null)
  const [m2, setM2] = useState<{ ok: boolean; t: string } | null>(null)

  useEffect(() => {
    if (perfil) { setNombre(perfil.nombre ?? ''); setCelular(perfil.celular ?? '') }
  }, [perfil])

  const guardarDatos = async (e: FormEvent) => {
    e.preventDefault(); setM1(null)
    if (!nombre.trim()) return setM1({ ok: false, t: 'El nombre no puede quedar vacío.' })
    if (celular.trim() && !CEL.test(celular.trim())) return setM1({ ok: false, t: 'Celular: solo números, de 7 a 15 dígitos.' })
    const { error } = await supabase.from('perfiles').update({ nombre: nombre.trim(), celular: celular.trim() || null }).eq('id', perfil!.id)
    if (error) return setM1({ ok: false, t: error.message })
    await recargarPerfil(); setM1({ ok: true, t: 'Datos guardados.' })
  }

  const guardarClave = async (e: FormEvent) => {
    e.preventDefault(); setM2(null)
    if (clave.length < 8) return setM2({ ok: false, t: 'La contraseña debe tener al menos 8 caracteres.' })
    if (clave !== confirmar) return setM2({ ok: false, t: 'Las contraseñas no coinciden.' })
    const err = await cambiarClave(clave)
    if (err) return setM2({ ok: false, t: err })
    setClave(''); setConfirmar(''); setM2({ ok: true, t: 'Contraseña actualizada.' })
  }

  const css = 'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none'
  const lbl = 'mb-1 block text-sm font-medium text-gray-700'
  const aviso = (m: { ok: boolean; t: string } | null) => m && <p className={`rounded-md p-2 text-sm ${m.ok ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>{m.t}</p>

  return (
    <div className="mx-auto max-w-xl space-y-6">
      <h1 className="text-xl font-bold text-gray-800">Mi cuenta</h1>
      <form onSubmit={guardarDatos} className="space-y-4 rounded-xl border bg-white p-5 shadow-sm">
        <p className="font-semibold text-gray-800">Mis datos</p>
        <div><label className={lbl}>Nombre completo</label><input value={nombre} onChange={(e) => setNombre(e.target.value)} className={css} /></div>
        <div><label className={lbl}>Correo electrónico</label><input value={perfil?.email ?? ''} readOnly className={`${css} bg-gray-100 text-gray-500`} /></div>
        <div><label className={lbl}>Celular</label><input value={celular} onChange={(e) => setCelular(e.target.value)} inputMode="tel" className={css} /></div>
        {aviso(m1)}
        <button className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700">Guardar datos</button>
      </form>
      <form onSubmit={guardarClave} className="space-y-4 rounded-xl border bg-white p-5 shadow-sm">
        <p className="font-semibold text-gray-800">Cambiar contraseña</p>
        <div><label className={lbl}>Nueva contraseña</label><input type="password" value={clave} onChange={(e) => setClave(e.target.value)} className={css} autoComplete="new-password" /></div>
        <div><label className={lbl}>Repita la contraseña</label><input type="password" value={confirmar} onChange={(e) => setConfirmar(e.target.value)} className={css} autoComplete="new-password" /></div>
        {aviso(m2)}
        <button className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700">Cambiar contraseña</button>
      </form>
    </div>
  )
}

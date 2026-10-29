import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'

/** Destino del enlace «Olvidé mi contraseña»: Supabase abre una sesión temporal y aquí se fija la nueva clave. */
export default function Restablecer() {
  const { session, cargando, cambiarClave } = useAuth()
  const navigate = useNavigate()
  const [clave, setClave] = useState('')
  const [confirmar, setConfirmar] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [enviando, setEnviando] = useState(false)
  const [hecho, setHecho] = useState(false)

  const enviar = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    if (clave.length < 8) return setError('La contraseña debe tener al menos 8 caracteres.')
    if (clave !== confirmar) return setError('Las contraseñas no coinciden.')
    setEnviando(true)
    const err = await cambiarClave(clave)
    setEnviando(false)
    if (err) setError(err)
    else { setHecho(true); setTimeout(() => navigate('/', { replace: true }), 1500) }
  }

  const css = 'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500'

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-50 to-brand-100 px-4">
      <div className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-lg">
        <div className="mb-6 text-center">
          <span className="text-4xl">🧪</span>
          <h1 className="mt-2 text-2xl font-bold text-brand-900">GesLab</h1>
          <p className="text-sm text-gray-500">Nueva contraseña</p>
        </div>
        {cargando ? (
          <p className="text-center text-sm text-gray-500">Verificando enlace…</p>
        ) : !session ? (
          <div className="space-y-3 text-center text-sm text-gray-600">
            <p>El enlace no es válido o ya venció. Pida uno nuevo desde «Olvidé mi contraseña».</p>
            <Link to="/login" className="font-medium text-brand-600 hover:underline">Ir a ingresar</Link>
          </div>
        ) : hecho ? (
          <p className="rounded-md bg-green-50 p-3 text-center text-sm text-green-800">Contraseña actualizada. Entrando…</p>
        ) : (
          <form onSubmit={enviar} className="space-y-4">
            <div>
              <label htmlFor="c1" className="mb-1 block text-sm font-medium text-gray-700">Nueva contraseña</label>
              <input id="c1" type="password" required minLength={8} value={clave} onChange={(e) => setClave(e.target.value)} className={css} autoComplete="new-password" />
              <p className="mt-1 text-xs text-gray-500">Mínimo 8 caracteres.</p>
            </div>
            <div>
              <label htmlFor="c2" className="mb-1 block text-sm font-medium text-gray-700">Repita la contraseña</label>
              <input id="c2" type="password" required value={confirmar} onChange={(e) => setConfirmar(e.target.value)} className={css} autoComplete="new-password" />
            </div>
            {error && <p className="rounded-md bg-red-50 p-2 text-sm text-red-600">{error}</p>}
            <button type="submit" disabled={enviando} className="w-full rounded-lg bg-brand-600 py-2 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">
              {enviando ? 'Guardando…' : 'Guardar contraseña'}
            </button>
          </form>
        )}
      </div>
    </div>
  )
}

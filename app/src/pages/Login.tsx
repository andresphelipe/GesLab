import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth, esCorreoInstitucional } from '@/hooks/useAuth'

type Modo = 'entrar' | 'crear' | 'olvide'

// Recuperar la contraseña por correo solo funciona si Supabase envía correos (SMTP propio)
const RECUPERA_POR_CORREO = import.meta.env.VITE_RECUPERACION_POR_CORREO === 'true'

export default function Login() {
  const { session, cargando, error, iniciarSesion, registrar, recuperarClave } = useAuth()
  const [modo, setModo] = useState<Modo>('entrar')
  const [nombre, setNombre] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmar, setConfirmar] = useState('')
  const [enviando, setEnviando] = useState(false)
  const [local, setLocal] = useState<string | null>(null)
  const [listo, setListo] = useState<string | null>(null)

  if (cargando) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-brand-600 border-t-transparent" />
      </div>
    )
  }

  if (session) return <Navigate to="/" replace />

  const cambiar = (m: Modo) => { setModo(m); setLocal(null); setListo(null); setPassword(''); setConfirmar('') }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setLocal(null)
    setEnviando(true)
    try {
      if (modo === 'entrar') {
        await iniciarSesion(email, password)
      } else if (modo === 'crear') {
        if (!esCorreoInstitucional(email)) return setLocal('Solo se permiten correos institucionales @udea.edu.co.')
        if (nombre.trim().split(/\s+/).length < 2) return setLocal('Escriba su nombre y apellido.')
        if (password.length < 8) return setLocal('La contraseña debe tener al menos 8 caracteres.')
        if (password !== confirmar) return setLocal('Las contraseñas no coinciden.')
        const { error: err, confirmar: porCorreo } = await registrar(nombre, email, password)
        if (err) setLocal(err)
        else if (porCorreo) setListo(`Le enviamos un mensaje a ${email.trim().toLowerCase()}. Abra el enlace para activar su cuenta y luego ingrese. Si no lo ve, revise la carpeta de correo no deseado.`)
        // sin confirmación por correo: la sesión ya está abierta y se redirige sola
      } else {
        if (!esCorreoInstitucional(email)) return setLocal('Escriba su correo institucional @udea.edu.co.')
        const err = await recuperarClave(email)
        if (err) setLocal(err)
        else setListo('Si el correo tiene una cuenta, le enviamos un enlace para crear una nueva contraseña. Revise también el correo no deseado.')
      }
    } finally {
      setEnviando(false)
    }
  }

  const css = 'w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500'
  const lbl = 'mb-1 block text-sm font-medium text-gray-700'
  const titulo = modo === 'entrar' ? 'Ingresar' : modo === 'crear' ? 'Crear cuenta' : 'Recuperar contraseña'
  const mensaje = local ?? (modo === 'entrar' ? error : null)

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-50 to-brand-100 px-4">
      <div className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-lg">
        <div className="mb-6 text-center">
          <span className="text-4xl">🧪</span>
          <h1 className="mt-2 text-2xl font-bold text-brand-900">GesLab</h1>
          <p className="text-sm text-gray-500">Gestión de Laboratorios · {titulo}</p>
        </div>

        {listo ? (
          <div className="space-y-4">
            <p className="rounded-md bg-green-50 p-3 text-sm text-green-800">{listo}</p>
            <button onClick={() => cambiar('entrar')} className="w-full rounded-lg border border-gray-300 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
              Volver a ingresar
            </button>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            {modo === 'crear' && (
              <div>
                <label htmlFor="nombre" className={lbl}>Nombre completo</label>
                <input id="nombre" required value={nombre} onChange={(e) => setNombre(e.target.value)} className={css} autoComplete="name" />
              </div>
            )}
            <div>
              <label htmlFor="email" className={lbl}>Correo institucional</label>
              <input id="email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} className={css} placeholder="usuario@udea.edu.co" autoComplete="email" />
            </div>
            {modo !== 'olvide' && (
              <div>
                <label htmlFor="password" className={lbl}>Contraseña</label>
                <input id="password" type="password" required value={password} onChange={(e) => setPassword(e.target.value)} className={css}
                  autoComplete={modo === 'crear' ? 'new-password' : 'current-password'} minLength={modo === 'crear' ? 8 : undefined} />
                {modo === 'crear' && <p className="mt-1 text-xs text-gray-500">Mínimo 8 caracteres.</p>}
              </div>
            )}
            {modo === 'crear' && (
              <div>
                <label htmlFor="confirmar" className={lbl}>Repita la contraseña</label>
                <input id="confirmar" type="password" required value={confirmar} onChange={(e) => setConfirmar(e.target.value)} className={css} autoComplete="new-password" />
              </div>
            )}

            {mensaje && <p className="rounded-md bg-red-50 p-2 text-sm text-red-600">{mensaje}</p>}

            <button type="submit" disabled={enviando} className="w-full rounded-lg bg-brand-600 py-2 text-sm font-medium text-white hover:bg-brand-700 disabled:opacity-50">
              {enviando ? 'Procesando…' : modo === 'entrar' ? 'Ingresar' : modo === 'crear' ? 'Crear cuenta' : 'Enviar enlace'}
            </button>

            <div className="flex flex-col items-center gap-1 text-sm">
              {modo === 'entrar' && (
                <>
                  {RECUPERA_POR_CORREO ? (
                    <button type="button" onClick={() => cambiar('olvide')} className="text-brand-600 hover:underline">Olvidé mi contraseña</button>
                  ) : (
                    <span className="text-xs text-gray-500">¿Olvidó su contraseña? Solicítela al administrador.</span>
                  )}
                  <button type="button" onClick={() => cambiar('crear')} className="text-brand-600 hover:underline">Crear cuenta</button>
                </>
              )}
              {modo !== 'entrar' && (
                <button type="button" onClick={() => cambiar('entrar')} className="text-brand-600 hover:underline">← Volver a ingresar</button>
              )}
            </div>
          </form>
        )}
      </div>
    </div>
  )
}

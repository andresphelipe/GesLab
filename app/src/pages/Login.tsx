import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { FlaskConical } from 'lucide-react'
import { useAuth, esCorreoInstitucional } from '@/hooks/useAuth'
import { Button, Field, Input, Spinner } from '@/components/ui'

type Modo = 'entrar' | 'crear' | 'olvide'
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
      <div className="flex h-screen items-center justify-center bg-bg">
        <Spinner className="h-6 w-6 text-fg-muted" />
      </div>
    )
  }
  if (session) return <Navigate to="/" replace />

  const cambiar = (m: Modo) => { setModo(m); setLocal(null); setListo(null); setPassword(''); setConfirmar('') }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setLocal(null); setEnviando(true)
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
        else if (porCorreo) setListo(`Le enviamos un mensaje a ${email.trim().toLowerCase()}. Abra el enlace para activar su cuenta.`)
      } else {
        if (!esCorreoInstitucional(email)) return setLocal('Escriba su correo institucional @udea.edu.co.')
        const err = await recuperarClave(email)
        if (err) setLocal(err)
        else setListo('Si el correo tiene una cuenta registrada, le enviamos un enlace para restablecer la contraseña.')
      }
    } finally { setEnviando(false) }
  }

  const titulo = modo === 'entrar' ? 'Ingresar' : modo === 'crear' ? 'Crear cuenta' : 'Recuperar contraseña'
  const mensaje = local ?? (modo === 'entrar' ? error : null)

  return (
    <div className="relative flex min-h-screen items-center justify-center bg-bg px-4">
      {/* Fondo sutil con gradiente radial */}
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,var(--surface),transparent_60%)]" />

      <div className="relative w-full max-w-sm">
        <div className="mb-6 flex flex-col items-center text-center">
          <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-accent text-accent-fg shadow-md">
            <FlaskConical size={22} />
          </span>
          <h1 className="mt-3 text-2xl font-semibold tracking-tight">GesLab</h1>
          <p className="mt-0.5 text-xs text-fg-muted">Gestión de laboratorios docentes · UdeA Urabá</p>
        </div>

        <div className="rounded-xl border border-border bg-surface p-6 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-base font-semibold">{titulo}</h2>
            {modo !== 'entrar' && !listo && (
              <button onClick={() => cambiar('entrar')} className="text-xs text-fg-muted hover:text-fg">← Volver</button>
            )}
          </div>

          {listo ? (
            <div className="space-y-3">
              <p className="rounded-md border border-ok bg-ok-soft px-3 py-2 text-sm text-ok">{listo}</p>
              <Button className="w-full" onClick={() => cambiar('entrar')}>Volver a ingresar</Button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-3">
              {modo === 'crear' && (
                <Field label="Nombre completo">
                  <Input id="nombre" required value={nombre} onChange={(e) => setNombre(e.target.value)} autoComplete="name" />
                </Field>
              )}
              <Field label="Correo institucional">
                <Input id="email" type="email" required value={email} onChange={(e) => setEmail(e.target.value)}
                  placeholder="usuario@udea.edu.co" autoComplete="email" />
              </Field>
              {modo !== 'olvide' && (
                <Field label="Contraseña" hint={modo === 'crear' ? 'mín. 8 caracteres' : undefined}>
                  <Input id="password" type="password" required value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    autoComplete={modo === 'crear' ? 'new-password' : 'current-password'}
                    minLength={modo === 'crear' ? 8 : undefined} />
                </Field>
              )}
              {modo === 'crear' && (
                <Field label="Repita la contraseña">
                  <Input id="confirmar" type="password" required value={confirmar} onChange={(e) => setConfirmar(e.target.value)} autoComplete="new-password" />
                </Field>
              )}

              {mensaje && <p className="rounded-md border border-danger bg-danger-soft px-3 py-2 text-sm text-danger">{mensaje}</p>}

              <Button type="submit" variant="primary" className="w-full" disabled={enviando}>
                {enviando && <Spinner />}
                {enviando ? 'Procesando…' : modo === 'entrar' ? 'Ingresar' : modo === 'crear' ? 'Crear cuenta' : 'Enviar enlace'}
              </Button>

              {modo === 'entrar' && (
                <div className="flex items-center justify-between pt-1 text-xs">
                  {RECUPERA_POR_CORREO ? (
                    <button type="button" onClick={() => cambiar('olvide')} className="text-fg-muted hover:text-fg">¿Olvidó la contraseña?</button>
                  ) : (
                    <span className="text-fg-faint">¿Olvidó la contraseña? Pídala al administrador.</span>
                  )}
                  <button type="button" onClick={() => cambiar('crear')} className="text-fg-muted hover:text-fg">Crear cuenta</button>
                </div>
              )}
            </form>
          )}
        </div>

        <p className="mt-4 text-center text-xs text-fg-faint">
          Solo correos @udea.edu.co · UdeA sede Urabá
        </p>
      </div>
    </div>
  )
}

import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  type ReactNode,
} from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'
import type { Perfil } from '@/lib/types'

interface AuthState {
  session: Session | null
  user: User | null
  perfil: Perfil | null
  cargando: boolean
  error: string | null
  iniciarSesion: (email: string, password: string) => Promise<void>
  cerrarSesion: () => Promise<void>
  recargarPerfil: () => Promise<void>
  registrar: (nombre: string, email: string, password: string) => Promise<{ error: string | null; confirmar: boolean }>
  recuperarClave: (email: string) => Promise<string | null>
  cambiarClave: (password: string) => Promise<string | null>
}

/** Mensajes de la autenticación en español. */
export function traducirError(msg: string): string {
  const m = msg.toLowerCase()
  if (m.includes('invalid login credentials')) return 'Correo o contraseña incorrectos.'
  if (m.includes('email not confirmed')) return 'Aún no ha activado su cuenta. Revise su correo y abra el enlace de activación.'
  if (m.includes('rate limit') || m.includes('too many') || m.includes('security purposes')) return 'Demasiados intentos. Espere unos minutos e inténtelo de nuevo.'
  if (m.includes('database error saving new user') || m.includes('correos institucionales'))
    return 'Solo se permiten correos institucionales @udea.edu.co.'
  if (m.includes('password should be at least')) return 'La contraseña debe tener al menos 8 caracteres.'
  if (m.includes('same password') || m.includes('different from the old')) return 'La nueva contraseña debe ser distinta de la anterior.'
  if (m.includes('already registered')) return 'Ese correo ya tiene una cuenta. Use «Olvidé mi contraseña» si no la recuerda.'
  if (m.includes('failed to fetch') || m.includes('network')) return 'No hay conexión con el servidor. Revise su internet.'
  return msg
}

export const esCorreoInstitucional = (correo: string) => /@([a-z0-9-]+\.)*udea\.edu\.co$/i.test(correo.trim())

const AuthContext = createContext<AuthState | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null)
  const [perfil, setPerfil] = useState<Perfil | null>(null)
  const [cargando, setCargando] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const cargarPerfil = useCallback(async (userId: string) => {
    const { data, error: err } = await supabase
      .from('perfiles')
      .select('*')
      .eq('id', userId)
      .single()

    if (err) {
      console.error('Error cargando perfil:', err.message)
      setError('No se pudo cargar el perfil de usuario.')
      setPerfil(null)
    } else {
      setPerfil(data as Perfil)
      setError(null)
    }
  }, [])

  useEffect(() => {
    // Sesión actual
    supabase.auth.getSession().then(({ data: { session: s } }) => {
      setSession(s)
      if (s?.user) cargarPerfil(s.user.id).finally(() => setCargando(false))
      else setCargando(false)
    })

    // Escuchar cambios
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s)
      if (s?.user) {
        cargarPerfil(s.user.id)
      } else {
        setPerfil(null)
      }
    })

    return () => subscription.unsubscribe()
  }, [cargarPerfil])

  const iniciarSesion = async (email: string, password: string) => {
    setError(null)
    const { error: err } = await supabase.auth.signInWithPassword({
      email,
      password,
    })
    if (err) setError(traducirError(err.message))
  }

  /** Devuelve un mensaje de error en español, o null si todo salió bien. */
  const registrar = async (nombre: string, email: string, password: string) => {
    if (!esCorreoInstitucional(email)) return { error: 'Solo se permiten correos institucionales @udea.edu.co.', confirmar: false }
    const { data, error: err } = await supabase.auth.signUp({
      email: email.trim().toLowerCase(),
      password,
      options: { data: { full_name: nombre.trim() }, emailRedirectTo: window.location.origin + '/' },
    })
    if (err) return { error: traducirError(err.message), confirmar: false }
    // Con «Confirm email» apagado, Supabase devuelve la sesión y la persona entra de una vez
    return { error: null, confirmar: !data.session }
  }

  const recuperarClave = async (email: string) => {
    const { error: err } = await supabase.auth.resetPasswordForEmail(email.trim().toLowerCase(), {
      redirectTo: window.location.origin + '/restablecer',
    })
    return err ? traducirError(err.message) : null
  }

  const cambiarClave = async (password: string) => {
    const { error: err } = await supabase.auth.updateUser({ password })
    return err ? traducirError(err.message) : null
  }

  const cerrarSesion = async () => {
    await supabase.auth.signOut()
    setPerfil(null)
  }

  const recargarPerfil = async () => {
    if (session?.user) await cargarPerfil(session.user.id)
  }

  return (
    <AuthContext.Provider
      value={{
        session,
        user: session?.user ?? null,
        perfil,
        cargando,
        error,
        iniciarSesion,
        cerrarSesion,
        recargarPerfil,
        registrar,
        recuperarClave,
        cambiarClave,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth debe usarse dentro de <AuthProvider>')
  return ctx
}

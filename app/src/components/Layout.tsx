import { useState } from 'react'
import { Link, Outlet, useLocation } from 'react-router-dom'
import {
  Home, ClipboardList, FlaskConical, Upload, Calendar,
  AlertTriangle, BarChart3, Settings, Menu, X, Sun, Moon, Monitor,
  LogOut, User, ChevronDown,
} from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { usePerfil } from '@/hooks/usePerfil'
import { useTema } from '@/hooks/useTema'
import clsx from 'clsx'

const NAV = [
  { to: '/',            label: 'Inicio',       Icon: Home,           roles: null },
  { to: '/sesiones',    label: 'Sesiones',     Icon: ClipboardList,  roles: null },
  { to: '/inventario',  label: 'Inventario',   Icon: FlaskConical,   roles: ['tecnico','admin'] as const },
  { to: '/importar',    label: 'Importar',     Icon: Upload,         roles: ['docente','tecnico','admin'] as const },
  { to: '/reservas',    label: 'Reservas',     Icon: Calendar,       roles: null },
  { to: '/incidencias', label: 'Incidencias',  Icon: AlertTriangle,  roles: null },
  { to: '/informes',    label: 'Informes',     Icon: BarChart3,      roles: ['tecnico','admin'] as const },
  { to: '/admin',       label: 'Admin',        Icon: Settings,       roles: ['admin'] as const },
]

const ROL_LABEL: Record<string, string> = {
  estudiante: 'Pendiente',
  docente: 'Docente',
  tecnico: 'Técnico',
  admin: 'Administrador',
}

export default function Layout() {
  const { cerrarSesion } = useAuth()
  const { perfil, tieneRol } = usePerfil()
  const { pathname } = useLocation()
  const [open, setOpen] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

  const items = NAV.filter((it) => !it.roles || it.roles.some((r) => tieneRol(r)))
  const current =
    pathname === '/cuenta'
      ? 'Mi cuenta'
      : items.find((i) => i.to === pathname || (i.to !== '/' && pathname.startsWith(i.to + '/')))?.label ?? 'GesLab'

  return (
    <div className="flex h-screen bg-bg text-fg">
      <Sidebar items={items} pathname={pathname} open={open} onClose={() => setOpen(false)} />

      <div className="flex flex-1 flex-col overflow-hidden">
        <header className="flex h-12 items-center gap-3 border-b border-border bg-surface px-3 lg:px-5">
          <button
            onClick={() => setOpen(true)}
            className="rounded p-1.5 text-fg-muted hover:bg-muted lg:hidden"
            aria-label="Abrir menú"
          ><Menu size={18} /></button>
          <h1 className="text-sm font-semibold">{current}</h1>
          <div className="ml-auto flex items-center gap-1">
            <ThemeToggle />
            <UserMenu
              open={menuOpen} setOpen={setMenuOpen}
              nombre={perfil?.nombre ?? ''}
              rol={perfil ? ROL_LABEL[perfil.rol] : ''}
              onLogout={cerrarSesion}
            />
          </div>
        </header>
        <div className="strip-udea" />

        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          {perfil?.rol === 'estudiante' ? <CuentaPendiente /> : <Outlet />}
        </main>
      </div>
    </div>
  )
}

function Sidebar({ items, pathname, open, onClose }: {
  items: typeof NAV; pathname: string; open: boolean; onClose: () => void
}) {
  return (
    <>
      {open && <div className="fixed inset-0 z-30 bg-black/50 lg:hidden" onClick={onClose} />}
      <aside
        className={clsx(
          'sidebar-udea fixed inset-y-0 left-0 z-40 flex w-[232px] flex-col border-r transition-transform lg:static lg:translate-x-0',
          open ? 'translate-x-0' : '-translate-x-full',
        )}>
        <div className="sidebar-brand flex h-12 items-center justify-between px-4">
          <Link to="/" className="flex items-center gap-2 font-semibold tracking-tight" onClick={onClose}>
            <span className="flex h-6 w-6 items-center justify-center rounded bg-[color:var(--sidebar-accent)] text-[color:var(--sidebar-bg)] text-xs font-bold">G</span>
            <span style={{ color: 'var(--sidebar-fg)' }}>GesLab</span>
          </Link>
          <button
            onClick={onClose}
            className="rounded p-1 hover:bg-black/20 lg:hidden"
            style={{ color: 'var(--sidebar-fg-muted)' }}
            aria-label="Cerrar menú"
          ><X size={16} /></button>
        </div>

        <nav className="flex-1 overflow-y-auto px-2 py-3">
          <div className="mb-2 px-2 text-[10px] font-semibold uppercase tracking-wider"
            style={{ color: 'var(--sidebar-fg-faint)' }}>Navegación</div>
          <ul className="space-y-0.5">
            {items.map(({ to, label, Icon }) => {
              const active = to === '/' ? pathname === '/' : pathname === to || pathname.startsWith(to + '/')
              return (
                <li key={to}>
                  <Link
                    to={to}
                    onClick={onClose}
                    className={clsx(
                      'sidebar-link relative flex items-center gap-2.5 rounded-md pl-3 pr-2 py-1.5 text-sm transition-colors',
                      active && 'active',
                    )}>
                    <Icon size={15} />
                    {label}
                  </Link>
                </li>
              )
            })}
          </ul>
        </nav>

        <div className="sidebar-footer px-3 py-2.5 text-[11px] leading-tight">
          <div style={{ color: 'var(--sidebar-fg-muted)' }} className="font-medium">Universidad de Antioquia</div>
          <div>Sede Urabá · Turbo · Apartadó · Carepa</div>
        </div>
      </aside>
    </>
  )
}

function ThemeToggle() {
  const { tema, setTema } = useTema()
  return (
    <div className="hidden items-center gap-0.5 rounded-md border border-border p-0.5 sm:flex">
      {(['light','auto','dark'] as const).map((t) => {
        const Icon = t === 'light' ? Sun : t === 'dark' ? Moon : Monitor
        const active = tema === t
        return (
          <button
            key={t} onClick={() => setTema(t)}
            className={clsx(
              'rounded p-1 transition-colors',
              active ? 'bg-muted text-fg' : 'text-fg-faint hover:text-fg',
            )}
            aria-label={t === 'light' ? 'Tema claro' : t === 'dark' ? 'Tema oscuro' : 'Tema automático'}
            aria-pressed={active}
          ><Icon size={14} /></button>
        )
      })}
    </div>
  )
}

function UserMenu({ open, setOpen, nombre, rol, onLogout }: {
  open: boolean; setOpen: (v: boolean) => void; nombre: string; rol: string; onLogout: () => void
}) {
  const iniciales = (nombre || '?').split(' ').map(s => s[0]).slice(0, 2).join('').toUpperCase()
  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 rounded-md border border-border bg-surface px-2 py-1 text-sm hover:bg-muted"
      >
        <span className="flex h-6 w-6 items-center justify-center rounded-full bg-accent text-accent-fg text-xs font-semibold">{iniciales}</span>
        <span className="hidden text-left sm:block">
          <span className="block max-w-[140px] truncate text-xs font-medium leading-tight">{nombre}</span>
          <span className="block text-[10px] uppercase tracking-wide text-fg-faint">{rol}</span>
        </span>
        <ChevronDown size={14} className="text-fg-faint" />
      </button>
      {open && (
        <>
          <div className="fixed inset-0 z-30" onClick={() => setOpen(false)} />
          <div className="absolute right-0 z-40 mt-1 w-52 overflow-hidden rounded-lg border border-border bg-surface shadow-lg">
            <div className="border-b border-border px-3 py-2">
              <div className="truncate text-sm font-medium">{nombre}</div>
              <div className="text-xs text-fg-muted">{rol}</div>
            </div>
            <Link
              to="/cuenta"
              onClick={() => setOpen(false)}
              className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-muted"
            ><User size={14} className="text-fg-faint" /> Mi cuenta</Link>
            <button
              onClick={() => { setOpen(false); onLogout() }}
              className="flex w-full items-center gap-2 border-t border-border px-3 py-2 text-left text-sm text-danger hover:bg-muted"
            ><LogOut size={14} /> Cerrar sesión</button>
          </div>
        </>
      )}
    </div>
  )
}

function CuentaPendiente() {
  return (
    <div className="mx-auto mt-16 max-w-md rounded-xl border border-border bg-surface p-6 text-center shadow-sm">
      <div className="mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-full bg-warn-soft text-warn">
        <AlertTriangle size={18} />
      </div>
      <p className="text-lg font-semibold">Cuenta pendiente de activación</p>
      <p className="mt-2 text-sm text-fg-muted">
        Un administrador debe asignarle un rol (docente o técnico). Cuando lo haga, cierre sesión y vuelva a entrar.
      </p>
    </div>
  )
}

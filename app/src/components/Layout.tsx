import { useState } from 'react'
import { Link, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '@/hooks/useAuth'
import { usePerfil } from '@/hooks/usePerfil'

const NAV_ITEMS = [
  { to: '/',            label: 'Inicio',        icon: '🏠', roles: null },
  { to: '/sesiones',    label: 'Sesiones',      icon: '📋', roles: null },
  { to: '/inventario',  label: 'Inventario',    icon: '🧪', roles: ['tecnico','admin'] as const },
  { to: '/importar',    label: 'Importar',      icon: '📥', roles: ['docente','tecnico','admin'] as const },
  { to: '/reservas',    label: 'Reservas',      icon: '📅', roles: null },
  { to: '/incidencias', label: 'Incidencias',   icon: '⚠️', roles: null },
  { to: '/informes',    label: 'Informes',      icon: '📊', roles: ['tecnico','admin'] as const },
  { to: '/admin',       label: 'Admin',         icon: '⚙️', roles: ['admin'] as const },
]

export default function Layout() {
  const { cerrarSesion } = useAuth()
  const { perfil, tieneRol } = usePerfil()
  const { pathname } = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const items = NAV_ITEMS.filter(
    (it) => !it.roles || it.roles.some((r) => tieneRol(r))
  )

  const rolLabel: Record<string, string> = {
    estudiante: 'Estudiante',
    docente: 'Docente',
    tecnico: 'Técnico',
    admin: 'Administrador',
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside
        className={`
          fixed inset-y-0 left-0 z-30 w-60 transform bg-brand-900 text-white
          transition-transform lg:static lg:translate-x-0
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
        `}
      >
        <div className="flex h-14 items-center gap-2 px-4 font-semibold text-lg">
          <span>🧪</span> GesLab
        </div>

        <nav className="mt-2 flex flex-col gap-1 px-2">
          {items.map((it) => (
            <Link
              key={it.to}
              to={it.to}
              onClick={() => setSidebarOpen(false)}
              className={`
                flex items-center gap-3 rounded-md px-3 py-2 text-sm
                transition-colors
                ${
                  pathname === it.to
                    ? 'bg-brand-700 text-white'
                    : 'text-brand-200 hover:bg-brand-800 hover:text-white'
                }
              `}
            >
              <span>{it.icon}</span>
              {it.label}
            </Link>
          ))}
        </nav>

        <div className="absolute bottom-0 w-full border-t border-brand-700 p-4">
          <p className="truncate text-sm font-medium">{perfil?.nombre}</p>
          <p className="text-xs text-brand-300">
            {perfil ? rolLabel[perfil.rol] : ''}
          </p>
          <Link to="/cuenta" onClick={() => setSidebarOpen(false)} className="mt-1 block text-xs text-brand-300 hover:text-white">Mi cuenta</Link>
          <button
            onClick={cerrarSesion}
            className="mt-2 text-xs text-brand-300 hover:text-white"
          >
            Cerrar sesión
          </button>
        </div>
      </aside>

      {/* Overlay móvil */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-20 bg-black/40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Contenido */}
      <div className="flex flex-1 flex-col overflow-hidden">
        <header className="flex h-14 items-center gap-4 border-b bg-white px-4 shadow-sm lg:px-6">
          <button
            className="text-gray-600 lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            ☰
          </button>
          <h1 className="text-lg font-semibold text-gray-800">
            {pathname === '/cuenta' ? 'Mi cuenta' : items.find((i) => i.to === pathname || (i.to !== '/' && pathname.startsWith(i.to + '/')))?.label ?? 'GesLab'}
          </h1>
        </header>

        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          {perfil?.rol === 'estudiante' ? (
            <div className="mx-auto mt-16 max-w-md rounded-xl border bg-white p-6 text-center shadow-sm">
              <p className="text-lg font-semibold text-gray-800">Su cuenta está pendiente de activación</p>
              <p className="mt-2 text-sm text-gray-600">Un administrador debe asignarle un rol (docente o técnico). Cuando lo haga, cierre sesión y vuelva a entrar.</p>
            </div>
          ) : (
            <Outlet />
          )}
        </main>
      </div>
    </div>
  )
}

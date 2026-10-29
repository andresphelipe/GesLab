import { Routes, Route } from 'react-router-dom'
import Layout from '@/components/Layout'
import ProtectedRoute from '@/components/ProtectedRoute'
import RoleGuard from '@/components/RoleGuard'
import Login from '@/pages/Login'
import Cuenta from '@/pages/Cuenta'
import Restablecer from '@/pages/Restablecer'
import Dashboard from '@/pages/Dashboard'
import ListaSesiones from '@/pages/sesiones/Lista'
import NuevaSesion from '@/pages/sesiones/Nueva'
import DetalleSesion from '@/pages/sesiones/Detalle'
import EditarSesion from '@/pages/sesiones/Editar'
import Admin from '@/pages/admin/Admin'
import Importar from '@/pages/importar/Importar'
import Informes from '@/pages/informes/Informes'
import Inventario from '@/pages/inventario/Inventario'

// Placeholders — se implementan en las siguientes fases
function Placeholder({ nombre }: { nombre: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-gray-400">
      <span className="text-5xl mb-4">🚧</span>
      <p className="text-lg font-medium">{nombre}</p>
      <p className="text-sm">Próximamente</p>
    </div>
  )
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/restablecer" element={<Restablecer />} />

      <Route
        element={
          <ProtectedRoute>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Dashboard />} />
        <Route path="cuenta" element={<Cuenta />} />

        {/* Sesiones */}
        <Route path="sesiones" element={<ListaSesiones />} />
        <Route path="sesiones/nueva" element={<NuevaSesion />} />
        <Route path="sesiones/:id" element={<DetalleSesion />} />
        <Route path="sesiones/:id/editar" element={
          <RoleGuard roles={['tecnico', 'admin']}>
            <EditarSesion />
          </RoleGuard>
        } />

        <Route path="inventario" element={
          <RoleGuard roles={['tecnico', 'admin']}>
            <Inventario />
          </RoleGuard>
        } />

        <Route path="importar" element={
          <RoleGuard roles={['docente', 'tecnico', 'admin']}>
            <Importar />
          </RoleGuard>
        } />

        <Route path="reservas" element={<Placeholder nombre="Reservas de laboratorio" />} />
        <Route path="incidencias" element={<Placeholder nombre="Incidencias" />} />

        <Route path="informes" element={<RoleGuard roles={['tecnico','admin']}><Informes /></RoleGuard>} />

        <Route path="admin/*" element={
          <RoleGuard roles={['admin']}>
            <Admin />
          </RoleGuard>
        } />
      </Route>

      {/* 404 */}
      <Route path="*" element={
        <div className="flex h-screen items-center justify-center">
          <p className="text-gray-500">Página no encontrada</p>
        </div>
      } />
    </Routes>
  )
}

import { usePerfil } from '@/hooks/usePerfil'
import { useAlertasTecnico, useResumenDocente } from '@/hooks/useAlertas'
import { format, parseISO } from 'date-fns'
import { es } from 'date-fns/locale'

function formatFecha(iso: string) {
  try {
    return format(parseISO(iso), "d MMM yyyy, HH:mm", { locale: es })
  } catch {
    return iso
  }
}

function formatDia(iso: string) {
  try {
    return format(parseISO(iso), "d MMM yyyy", { locale: es })
  } catch {
    return iso
  }
}

/* ─── Tarjeta genérica ─── */
function Card({
  titulo,
  valor,
  icono,
  color = 'blue',
}: {
  titulo: string
  valor: number | string
  icono: string
  color?: string
}) {
  const colores: Record<string, string> = {
    blue:   'bg-blue-50 text-blue-700',
    amber:  'bg-amber-50 text-amber-700',
    red:    'bg-red-50 text-red-700',
    green:  'bg-green-50 text-green-700',
    purple: 'bg-purple-50 text-purple-700',
  }
  return (
    <div className="rounded-xl border bg-white p-4 shadow-sm">
      <div className="flex items-center gap-3">
        <span className={`rounded-lg p-2 text-xl ${colores[color] ?? colores.blue}`}>
          {icono}
        </span>
        <div>
          <p className="text-2xl font-bold text-gray-800">{valor}</p>
          <p className="text-sm text-gray-500">{titulo}</p>
        </div>
      </div>
    </div>
  )
}

/* ─── Vista del técnico ─── */
function DashboardTecnico() {
  const { data, isLoading, error } = useAlertasTecnico()

  if (isLoading)
    return <p className="text-gray-500">Cargando alertas…</p>
  if (error)
    return <p className="text-red-500">Error al cargar alertas: {(error as Error).message}</p>
  if (!data) return null

  return (
    <div className="space-y-6">
      {/* Tarjetas resumen */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Card titulo="Sesiones por aprobar" valor={data.sesiones_pendientes?.length ?? 0} icono="📋" color="amber" />
        <Card titulo="Reactivos bajo mínimo" valor={data.stock_bajo_minimo?.length ?? 0} icono="🧪" color="red" />
        <Card titulo="Próximos a vencer" valor={data.proximos_a_vencer?.length ?? 0} icono="⏰" color="amber" />
        <Card titulo="Líneas sin vincular" valor={data.lineas_sin_vincular ?? 0} icono="🔗" color="purple" />
      </div>

      {/* Sesiones pendientes */}
      {(data.sesiones_pendientes?.length ?? 0) > 0 && (
        <section>
          <h2 className="mb-3 text-lg font-semibold text-gray-800">
            Sesiones pendientes de aprobación
          </h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600">
                <tr>
                  <th className="px-4 py-2">Práctica</th>
                  <th className="px-4 py-2">Docente</th>
                  <th className="px-4 py-2">Laboratorio</th>
                  <th className="px-4 py-2">Inicio</th>
                  <th className="px-4 py-2">Estudiantes</th>
                </tr>
              </thead>
              <tbody>
                {data.sesiones_pendientes.map((s) => (
                  <tr key={s.id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-2 font-medium">{s.practica ?? '—'}</td>
                    <td className="px-4 py-2">{s.docente}</td>
                    <td className="px-4 py-2">{s.laboratorio ?? <span className="text-gray-400">Por asignar</span>}</td>
                    <td className="px-4 py-2">{formatFecha(s.inicio)}</td>
                    <td className="px-4 py-2 text-center">{s.num_estudiantes ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* Reactivos bajo mínimo */}
      {(data.stock_bajo_minimo?.length ?? 0) > 0 && (
        <section>
          <h2 className="mb-3 text-lg font-semibold text-gray-800">
            Reactivos bajo stock mínimo
          </h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600">
                <tr>
                  <th className="px-4 py-2">Reactivo</th>
                  <th className="px-4 py-2">CAS</th>
                  <th className="px-4 py-2 text-right">Stock</th>
                  <th className="px-4 py-2 text-right">Mínimo</th>
                  <th className="px-4 py-2">Unidad</th>
                </tr>
              </thead>
              <tbody>
                {data.stock_bajo_minimo.map((r) => (
                  <tr key={r.reactivo_id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-2 font-medium">{r.nombre}</td>
                    <td className="px-4 py-2 font-mono text-xs">{r.cas ?? '—'}</td>
                    <td className="px-4 py-2 text-right text-red-600 font-semibold">{r.stock_total}</td>
                    <td className="px-4 py-2 text-right">{r.stock_minimo}</td>
                    <td className="px-4 py-2">{r.unidad}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {/* Próximos a vencer */}
      {(data.proximos_a_vencer?.length ?? 0) > 0 && (
        <section>
          <h2 className="mb-3 text-lg font-semibold text-gray-800">
            Envases próximos a vencer (30 días)
          </h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600">
                <tr>
                  <th className="px-4 py-2">Código</th>
                  <th className="px-4 py-2">Reactivo</th>
                  <th className="px-4 py-2">Lote</th>
                  <th className="px-4 py-2 text-right">Cantidad</th>
                  <th className="px-4 py-2">Vence</th>
                  <th className="px-4 py-2 text-right">Días</th>
                </tr>
              </thead>
              <tbody>
                {data.proximos_a_vencer.map((e) => (
                  <tr key={e.envase_id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-2 font-mono text-xs">{e.codigo}</td>
                    <td className="px-4 py-2 font-medium">{e.reactivo}</td>
                    <td className="px-4 py-2">{e.lote ?? '—'}</td>
                    <td className="px-4 py-2 text-right">{e.cantidad_actual} {e.unidad}</td>
                    <td className="px-4 py-2">{formatDia(e.fecha_caducidad)}</td>
                    <td className={`px-4 py-2 text-right font-semibold ${
                      e.dias_restantes <= 7 ? 'text-red-600' : 'text-amber-600'
                    }`}>
                      {e.dias_restantes}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  )
}

/* ─── Vista del docente ─── */
function DashboardDocente() {
  const { data, isLoading, error } = useResumenDocente()

  if (isLoading) return <p className="text-gray-500">Cargando resumen…</p>
  if (error) return <p className="text-red-500">Error: {(error as Error).message}</p>
  if (!data) return null

  return (
    <div className="space-y-6">
      <div className="grid gap-4 sm:grid-cols-3">
        <Card titulo="Próximas 7 días" valor={data.proximas_7_dias} icono="📅" color="blue" />
        <Card titulo="Mis prácticas" valor={data.mis_practicas} icono="🔬" color="green" />
        <Card titulo="Mis grupos" valor={data.mis_grupos} icono="👥" color="purple" />
      </div>

      {data.sesiones_activas.length > 0 && (
        <section>
          <h2 className="mb-3 text-lg font-semibold text-gray-800">
            Sesiones activas
          </h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b bg-gray-50 text-gray-600">
                <tr>
                  <th className="px-4 py-2">Práctica</th>
                  <th className="px-4 py-2">Laboratorio</th>
                  <th className="px-4 py-2">Inicio</th>
                  <th className="px-4 py-2">Estado</th>
                </tr>
              </thead>
              <tbody>
                {data.sesiones_activas.map((s) => (
                  <tr key={s.id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-2 font-medium">{s.practica ?? '—'}</td>
                    <td className="px-4 py-2">{s.laboratorio ?? <span className="text-gray-400">Por asignar</span>}</td>
                    <td className="px-4 py-2">{formatFecha(s.inicio)}</td>
                    <td className="px-4 py-2">
                      <span className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium ${
                        s.estado === 'aprobada' ? 'bg-green-100 text-green-700'
                        : s.estado === 'solicitada' ? 'bg-amber-100 text-amber-700'
                        : 'bg-gray-100 text-gray-600'
                      }`}>
                        {s.estado}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  )
}

/* ─── Componente principal ─── */
export default function Dashboard() {
  const { perfil } = usePerfil()

  if (!perfil) return null

  const saludo = `Hola, ${perfil.nombre.split(' ')[0]}`

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-800">{saludo}</h1>

      {(perfil.rol === 'tecnico' || perfil.rol === 'admin') && <DashboardTecnico />}
      {perfil.rol === 'docente' && <DashboardDocente />}
      {perfil.rol === 'estudiante' && (
        <p className="text-gray-500">
          Bienvenido a GesLab. Puedes consultar las sesiones de laboratorio asignadas a tus grupos.
        </p>
      )}
    </div>
  )
}

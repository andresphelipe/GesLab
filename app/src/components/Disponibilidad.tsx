import type { LineaDisponibilidad } from '@/hooks/useInventario'

const ETIQ: Record<LineaDisponibilidad['estado'], { t: string; c: string }> = {
  ok: { t: 'Hay', c: 'bg-green-100 text-green-700' },
  ok_traslado: { t: 'Hay, con traslado', c: 'bg-amber-100 text-amber-800' },
  falta: { t: 'Falta', c: 'bg-red-100 text-red-700' },
  sin_cantidad: { t: 'Sin cantidad', c: 'bg-gray-100 text-gray-600' },
  sin_unidad: { t: 'Unidad no comparable', c: 'bg-gray-100 text-gray-600' },
  sin_campus: { t: 'Sin campus', c: 'bg-gray-100 text-gray-600' },
}

export function EtiquetaDisp({ estado }: { estado: LineaDisponibilidad['estado'] }) {
  const e = ETIQ[estado]
  return <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${e.c}`}>{e.t}</span>
}

const TIPO = { reactivo: 'Reactivo', equipo: 'Equipo', vidrieria: 'Vidriería' }

export function TablaDisponibilidad({ lineas }: { lineas: LineaDisponibilidad[] }) {
  if (lineas.length === 0) return <p className="text-sm text-gray-500">Esta sesión no tiene líneas vinculadas al catálogo.</p>
  const orden = { falta: 0, ok_traslado: 1, sin_unidad: 2, sin_cantidad: 3, sin_campus: 4, ok: 5 } as const
  const ls = [...lineas].sort((a, b) => orden[a.estado] - orden[b.estado])
  return (
    <div className="overflow-x-auto rounded-lg border bg-white">
      <table className="w-full text-left text-sm">
        <thead className="border-b bg-gray-50 text-gray-600">
          <tr>
            <th className="px-3 py-2">Ítem</th>
            <th className="px-3 py-2">Tipo</th>
            <th className="px-3 py-2 text-right">Pedido</th>
            <th className="px-3 py-2 text-right">Libre en la sede</th>
            <th className="px-3 py-2">Estado</th>
            <th className="px-3 py-2">Detalle</th>
          </tr>
        </thead>
        <tbody>
          {ls.map((l, i) => (
            <tr key={i} className="border-b last:border-0">
              <td className="px-3 py-1.5 font-medium">{l.item}</td>
              <td className="px-3 py-1.5 text-gray-500">{TIPO[l.tipo]}</td>
              <td className="px-3 py-1.5 text-right">{l.solicitado != null ? `${Number(l.solicitado.toFixed(2))} ${l.unidad ?? ''}` : '—'}</td>
              <td className="px-3 py-1.5 text-right">{l.disponible != null ? Number(Math.max(l.disponible, 0).toFixed(2)) : '—'}</td>
              <td className="px-3 py-1.5"><EtiquetaDisp estado={l.estado} /></td>
              <td className="px-3 py-1.5 text-xs text-gray-600">{l.mensaje ?? ''}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

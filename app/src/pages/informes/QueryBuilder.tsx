import { useMemo, useState } from 'react'
import { Download, Play, Plus, Save, Trash2, X } from 'lucide-react'
import * as XLSX from 'xlsx'
import {
  Dimension, Filtro, Metrica, Operador, SpecInforme,
  formatearMetrica, useDimensiones, useDominios, useEjecutarInforme,
  useFavoritos, useGuardarFavorito, useMetricas, useBorrarFavorito,
} from '@/hooks/useInformesDinamicos'
import { Badge, Button, Card, Empty, Field, Input, PageHeader, Select, Spinner, Table } from '@/components/ui'

const OPERADORES: { v: Operador; l: string; valor: 'uno' | 'lista' | 'rango' | 'nada' }[] = [
  { v: 'eq', l: 'igual a', valor: 'uno' },
  { v: 'ne', l: 'distinto de', valor: 'uno' },
  { v: 'lt', l: 'menor que', valor: 'uno' },
  { v: 'lte', l: 'menor o igual', valor: 'uno' },
  { v: 'gt', l: 'mayor que', valor: 'uno' },
  { v: 'gte', l: 'mayor o igual', valor: 'uno' },
  { v: 'in', l: 'en lista', valor: 'lista' },
  { v: 'not_in', l: 'no en lista', valor: 'lista' },
  { v: 'between', l: 'entre', valor: 'rango' },
  { v: 'contains', l: 'contiene', valor: 'uno' },
  { v: 'starts_with', l: 'empieza con', valor: 'uno' },
  { v: 'ends_with', l: 'termina con', valor: 'uno' },
  { v: 'is_null', l: 'está vacío', valor: 'nada' },
  { v: 'is_not_null', l: 'no está vacío', valor: 'nada' },
]

export default function QueryBuilder() {
  const { data: dominios } = useDominios()
  const [dominio, setDominio] = useState<string>('')
  const { data: dimensiones } = useDimensiones(dominio || null)
  const { data: metricas } = useMetricas(dominio || null)
  const favoritos = useFavoritos()
  const ejecutar = useEjecutarInforme()
  const guardar = useGuardarFavorito()
  const borrarFav = useBorrarFavorito()

  const [dimensionesSel, setDimensionesSel] = useState<string[]>([])
  const [metricasSel,    setMetricasSel]    = useState<string[]>([])
  const [filtros,        setFiltros]        = useState<Filtro[]>([])
  const [ordenCampo,     setOrdenCampo]     = useState<string>('')
  const [ordenDir,       setOrdenDir]       = useState<'asc' | 'desc'>('desc')
  const [limite,         setLimite]         = useState<number>(500)
  const [mostrarGuardar, setMostrarGuardar] = useState(false)
  const [nombreFav,      setNombreFav]      = useState('')

  const camposMap = useMemo(() => {
    const m = new Map<string, Dimension | Metrica>()
    for (const d of dimensiones ?? []) m.set(d.id, d)
    for (const x of metricas ?? [])    m.set(x.id, x)
    return m
  }, [dimensiones, metricas])

  const spec: SpecInforme = {
    dominio,
    dimensiones: dimensionesSel,
    metricas:    metricasSel,
    filtros:     filtros.filter(f => f.campo),
    orden:       ordenCampo ? [{ campo: ordenCampo, dir: ordenDir }] : [],
    limite,
  }

  const correr = () => {
    if (!dominio || (dimensionesSel.length === 0 && metricasSel.length === 0)) return
    ejecutar.mutate(spec)
  }

  const cargarFavorito = (f: SpecInforme) => {
    setDominio(f.dominio)
    setDimensionesSel(f.dimensiones)
    setMetricasSel(f.metricas)
    setFiltros(f.filtros)
    setOrdenCampo(f.orden?.[0]?.campo ?? '')
    setOrdenDir(f.orden?.[0]?.dir ?? 'desc')
    setLimite(f.limite ?? 500)
    setTimeout(() => ejecutar.mutate(f), 50)
  }

  const guardarFavorito = () => {
    if (!nombreFav.trim() || !dominio) return
    guardar.mutate(
      { nombre: nombreFav.trim(), dominio_id: dominio, spec },
      {
        onSuccess: () => {
          setMostrarGuardar(false); setNombreFav('')
          favoritos.refetch()
        },
      },
    )
  }

  const exportarExcel = () => {
    if (!ejecutar.data?.filas?.length) return
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(ejecutar.data.filas), 'Datos')
    const meta = [
      { Campo: 'Dominio', Valor: dominios?.find(d => d.id === dominio)?.nombre },
      { Campo: 'Dimensiones', Valor: dimensionesSel.join(', ') },
      { Campo: 'Métricas', Valor: metricasSel.join(', ') },
      { Campo: 'Filtros', Valor: JSON.stringify(filtros) },
      { Campo: 'Generado', Valor: new Date().toLocaleString('es-CO') },
      { Campo: 'Filas', Valor: ejecutar.data.n_filas },
      { Campo: 'ms', Valor: ejecutar.data.duracion_ms.toFixed(0) },
    ]
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(meta), 'Metadata')
    XLSX.writeFile(wb, `informe-${dominio}-${new Date().toISOString().slice(0, 10)}.xlsx`)
  }

  return (
    <div className="space-y-4">
      <PageHeader
        title="Informes dinámicos"
        sub="Arme su reporte eligiendo dimensiones, métricas y filtros. El motor valida permisos y audita cada consulta."
        actions={<>
          <Button variant="ghost" onClick={() => setMostrarGuardar(v => !v)} disabled={!dominio}>
            <Save size={14} /> Guardar
          </Button>
          <Button variant="ghost" onClick={exportarExcel} disabled={!ejecutar.data?.filas?.length}>
            <Download size={14} /> Excel
          </Button>
          <Button variant="primary" onClick={correr} disabled={!dominio || (dimensionesSel.length === 0 && metricasSel.length === 0) || ejecutar.isPending}>
            {ejecutar.isPending ? <Spinner /> : <Play size={14} />} Ejecutar
          </Button>
        </>}
      />

      {mostrarGuardar && (
        <Card>
          <div className="flex flex-wrap items-end gap-2">
            <Field label="Nombre del informe">
              <Input value={nombreFav} onChange={e => setNombreFav(e.target.value)} placeholder="Consumo H₂SO₄ semestre 2026-2" className="min-w-[280px]" />
            </Field>
            <Button variant="primary" onClick={guardarFavorito} disabled={!nombreFav.trim() || guardar.isPending}>
              {guardar.isPending ? <Spinner /> : <Save size={14} />} Guardar como favorito
            </Button>
            <Button variant="ghost" onClick={() => setMostrarGuardar(false)}>Cancelar</Button>
          </div>
        </Card>
      )}

      <div className="grid gap-4 lg:grid-cols-[280px_1fr]">
        <aside className="space-y-3">
          <Card header="Dominio">
            <Select value={dominio} onChange={e => { setDominio(e.target.value); setDimensionesSel([]); setMetricasSel([]); setFiltros([]); setOrdenCampo('') }}>
              <option value="">Seleccionar…</option>
              {(dominios ?? []).map(d => <option key={d.id} value={d.id}>{d.nombre}</option>)}
            </Select>
            {dominio && (
              <p className="mt-2 text-xs text-fg-muted">
                {dominios?.find(d => d.id === dominio)?.descripcion}
              </p>
            )}
          </Card>

          {dominio && (
            <Card header={`Dimensiones · ${dimensionesSel.length}`}>
              <ul className="space-y-1 text-sm">
                {(dimensiones ?? []).map(d => (
                  <li key={d.id}>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input type="checkbox"
                        checked={dimensionesSel.includes(d.id)}
                        onChange={e => setDimensionesSel(e.target.checked ? [...dimensionesSel, d.id] : dimensionesSel.filter(x => x !== d.id))} />
                      <span>{d.etiqueta}</span>
                      <span className="ml-auto text-[10px] text-fg-faint">{d.tipo}</span>
                    </label>
                  </li>
                ))}
              </ul>
            </Card>
          )}

          {dominio && (
            <Card header={`Métricas · ${metricasSel.length}`}>
              <ul className="space-y-1 text-sm">
                {(metricas ?? []).map(m => (
                  <li key={m.id}>
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input type="checkbox"
                        checked={metricasSel.includes(m.id)}
                        onChange={e => setMetricasSel(e.target.checked ? [...metricasSel, m.id] : metricasSel.filter(x => x !== m.id))} />
                      <span>{m.etiqueta}</span>
                      {m.unidad && <span className="ml-auto text-[10px] text-fg-faint">{m.unidad}</span>}
                    </label>
                  </li>
                ))}
              </ul>
            </Card>
          )}

          <Card header={`Favoritos · ${favoritos.data?.length ?? 0}`}>
            {favoritos.data?.length === 0 ? (
              <p className="text-xs text-fg-muted">Aún no has guardado ningún informe.</p>
            ) : (
              <ul className="space-y-1 text-sm">
                {(favoritos.data ?? []).map(f => (
                  <li key={f.id} className="flex items-center gap-2">
                    <button onClick={() => cargarFavorito(f.spec)} className="flex-1 text-left hover:text-accent">{f.nombre}</button>
                    <button onClick={() => borrarFav.mutate(f.id, { onSuccess: () => favoritos.refetch() })} className="text-fg-faint hover:text-danger"><Trash2 size={12} /></button>
                  </li>
                ))}
              </ul>
            )}
          </Card>
        </aside>

        <main className="space-y-4">
          <Card header={`Filtros · ${filtros.length}`}>
            {filtros.length === 0 && <p className="text-xs text-fg-muted">Sin filtros. El informe traerá todo lo permitido por su rol.</p>}
            <div className="space-y-2">
              {filtros.map((f, i) => (
                <FilaFiltro key={i} filtro={f} dimensiones={dimensiones ?? []}
                  onChange={nf => setFiltros(filtros.map((x, k) => k === i ? nf : x))}
                  onRemove={() => setFiltros(filtros.filter((_, k) => k !== i))} />
              ))}
            </div>
            {dominio && (
              <Button variant="ghost" size="sm" onClick={() => setFiltros([...filtros, { campo: '', op: 'eq', valor: '' }])} className="mt-2">
                <Plus size={13} /> Agregar filtro
              </Button>
            )}
          </Card>

          <Card header="Orden y límite">
            <div className="flex flex-wrap items-end gap-2">
              <Field label="Ordenar por">
                <Select value={ordenCampo} onChange={e => setOrdenCampo(e.target.value)}>
                  <option value="">— sin orden —</option>
                  {[...(dimensiones ?? []), ...(metricas ?? [])].map(c => (
                    <option key={c.id} value={c.id}>{c.etiqueta}</option>
                  ))}
                </Select>
              </Field>
              <Field label="Dirección">
                <Select value={ordenDir} onChange={e => setOrdenDir(e.target.value as 'asc' | 'desc')}>
                  <option value="desc">Descendente</option>
                  <option value="asc">Ascendente</option>
                </Select>
              </Field>
              <Field label="Límite">
                <Input type="number" min={1} max={10000} value={limite} onChange={e => setLimite(Number(e.target.value) || 500)} className="w-24" />
              </Field>
            </div>
          </Card>

          {ejecutar.error && (
            <Card>
              <div className="border-l-2 border-danger bg-danger-soft px-3 py-2 text-sm text-danger">
                {(ejecutar.error as Error).message}
              </div>
            </Card>
          )}

          {ejecutar.data ? (
            <Resultados data={ejecutar.data} camposMap={camposMap} />
          ) : (
            !ejecutar.isPending && <Empty titulo="Sin resultados" descripcion="Elija al menos una dimensión o métrica y ejecute el informe." />
          )}
        </main>
      </div>
    </div>
  )
}

function FilaFiltro({ filtro, dimensiones, onChange, onRemove }: {
  filtro: Filtro; dimensiones: Dimension[]
  onChange: (f: Filtro) => void; onRemove: () => void
}) {
  const dim = dimensiones.find(d => d.id === filtro.campo)
  const opDef = OPERADORES.find(o => o.v === filtro.op) ?? OPERADORES[0]
  return (
    <div className="flex flex-wrap items-center gap-2 border border-border rounded-md p-2 bg-surface-2">
      <Select value={filtro.campo} onChange={e => onChange({ ...filtro, campo: e.target.value })} className="w-48">
        <option value="">Campo…</option>
        {dimensiones.map(d => <option key={d.id} value={d.id}>{d.etiqueta}</option>)}
      </Select>
      <Select value={filtro.op} onChange={e => onChange({ ...filtro, op: e.target.value as Operador })} className="w-40">
        {OPERADORES.map(o => <option key={o.v} value={o.v}>{o.l}</option>)}
      </Select>
      {opDef.valor === 'uno' && (
        <Input value={String(filtro.valor ?? '')} onChange={e => onChange({ ...filtro, valor: e.target.value })}
          placeholder={dim?.tipo === 'date' ? 'YYYY-MM-DD' : 'valor'}
          type={dim?.tipo === 'date' ? 'date' : dim?.tipo === 'int' || dim?.tipo === 'numeric' ? 'number' : 'text'}
          className="flex-1 min-w-[160px]" />
      )}
      {opDef.valor === 'lista' && (
        <Input value={Array.isArray(filtro.valor) ? (filtro.valor as string[]).join(', ') : String(filtro.valor ?? '')}
          onChange={e => onChange({ ...filtro, valor: e.target.value.split(',').map(x => x.trim()).filter(Boolean) })}
          placeholder="separados por coma" className="flex-1 min-w-[160px]" />
      )}
      {opDef.valor === 'rango' && (
        <>
          <Input value={Array.isArray(filtro.valor) ? String((filtro.valor as string[])[0] ?? '') : ''}
            onChange={e => {
              const arr = Array.isArray(filtro.valor) ? [...(filtro.valor as string[])] : ['', '']
              arr[0] = e.target.value
              onChange({ ...filtro, valor: arr })
            }}
            type={dim?.tipo === 'date' ? 'date' : 'text'} placeholder="desde" className="w-40" />
          <Input value={Array.isArray(filtro.valor) ? String((filtro.valor as string[])[1] ?? '') : ''}
            onChange={e => {
              const arr = Array.isArray(filtro.valor) ? [...(filtro.valor as string[])] : ['', '']
              arr[1] = e.target.value
              onChange({ ...filtro, valor: arr })
            }}
            type={dim?.tipo === 'date' ? 'date' : 'text'} placeholder="hasta" className="w-40" />
        </>
      )}
      <button onClick={onRemove} className="ml-auto text-fg-faint hover:text-danger p-1"><X size={14} /></button>
    </div>
  )
}

function Resultados({ data, camposMap }: {
  data: { filas: Record<string, unknown>[]; n_filas: number; duracion_ms: number }
  camposMap: Map<string, Dimension | Metrica>
}) {
  if (!data.filas || data.filas.length === 0) {
    return <Empty titulo="Consulta sin resultados" descripcion="Pruebe quitar filtros o ampliar el periodo." />
  }
  const columnas = Object.keys(data.filas[0])
  const headers = columnas.map(c => {
    const def = camposMap.get(c)
    return def?.etiqueta ?? c
  })
  const filas = data.filas.map(f =>
    columnas.map(c => {
      const def = camposMap.get(c)
      if (def && 'formato' in def) {
        return <span className="tabular-nums">{formatearMetrica(f[c], (def as Metrica).formato, (def as Metrica).unidad)}</span>
      }
      const v = f[c]
      if (v == null) return <span className="text-fg-faint">—</span>
      return String(v)
    })
  )
  return (
    <Card
      header={<div className="flex items-center gap-2">Resultados <Badge tone="info">{data.n_filas}</Badge> <span className="text-xs text-fg-faint">· {data.duracion_ms.toFixed(0)} ms</span></div>}
    >
      <Table columnas={headers} filas={filas} />
    </Card>
  )
}

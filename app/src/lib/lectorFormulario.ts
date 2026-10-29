import * as XLSX from 'xlsx'

/* Lector del «Formulario de insumos por práctica» (v3). Lee por posición de celda. */

export interface LineaLeida {
  texto: string
  cantidad?: number
  cantidad_por_mesa?: number
  unidad?: string
  concentracion?: string
}
export interface JornadaLeida {
  fecha: string
  inicio: string
  fin: string
  num_estudiantes: number | null
  num_grupos_trabajo: number | null
}
export interface HojaLeida {
  hoja: string
  practica_nombre: string
  campus: string
  programa_academico: string
  curso: string
  fecha: string
  inicio: string
  fin: string
  num_estudiantes: number | null
  num_grupos_trabajo: number | null
  agua_destilada_l: number | null
  observaciones: string
  otras_jornadas: JornadaLeida[]
  reactivos: LineaLeida[]
  materiales: LineaLeida[]
  /** Obligatorios que faltan o datos inválidos: impiden importar la hoja. */
  faltan: string[]
  /** Advertencias que no impiden importar. */
  avisos: string[]
}
export interface DocenteLeido {
  nombre: string
  correo: string
  celular: string
}
export interface ArchivoLeido {
  docente: DocenteLeido | null
  hojas: HojaLeida[]
  ignoradas: string[]
}

const HOJAS_NO_PRACTICA = ['instrucciones', 'docente', 'plantilla']
const CAMPUS = ['Turbo', 'Apartadó', 'Carepa']

const sinTildes = (t: string) => t.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim()

type Hoja = XLSX.WorkSheet
const crudo = (ws: Hoja, dir: string): unknown => {
  const c = ws[dir]
  return c && c.v !== undefined && c.v !== null && c.v !== '' ? c.v : undefined
}
const texto = (ws: Hoja, dir: string): string => {
  const v = crudo(ws, dir)
  return v === undefined ? '' : String(v).replace(/\s+/g, ' ').trim()
}
const numero = (ws: Hoja, dir: string): number | null => {
  const v = crudo(ws, dir)
  if (v === undefined) return null
  if (typeof v === 'number') return isFinite(v) ? v : null
  const n = Number(String(v).replace(',', '.').trim())
  return isNaN(n) ? null : n
}

const pad = (n: number) => String(n).padStart(2, '0')

/** Fecha como AAAA-MM-DD; acepta número de serie de Excel o texto DD/MM/AAAA. */
export function leerFecha(v: unknown): string {
  if (v === undefined || v === null || v === '') return ''
  if (typeof v === 'number') {
    const d = new Date(Date.UTC(1899, 11, 30) + Math.floor(v) * 86400000)
    return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`
  }
  const s = String(v).trim()
  let m = s.match(/^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$/)
  if (m) return `${m[3]}-${pad(+m[2])}-${pad(+m[1])}`
  m = s.match(/^(\d{4})-(\d{2})-(\d{2})/)
  return m ? `${m[1]}-${m[2]}-${m[3]}` : ''
}

/** Hora como HH:MM; acepta fracción de día de Excel o texto «9:00», «2:30 pm». */
export function leerHora(v: unknown): string {
  if (v === undefined || v === null || v === '') return ''
  if (typeof v === 'number') {
    const min = Math.round((v - Math.floor(v)) * 1440)
    return `${pad(Math.floor(min / 60) % 24)}:${pad(min % 60)}`
  }
  const m = String(v).trim().toLowerCase().match(/^(\d{1,2})[:.](\d{2})\s*(a\.?m\.?|p\.?m\.?)?$/)
  if (!m) return ''
  let h = +m[1]
  if (m[3]?.startsWith('p') && h < 12) h += 12
  if (m[3]?.startsWith('a') && h === 12) h = 0
  return h > 23 || +m[2] > 59 ? '' : `${pad(h)}:${m[2]}`
}

function leerLineas(ws: Hoja, cols: { desc: string; total: string; mesa: string; unidad?: string; conc?: string }, avisos: string[], tipo: string): LineaLeida[] {
  const out: LineaLeida[] = []
  for (let r = 21; r <= 55; r++) {
    const desc = texto(ws, `${cols.desc}${r}`)
    const total = numero(ws, `${cols.total}${r}`)
    const mesa = numero(ws, `${cols.mesa}${r}`)
    if (!desc) {
      if ((total ?? 0) > 0) avisos.push(`${tipo}, fila ${r}: hay cantidad pero no descripción (se omite)`)
      continue
    }
    out.push({
      texto: desc,
      cantidad: total !== null && total >= 0 ? total : undefined,
      cantidad_por_mesa: total === null && mesa !== null && mesa >= 0 ? mesa : undefined,
      unidad: cols.unidad ? texto(ws, `${cols.unidad}${r}`) || undefined : undefined,
      concentracion: cols.conc ? texto(ws, `${cols.conc}${r}`) || undefined : undefined,
    })
  }
  return out
}

export function leerHoja(ws: Hoja, nombreHoja: string): HojaLeida {
  const faltan: string[] = []
  const avisos: string[] = []

  const campusTxt = texto(ws, 'E6')
  const campus = CAMPUS.find((c) => sinTildes(c) === sinTildes(campusTxt)) ?? ''
  if (campusTxt && !campus) faltan.push(`campus «${campusTxt}» no válido (Turbo, Apartadó o Carepa)`)

  const fecha = leerFecha(crudo(ws, 'E9'))
  const inicio = leerHora(crudo(ws, 'E10'))
  const fin = leerHora(crudo(ws, 'E11'))
  const agua = numero(ws, 'K11')

  const otras: JornadaLeida[] = []
  for (let r = 15; r <= 16; r++) {
    const f = leerFecha(crudo(ws, `C${r}`))
    if (!f) continue
    const i = leerHora(crudo(ws, `D${r}`))
    const e = leerHora(crudo(ws, `E${r}`))
    if (!i || !e || e <= i) faltan.push(`otras jornadas, fila ${r}: falta hora de inicio o de fin válida`)
    otras.push({ fecha: f, inicio: i, fin: e, num_estudiantes: numero(ws, `F${r}`), num_grupos_trabajo: numero(ws, `G${r}`) })
  }

  const reactivos = leerLineas(ws, { desc: 'G', total: 'I', mesa: 'J', unidad: 'K', conc: 'L' }, avisos, 'Reactivos')
  const materiales = leerLineas(ws, { desc: 'C', total: 'E', mesa: 'F' }, avisos, 'Equipos')

  const obs = texto(ws, 'B57').replace(/^observaciones\s*:?\s*/i, '').trim()

  const h: HojaLeida = {
    hoja: nombreHoja,
    practica_nombre: texto(ws, 'G7'),
    campus,
    programa_academico: texto(ws, 'E7'),
    curso: texto(ws, 'E8'),
    fecha,
    inicio,
    fin,
    num_estudiantes: numero(ws, 'K9'),
    num_grupos_trabajo: numero(ws, 'K10'),
    agua_destilada_l: agua,
    observaciones: obs,
    otras_jornadas: otras,
    reactivos,
    materiales,
    faltan,
    avisos,
  }

  if (!h.practica_nombre) faltan.push('nombre de la práctica de laboratorio')
  if (!campusTxt) faltan.push('campus')
  if (!h.programa_academico) faltan.push('programa académico')
  if (!h.curso) faltan.push('nombre del curso')
  if (!fecha) faltan.push('fecha de realización')
  if (!inicio) faltan.push('hora de inicio')
  if (!fin) faltan.push('hora de fin')
  if (inicio && fin && fin <= inicio) faltan.push('la hora de fin debe ser posterior a la de inicio')
  if (agua === null || agua < 0) faltan.push('agua destilada estimada (litros)')
  if (h.num_estudiantes === null) avisos.push('no se indicó el número de estudiantes')
  if (h.num_grupos_trabajo === null) {
    if ([...reactivos, ...materiales].some((l) => l.cantidad === undefined && l.cantidad_por_mesa !== undefined))
      faltan.push('hay cantidades por mesa pero falta el número de grupos de trabajo (mesas)')
    else avisos.push('no se indicó el número de grupos de trabajo (mesas)')
  }
  if (reactivos.length + materiales.length === 0) avisos.push('la hoja no tiene reactivos ni equipos')
  return h
}

function hojaVacia(ws: Hoja): boolean {
  return !texto(ws, 'G7') && !texto(ws, 'E9') && !crudo(ws, 'E9') && !texto(ws, 'I21') && !texto(ws, 'G21') && !texto(ws, 'C21')
}

export function leerDocente(wb: XLSX.WorkBook): DocenteLeido | null {
  const nombre = Object.keys(wb.Sheets).find((n) => sinTildes(n) === 'docente')
  if (!nombre) return null
  const ws = wb.Sheets[nombre]
  const celular = crudo(ws, 'E8')
  const d: DocenteLeido = {
    nombre: texto(ws, 'E6'),
    correo: texto(ws, 'E7').toLowerCase(),
    celular: celular === undefined ? '' : String(celular).replace(/\.0$/, '').trim(),
  }
  return d.nombre || d.correo || d.celular ? d : null
}

export function leerFormulario(datos: ArrayBuffer): ArchivoLeido {
  const wb = XLSX.read(datos, { type: 'array' })
  const hojas: HojaLeida[] = []
  const ignoradas: string[] = []
  for (const nombre of wb.SheetNames) {
    if (HOJAS_NO_PRACTICA.includes(sinTildes(nombre))) continue
    const ws = wb.Sheets[nombre]
    if (hojaVacia(ws)) {
      ignoradas.push(nombre)
      continue
    }
    hojas.push(leerHoja(ws, nombre))
  }
  return { docente: leerDocente(wb), hojas, ignoradas }
}

/** JSON que recibe la función importar_formulario de la base de datos. */
export function aPayload(h: HojaLeida, extra: { archivo: string; docente_id?: string | null }) {
  return {
    origen: 'excel_import',
    archivo: extra.archivo,
    estado: 'solicitada',
    docente_id: extra.docente_id ?? undefined,
    practica_nombre: h.practica_nombre,
    campus: h.campus,
    programa_academico: h.programa_academico,
    curso: h.curso,
    agua_destilada_l: h.agua_destilada_l,
    fecha: h.fecha,
    inicio: h.inicio,
    fin: h.fin,
    num_estudiantes: h.num_estudiantes,
    num_grupos_trabajo: h.num_grupos_trabajo,
    observaciones: h.observaciones,
    otras_jornadas: h.otras_jornadas,
    reactivos: h.reactivos,
    materiales: h.materiales,
  }
}

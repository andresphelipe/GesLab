/** Misma normalización que normalizar_texto() en la base de datos. */
export function normalizar(t: string): string {
  return t
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/\s+/g, ' ')
    .replace(/^[\s.,;:]+|[\s.,;:]+$/g, '')
}

/** Quita una concentración final como "2 M" o "(0,1 M)" del nombre de un reactivo. */
export function sinConcentracion(norm: string): string {
  return norm.replace(/\(?\s*\d+(?:[.,]\d+)?\s*m\)?\s*$/, '').trim()
}

import { useCallback, useEffect, useState } from 'react'

export type Tema = 'light' | 'dark' | 'auto'

const KEY = 'geslab-tema'

function leer(): Tema {
  try {
    const v = localStorage.getItem(KEY)
    if (v === 'light' || v === 'dark') return v
  } catch {}
  return 'auto'
}

function aplicar(t: Tema) {
  const root = document.documentElement
  if (t === 'auto') root.removeAttribute('data-theme')
  else root.setAttribute('data-theme', t)
}

export function useTema() {
  const [tema, setTemaRaw] = useState<Tema>(() => leer())

  useEffect(() => aplicar(tema), [tema])

  const setTema = useCallback((t: Tema) => {
    try {
      if (t === 'auto') localStorage.removeItem(KEY)
      else localStorage.setItem(KEY, t)
    } catch {}
    setTemaRaw(t)
  }, [])

  const alternar = useCallback(() => {
    setTema(tema === 'dark' ? 'light' : 'dark')
  }, [tema, setTema])

  return { tema, setTema, alternar }
}

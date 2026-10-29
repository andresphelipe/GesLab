# GesLab

App de gestión de laboratorios docentes de ciencias — UdeA sede Urabá (Turbo, Apartadó, Carepa).

## Stack

- **Supabase** (PostgreSQL + RLS + Auth): esquema y lógica en los archivos `01_*.sql`–`10_*.sql` en la raíz.
- **Frontend** (Vite + React + TypeScript + Tailwind + TanStack Query + Recharts) en `app/`.

## Puesta en marcha local

```bash
cd app
cp .env.example .env   # pega VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY del proyecto
npm install
npm run dev
```

## Despliegue

El frontend se publica en Vercel conectando este repositorio.
- Root Directory: `app`
- Build Command: `npm run build`
- Output Directory: `dist`
- Variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_RECUPERACION_POR_CORREO=false`

El backend corre en Supabase (nube). Los archivos `*.sql` de la raíz se ejecutan en el SQL Editor del proyecto, en orden numérico, cuando hay cambios de esquema.

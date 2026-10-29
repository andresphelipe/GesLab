import { ButtonHTMLAttributes, InputHTMLAttributes, SelectHTMLAttributes, TextareaHTMLAttributes, forwardRef } from 'react'
import clsx from 'clsx'

/* ---------- Button ---------- */
type Variant = 'primary' | 'secondary' | 'ghost' | 'danger'
type Size = 'sm' | 'md' | 'lg'
export function Button({
  variant = 'secondary', size = 'md', className, ...rest
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: Variant; size?: Size }) {
  return (
    <button
      className={clsx(
        'btn',
        variant === 'primary' && 'btn-primary',
        variant === 'ghost' && 'btn-ghost',
        variant === 'danger' && 'btn-danger',
        size === 'sm' && 'btn-sm',
        size === 'lg' && 'btn-lg',
        className,
      )}
      {...rest}
    />
  )
}

/* ---------- Form controls ---------- */
export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  ({ className, ...rest }, ref) => <input ref={ref} className={clsx('input', className)} {...rest} />,
)
Input.displayName = 'Input'

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(
  ({ className, ...rest }, ref) => <textarea ref={ref} className={clsx('input min-h-[64px]', className)} {...rest} />,
)
Textarea.displayName = 'Textarea'

export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(
  ({ className, children, ...rest }, ref) => (
    <select ref={ref} className={clsx('input appearance-none pr-7 bg-no-repeat bg-right', className)}
      style={{ backgroundImage: `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%23a1a1aa' stroke-width='2'><polyline points='6 9 12 15 18 9'/></svg>")`, backgroundPositionX: 'calc(100% - 8px)' }}
      {...rest}>{children}</select>
  ),
)
Select.displayName = 'Select'

export function Label({ htmlFor, children, hint }: { htmlFor?: string; children: React.ReactNode; hint?: string }) {
  return (
    <label htmlFor={htmlFor} className="mb-1 flex items-end justify-between gap-2 text-xs font-medium text-fg-muted">
      <span>{children}</span>
      {hint && <span className="text-fg-faint">{hint}</span>}
    </label>
  )
}

export function Field({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return <div className="flex flex-col"><Label hint={hint}>{label}</Label>{children}</div>
}

/* ---------- Card / Panel ---------- */
export function Card({ className, children, header, footer }: { className?: string; children: React.ReactNode; header?: React.ReactNode; footer?: React.ReactNode }) {
  return (
    <section className={clsx('card overflow-hidden', className)}>
      {header && <header className="border-b border-border px-4 py-2.5 text-sm font-semibold">{header}</header>}
      <div className={clsx(!header && 'p-0', header && 'p-4')}>{children}</div>
      {footer && <footer className="border-t border-border px-4 py-2 text-xs text-fg-muted">{footer}</footer>}
    </section>
  )
}

/* ---------- Badge / Status pill ---------- */
export function Badge({ tone = 'default', children, className }: { tone?: 'default' | 'ok' | 'warn' | 'danger' | 'info'; children: React.ReactNode; className?: string }) {
  return <span className={clsx('badge', tone === 'ok' && 'badge-ok', tone === 'warn' && 'badge-warn', tone === 'danger' && 'badge-danger', tone === 'info' && 'badge-info', className)}>{children}</span>
}

/* ---------- Page header ---------- */
export function PageHeader({ title, sub, actions }: { title: string; sub?: string; actions?: React.ReactNode }) {
  return (
    <header className="mb-4 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="page-title">{title}</h1>
        {sub && <p className="page-sub mt-0.5">{sub}</p>}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </header>
  )
}

/* ---------- Empty state ---------- */
export function Empty({ titulo, descripcion, icon }: { titulo: string; descripcion?: string; icon?: React.ReactNode }) {
  return (
    <div className="rounded-lg border border-dashed border-border bg-surface px-6 py-10 text-center">
      {icon && <div className="mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-full bg-muted text-fg-muted">{icon}</div>}
      <p className="text-sm font-semibold">{titulo}</p>
      {descripcion && <p className="mt-1 text-xs text-fg-muted">{descripcion}</p>}
    </div>
  )
}

/* ---------- Spinner ---------- */
export function Spinner({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" className={clsx('h-4 w-4 animate-spin', className)} fill="none" stroke="currentColor" strokeWidth="2">
      <circle cx="12" cy="12" r="9" opacity="0.25" />
      <path d="M21 12a9 9 0 0 0-9-9" strokeLinecap="round" />
    </svg>
  )
}

/* ---------- Table wrapper ---------- */
export function Table({ columnas, filas, vacio }: { columnas: string[]; filas: React.ReactNode[][]; vacio?: string }) {
  if (filas.length === 0) {
    return <Empty titulo={vacio ?? 'Sin datos'} />
  }
  return (
    <div className="overflow-x-auto rounded-lg border border-border">
      <table className="table-grid">
        <thead><tr>{columnas.map(c => <th key={c}>{c}</th>)}</tr></thead>
        <tbody>
          {filas.map((f, i) => <tr key={i}>{f.map((c, j) => <td key={j}>{c}</td>)}</tr>)}
        </tbody>
      </table>
    </div>
  )
}

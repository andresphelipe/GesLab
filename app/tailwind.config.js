/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class', '[data-theme="dark"]'],
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Semántica — se definen en index.css con CSS variables
        bg:            'var(--bg)',
        surface:       'var(--surface)',
        surface2:      'var(--surface-2)',
        muted:         'var(--muted)',
        fg:            'var(--fg)',
        'fg-muted':    'var(--fg-muted)',
        'fg-faint':    'var(--fg-faint)',
        border:        'var(--border)',
        'border-strong':'var(--border-strong)',
        accent:        'var(--accent)',
        'accent-fg':   'var(--accent-fg)',
        'accent-soft': 'var(--accent-soft)',
        ok:            'var(--ok)',
        'ok-soft':     'var(--ok-soft)',
        warn:          'var(--warn)',
        'warn-soft':   'var(--warn-soft)',
        danger:        'var(--danger)',
        'danger-soft': 'var(--danger-soft)',
        info:          'var(--info)',
        'info-soft':   'var(--info-soft)',
      },
      fontFamily: {
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'Consolas', 'monospace'],
      },
      fontSize: {
        // escala densa, base 13
        xs:   ['11px', { lineHeight: '15px' }],
        sm:   ['12px', { lineHeight: '16px' }],
        base: ['13px', { lineHeight: '18px' }],
        md:   ['14px', { lineHeight: '20px' }],
        lg:   ['15px', { lineHeight: '22px' }],
        xl:   ['18px', { lineHeight: '24px' }],
        '2xl':['22px', { lineHeight: '28px' }],
        '3xl':['28px', { lineHeight: '34px' }],
      },
      borderRadius: {
        DEFAULT: '6px',
        md: '7px',
        lg: '9px',
        xl: '12px',
      },
      boxShadow: {
        xs: '0 1px 1px rgba(0,0,0,0.04)',
        sm: '0 1px 2px rgba(10,15,25,0.06), 0 1px 1px rgba(10,15,25,0.04)',
        md: '0 4px 10px -2px rgba(10,15,25,0.08), 0 2px 4px -2px rgba(10,15,25,0.06)',
        lg: '0 12px 24px -6px rgba(10,15,25,0.12), 0 4px 8px -4px rgba(10,15,25,0.08)',
      },
    },
  },
  plugins: [],
}

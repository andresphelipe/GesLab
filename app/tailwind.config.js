/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f7ff', 100: '#e0effe', 200: '#b9dffd',
          300: '#7cc8fc', 400: '#36aef8', 500: '#0c95e9',
          600: '#0075c7', 700: '#015da1', 800: '#065085', 900: '#0b436e'
        }
      }
    }
  },
  plugins: []
}

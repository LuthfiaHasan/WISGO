/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        cream: {
          DEFAULT: '#F6F3EC',
          subtle: '#EDE8DD',
          100: '#F6F3EC',
          200: '#E5DFCF',
        },
        forest: {
          DEFAULT: '#193D22',
          deep: '#142618',
        },
        brush: {
          DEFAULT: '#2F663E',
          hover: '#265433',
        },
        sage: {
          DEFAULT: '#DFECE2',
          border: '#D5E2D7',
          100: '#E4E9DA',
          200: '#CFD8BE',
        },
        warm: {
          border: '#E5DEC9',
        },
        terracotta: {
          DEFAULT: '#E65F2B',
        },
        green: {
          500: '#1E9E5A',
          700: '#1B3B1C',
          800: '#234B24',
        },
        ink: {
          DEFAULT: '#142618',
          900: '#142618',
          800: '#1B1F1A',
          600: '#4A5248',
          muted: '#5A6B5D',
        },
        coral: {
          DEFAULT: '#F26B4B',
          tint: '#F9E4DC',
          500: '#F26B4B',
          600: '#D95637',
        },
        orange: {
          500: '#E85D1A',
        },
        indigo: {
          500: '#5B6AE8',
        },
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'system-ui', '-apple-system', 'sans-serif'],
      },
      borderRadius: {
        pill: '26px',
        sheet: '28px',
      },
      boxShadow: {
        soft: '0 4px 24px rgba(35, 75, 36, 0.04)',
        elevated: '0 8px 32px rgba(35, 75, 36, 0.08)',
        subtle: '0 2px 12px rgba(35, 75, 36, 0.03)',
      },
    },
  },
  plugins: [],
};


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
          100: '#F6F3EC',
          200: '#ECE6D8',
        },
        green: {
          500: '#1E9E5A',
          700: '#1B3B1C',
          800: '#234B24',
        },
        ink: {
          900: '#1B1F1A',
          600: '#4A5248',
        },
        coral: {
          500: '#F26B4B',
          600: '#D95637',
        },
        orange: {
          500: '#E85D1A',
        },
        indigo: {
          500: '#5B6AE8',
        },
        sage: {
          100: '#E4E9DA',
          200: '#CFD8BE',
        },
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'system-ui', '-apple-system', 'sans-serif'],
      },
      borderRadius: {
        pill: '26px',
        sheet: '28px',
      },
    },
  },
  plugins: [],
};


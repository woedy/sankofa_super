import type { Config } from 'tailwindcss';
import forms from '@tailwindcss/forms';
import typography from '@tailwindcss/typography';

const config: Config = {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#1E3A8A',
          foreground: '#FFFFFF',
          light: '#93C5FD',
          dark: '#12245C'
        },
        accent: {
          DEFAULT: '#14B8A6',
          foreground: '#FFFFFF'
        }
      },
      backgroundImage: {
        'grid-light':
          'linear-gradient(rgba(30,58,138,0.08) 1px, transparent 1px), linear-gradient(90deg, rgba(30,58,138,0.08) 1px, transparent 1px)',
        'grid-dark':
          'linear-gradient(rgba(147,197,253,0.08) 1px, transparent 1px), linear-gradient(90deg, rgba(147,197,253,0.08) 1px, transparent 1px)'
      }
    }
  },
  plugins: [forms, typography]
};

export default config;

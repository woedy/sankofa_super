import { MoonIcon, SunIcon } from 'lucide-react';
import { useTheme } from '../providers/ThemeProvider';
import clsx from 'clsx';

const ThemeToggle = ({ className }: { className?: string }) => {
  const { theme, toggleTheme } = useTheme();

  return (
    <button
      onClick={toggleTheme}
      className={clsx(
        'inline-flex items-center gap-2 rounded-full border border-slate-200 px-3 py-1 text-sm font-medium text-slate-600 transition hover:border-primary hover:text-primary dark:border-slate-700 dark:text-slate-300 dark:hover:border-primary dark:hover:text-primary',
        className
      )}
    >
      {theme === 'light' ? <SunIcon size={16} /> : <MoonIcon size={16} />}
      <span>{theme === 'light' ? 'Light' : 'Dark'} mode</span>
    </button>
  );
};

export default ThemeToggle;

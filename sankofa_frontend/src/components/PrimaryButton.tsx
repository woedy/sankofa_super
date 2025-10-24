import type { ButtonHTMLAttributes } from 'react';
import clsx from 'clsx';
import { ArrowRightIcon } from 'lucide-react';

interface Props extends ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  icon?: boolean;
}

const PrimaryButton = ({ label, className, icon = true, ...rest }: Props) => {
  return (
    <button
      className={clsx(
        'group inline-flex items-center gap-2 rounded-full bg-primary px-5 py-2 text-sm font-semibold text-primary-foreground shadow-lg shadow-primary/25 transition hover:-translate-y-0.5 hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-primary-light focus:ring-offset-2 dark:shadow-primary/40',
        className
      )}
      {...rest}
    >
      <span>{label}</span>
      {icon && <ArrowRightIcon size={16} className="transition group-hover:translate-x-1" />}
    </button>
  );
};

export default PrimaryButton;

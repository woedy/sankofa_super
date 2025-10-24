import { Link } from 'react-router-dom';
import { savingsGoals } from '../../assets/data/mockData';
import { ArrowUpRightIcon, CalendarDaysIcon, TrendingUpIcon } from 'lucide-react';

const Savings = () => {
  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <p className="text-sm font-semibold uppercase tracking-widest text-primary">Savings goals</p>
        <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Stay on track</h1>
        <p className="text-sm text-slate-600 dark:text-slate-300">
          Monitor progress, celebrate milestones, and launch boosts exactly like the mobile app flow.
        </p>
      </header>
      <div className="grid gap-6 md:grid-cols-2">
        {savingsGoals.map((goal) => {
          const progress = Math.round((goal.savedAmount / goal.targetAmount) * 100);
          return (
            <Link
              key={goal.id}
              to={`/app/savings/${goal.id}`}
              className="rounded-3xl border border-slate-200 bg-white/90 p-6 shadow-lg transition hover:-translate-y-1 hover:border-primary dark:border-slate-800 dark:bg-slate-900/80"
            >
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-semibold text-slate-900 dark:text-white">{goal.name}</h2>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{goal.category} • Target GH₵{goal.targetAmount.toLocaleString()}</p>
                </div>
                <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
                  <TrendingUpIcon size={14} /> {progress}%
                </span>
              </div>
              <div className="mt-6 h-2 rounded-full bg-slate-200 dark:bg-slate-700">
                <div className="h-2 rounded-full bg-primary" style={{ width: `${progress}%` }} />
              </div>
              <p className="mt-4 text-sm text-slate-600 dark:text-slate-300">Saved GH₵{goal.savedAmount.toLocaleString()} so far.</p>
              <p className="mt-2 inline-flex items-center gap-2 text-xs font-semibold text-primary">
                <CalendarDaysIcon size={16} /> Target date {goal.targetDate}
              </p>
              <div className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-primary">
                View details <ArrowUpRightIcon size={16} />
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
};

export default Savings;

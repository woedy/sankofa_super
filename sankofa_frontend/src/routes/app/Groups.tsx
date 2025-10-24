import { Link } from 'react-router-dom';
import { groups } from '../../assets/data/mockData';
import { UsersIcon, CalendarDaysIcon, ArrowUpRightIcon } from 'lucide-react';

const Groups = () => {
  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <p className="text-sm font-semibold uppercase tracking-widest text-primary">Groups</p>
        <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Your susu circles</h1>
        <p className="text-sm text-slate-600 dark:text-slate-300">
          Review rosters, contribution schedules, and payout forecasts. Everything mirrors the Ghana-focused mobile experience.
        </p>
      </header>
      <div className="grid gap-6 md:grid-cols-2">
        {groups.map((group) => (
          <Link
            key={group.id}
            to={`/app/groups/${group.id}`}
            className="rounded-3xl border border-slate-200 bg-white/90 shadow-lg transition hover:-translate-y-1 hover:border-primary dark:border-slate-800 dark:bg-slate-900/80"
          >
            <div className="h-48 overflow-hidden rounded-t-3xl">
              <img src={group.heroImage} alt={group.name} className="h-full w-full object-cover" />
            </div>
            <div className="space-y-4 p-6">
              <div className="flex items-center justify-between">
                <h2 className="text-xl font-semibold text-slate-900 dark:text-white">{group.name}</h2>
                <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
                  <UsersIcon size={14} /> {group.members} members
                </span>
              </div>
              <div className="grid gap-2 text-sm text-slate-600 dark:text-slate-300">
                <p>Cycle status: <span className="font-semibold text-slate-900 dark:text-white">{group.cycleStatus}</span></p>
                <p>Contribution: GH₵{group.contribution} per week</p>
                <p className="inline-flex items-center gap-2">
                  <CalendarDaysIcon size={16} className="text-primary" /> Next payout on {group.nextPayout}
                </p>
              </div>
              <div className="flex items-center justify-between text-sm font-semibold text-primary">
                <span>Total pool GH₵{group.totalPool.toLocaleString()}</span>
                <ArrowUpRightIcon size={18} />
              </div>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
};

export default Groups;

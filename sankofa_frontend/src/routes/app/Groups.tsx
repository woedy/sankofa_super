import { Link, useNavigate } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { UsersIcon, CalendarDaysIcon, ArrowUpRightIcon, PlusIcon } from 'lucide-react';
import { groupService } from '../../services/groupService';
import type { SusuGroup } from '../../lib/types';

const Groups = () => {
  const [groups, setGroups] = useState<SusuGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    loadGroups();
  }, []);

  const loadGroups = async () => {
    try {
      const data = await groupService.getGroups();
      setGroups(data);
    } catch (error) {
      console.error('Failed to load groups:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-center">
          <div className="mb-4 h-12 w-12 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
          <p className="text-sm text-slate-600 dark:text-slate-400">Loading groups...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-widest text-primary">Groups</p>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Your susu circles</h1>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              Review rosters, contribution schedules, and payout forecasts. Everything mirrors the Ghana-focused mobile experience.
            </p>
          </div>
          <button
            onClick={() => navigate('/app/groups/create')}
            className="inline-flex items-center gap-2 rounded-2xl bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground shadow-lg transition hover:bg-primary/90"
          >
            <PlusIcon size={16} />
            Create Group
          </button>
        </div>
      </header>
      {groups.length === 0 ? (
        <div className="rounded-3xl border border-slate-200 bg-white p-12 text-center dark:border-slate-800 dark:bg-slate-900">
          <p className="text-slate-600 dark:text-slate-400">You haven't joined any groups yet.</p>
        </div>
      ) : (
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
                  <UsersIcon size={14} /> {group.totalMembers} members
                </span>
              </div>
              <div className="grid gap-2 text-sm text-slate-600 dark:text-slate-300">
                <p>Cycle status: <span className="font-semibold text-slate-900 dark:text-white capitalize">{group.cycleStatus}</span></p>
                <p>Contribution: GH₵{group.contributionAmount} per {group.contributionFrequency}</p>
                <p className="inline-flex items-center gap-2">
                  <CalendarDaysIcon size={16} className="text-primary" /> 
                  {group.nextPayoutDate ? `Next payout on ${new Date(group.nextPayoutDate).toLocaleDateString()}` : 'No payout scheduled'}
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
      )}
    </div>
  );
};

export default Groups;

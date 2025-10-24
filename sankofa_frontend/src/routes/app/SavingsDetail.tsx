import { useMemo } from 'react';
import { Link, useParams } from 'react-router-dom';
import { savingsGoals, transactions } from '../../assets/data/mockData';
import { ArrowLeftIcon, GiftIcon, SparklesIcon } from 'lucide-react';

const SavingsDetail = () => {
  const { id } = useParams<{ id: string }>();
  const goal = useMemo(() => savingsGoals.find((item) => item.id === id), [id]);

  if (!goal) {
    return (
      <div className="space-y-4">
        <p className="text-sm text-slate-500">Goal not found.</p>
        <Link to="/app/savings" className="inline-flex items-center gap-2 text-sm font-semibold text-primary">
          <ArrowLeftIcon size={16} /> Back to savings
        </Link>
      </div>
    );
  }

  const progress = Math.round((goal.savedAmount / goal.targetAmount) * 100);
  const goalTransactions = transactions.filter((transaction) => transaction.type !== 'Withdrawal');

  return (
    <div className="space-y-8">
      <Link to="/app/savings" className="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline">
        <ArrowLeftIcon size={16} /> Back to savings
      </Link>
      <div className="rounded-3xl border border-slate-200 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-900">
        <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-widest text-primary">Savings goal</p>
            <h1 className="mt-2 text-3xl font-bold text-slate-900 dark:text-white">{goal.name}</h1>
            <p className="text-sm text-slate-600 dark:text-slate-300">{goal.category} • Target GH₵{goal.targetAmount.toLocaleString()}</p>
          </div>
          <div className="rounded-3xl bg-primary/10 px-6 py-4 text-right text-primary">
            <p className="text-xs uppercase">Progress</p>
            <p className="text-3xl font-bold">{progress}%</p>
            <p className="text-xs text-primary/70">Saved GH₵{goal.savedAmount.toLocaleString()}</p>
          </div>
        </div>
        <div className="mt-6 h-3 rounded-full bg-slate-200 dark:bg-slate-700">
          <div className="h-3 rounded-full bg-primary" style={{ width: `${progress}%` }} />
        </div>
        <div className="mt-6 grid gap-4 md:grid-cols-2">
          <div className="rounded-2xl bg-slate-50/80 p-4 text-sm text-slate-600 shadow-inner dark:bg-slate-900/60 dark:text-slate-300">
            <p className="font-semibold text-slate-900 dark:text-white">Boost plan</p>
            <p className="mt-1">Switch on weekly GH₵200 boosts from wallet to hit your target ahead of schedule.</p>
          </div>
          <div className="rounded-2xl bg-slate-50/80 p-4 text-sm text-slate-600 shadow-inner dark:bg-slate-900/60 dark:text-slate-300">
            <p className="font-semibold text-slate-900 dark:text-white">Celebration milestones</p>
            <p className="mt-1">Unlock confetti, badges, and notifications at 25%, 50%, 75%, and 100% completion.</p>
          </div>
        </div>
      </div>

      <section className="grid gap-6 md:grid-cols-2">
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Contribution history</h2>
          <div className="mt-4 space-y-3">
            {goalTransactions.map((transaction) => (
              <div key={transaction.id} className="rounded-2xl border border-slate-200/70 bg-white/80 p-4 dark:border-slate-700 dark:bg-slate-900/70">
                <p className="text-sm font-semibold text-slate-900 dark:text-white">{transaction.type}</p>
                <p className="text-xs text-slate-500 dark:text-slate-400">{transaction.date} • {transaction.channel}</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">GH₵{transaction.amount.toLocaleString()} ({transaction.status})</p>
              </div>
            ))}
          </div>
        </div>
        <div className="space-y-4 rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Boost your goal</h2>
          <div className="space-y-3 text-sm text-slate-600 dark:text-slate-300">
            <p className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <GiftIcon className="mr-2 inline h-5 w-5 text-primary" /> Add GH₵100 top-up this week to stay on track.
            </p>
            <p className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <SparklesIcon className="mr-2 inline h-5 w-5 text-primary" /> Activate automatic boosts for payday celebrations.
            </p>
            <Link to="/app/notifications" className="inline-flex items-center gap-2 text-sm font-semibold text-primary">
              Review celebration receipts →
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
};

export default SavingsDetail;

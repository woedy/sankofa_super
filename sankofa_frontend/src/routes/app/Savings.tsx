import { Link } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { ArrowUpRightIcon, CalendarDaysIcon, TrendingUpIcon, PlusIcon } from 'lucide-react';
import { savingsService } from '../../services/savingsService';
import type { SavingsGoal } from '../../lib/types';

const Savings = () => {
  const [savingsGoals, setSavingsGoals] = useState<SavingsGoal[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);

  useEffect(() => {
    loadSavingsGoals();
  }, []);

  const loadSavingsGoals = async () => {
    try {
      const data = await savingsService.getSavingsGoals();
      setSavingsGoals(data);
    } catch (error) {
      console.error('Failed to load savings goals:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-center">
          <div className="mb-4 h-12 w-12 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
          <p className="text-sm text-slate-600 dark:text-slate-400">Loading savings goals...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-widest text-primary">Savings goals</p>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Stay on track</h1>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              Monitor progress, celebrate milestones, and launch boosts exactly like the mobile app flow.
            </p>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="inline-flex items-center gap-2 rounded-2xl bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground shadow-lg transition hover:bg-primary/90"
          >
            <PlusIcon size={16} />
            New Goal
          </button>
        </div>
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
                <CalendarDaysIcon size={16} /> Target date {new Date(goal.targetDate).toLocaleDateString()}
              </p>
              <div className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-primary">
                View details <ArrowUpRightIcon size={16} />
              </div>
            </Link>
          );
        })}
      </div>

      {savingsGoals.length === 0 && (
        <div className="rounded-3xl border border-slate-200 bg-white p-12 text-center dark:border-slate-800 dark:bg-slate-900">
          <p className="text-slate-600 dark:text-slate-400">No savings goals yet. Create your first goal to get started!</p>
        </div>
      )}

      {showCreateModal && (
        <CreateGoalModal
          onClose={() => setShowCreateModal(false)}
          onSuccess={() => {
            setShowCreateModal(false);
            loadSavingsGoals();
          }}
        />
      )}
    </div>
  );
};

const CreateGoalModal = ({ onClose, onSuccess }: { onClose: () => void; onSuccess: () => void }) => {
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    targetAmount: '',
    targetDate: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await savingsService.createSavingsGoal(
        formData.name,
        parseFloat(formData.targetAmount),
        formData.category,
        formData.targetDate || undefined
      );
      onSuccess();
    } catch (err: any) {
      setError(err.message || 'Failed to create savings goal');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900">
        <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Create Savings Goal</h2>
        <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">Set a target and start saving towards your goal.</p>

        {error && (
          <div className="mt-4 rounded-2xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label className="block text-sm font-semibold text-slate-900 dark:text-white">Goal Name</label>
            <input
              type="text"
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
              placeholder="e.g., Emergency Fund"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-slate-900 dark:text-white">Category</label>
            <select
              required
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
            >
              <option value="">Select category</option>
              <option value="emergency">Emergency Fund</option>
              <option value="education">Education</option>
              <option value="business">Business</option>
              <option value="travel">Travel</option>
              <option value="housing">Housing</option>
              <option value="other">Other</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-semibold text-slate-900 dark:text-white">Target Amount (GH₵)</label>
            <input
              type="number"
              required
              min="1"
              step="0.01"
              value={formData.targetAmount}
              onChange={(e) => setFormData({ ...formData, targetAmount: e.target.value })}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
              placeholder="1000"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-slate-900 dark:text-white">Target Date</label>
            <input
              type="date"
              required
              value={formData.targetDate}
              onChange={(e) => setFormData({ ...formData, targetDate: e.target.value })}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
            />
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              disabled={loading}
              className="flex-1 rounded-2xl border border-slate-200 bg-white px-6 py-3 text-sm font-semibold text-slate-900 transition hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900 dark:text-white dark:hover:bg-slate-800"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 rounded-2xl bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground shadow-lg transition hover:bg-primary/90 disabled:opacity-50"
            >
              {loading ? 'Creating...' : 'Create Goal'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default Savings;

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { PlusIcon, XIcon, ArrowLeftIcon } from 'lucide-react';
import { groupService } from '../../services/groupService';

interface Invite {
  id: string;
  name: string;
  phoneNumber: string;
}

const CreateGroup = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    contributionAmount: '',
    frequency: 'weekly',
    startDate: '',
  });
  const [invites, setInvites] = useState<Invite[]>([]);
  const [newInvite, setNewInvite] = useState({ name: '', phoneNumber: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const addInvite = () => {
    if (!newInvite.name.trim() || !newInvite.phoneNumber.trim()) {
      setError('Please enter both name and phone number for the invite');
      return;
    }

    const invite: Invite = {
      id: Date.now().toString(),
      name: newInvite.name.trim(),
      phoneNumber: newInvite.phoneNumber.trim(),
    };

    setInvites([...invites, invite]);
    setNewInvite({ name: '', phoneNumber: '' });
    setError('');
  };

  const removeInvite = (id: string) => {
    setInvites(invites.filter(inv => inv.id !== id));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (invites.length === 0) {
      setError('Please add at least one member to invite');
      return;
    }

    setLoading(true);

    try {
      await groupService.createGroup({
        name: formData.name,
        description: formData.description || undefined,
        contributionAmount: parseFloat(formData.contributionAmount),
        frequency: formData.frequency,
        startDate: formData.startDate,
        invites: invites.map(inv => ({
          name: inv.name,
          phoneNumber: inv.phoneNumber,
        })),
      });

      navigate('/app/groups');
    } catch (err: any) {
      setError(err.message || 'Failed to create group');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <header className="flex items-center gap-4">
        <button
          onClick={() => navigate('/app/groups')}
          className="rounded-2xl border border-slate-200 bg-white p-3 transition hover:bg-slate-50 dark:border-slate-700 dark:bg-slate-900 dark:hover:bg-slate-800"
        >
          <ArrowLeftIcon size={20} />
        </button>
        <div>
          <p className="text-sm font-semibold uppercase tracking-widest text-primary">New Group</p>
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Create a susu circle</h1>
        </div>
      </header>

      {error && (
        <div className="rounded-2xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Group Details</h2>
          <div className="mt-4 space-y-4">
            <div>
              <label className="block text-sm font-semibold text-slate-900 dark:text-white">Group Name</label>
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                placeholder="e.g., Family Savings Circle"
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-slate-900 dark:text-white">Purpose (optional)</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                placeholder="What is this group saving for?"
                rows={3}
              />
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="block text-sm font-semibold text-slate-900 dark:text-white">Contribution Amount (GH₵)</label>
                <input
                  type="number"
                  required
                  min="1"
                  step="0.01"
                  value={formData.contributionAmount}
                  onChange={(e) => setFormData({ ...formData, contributionAmount: e.target.value })}
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                  placeholder="100"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-900 dark:text-white">Frequency</label>
                <select
                  required
                  value={formData.frequency}
                  onChange={(e) => setFormData({ ...formData, frequency: e.target.value })}
                  className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="biweekly">Bi-weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-semibold text-slate-900 dark:text-white">Start Date</label>
              <input
                type="date"
                required
                value={formData.startDate}
                onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
                className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
              />
            </div>
          </div>
        </div>

        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Invite Members</h2>
          <p className="mt-1 text-sm text-slate-600 dark:text-slate-400">
            Add at least one member to start your group. You'll be added automatically as the creator.
          </p>

          <div className="mt-4 space-y-4">
            <div className="grid gap-4 md:grid-cols-[1fr_1fr_auto]">
              <input
                type="text"
                value={newInvite.name}
                onChange={(e) => setNewInvite({ ...newInvite, name: e.target.value })}
                className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                placeholder="Member name"
              />
              <input
                type="tel"
                value={newInvite.phoneNumber}
                onChange={(e) => setNewInvite({ ...newInvite, phoneNumber: e.target.value })}
                className="rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                placeholder="Phone number"
              />
              <button
                type="button"
                onClick={addInvite}
                className="inline-flex items-center gap-2 rounded-2xl bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90"
              >
                <PlusIcon size={16} />
                Add
              </button>
            </div>

            {invites.length > 0 && (
              <div className="space-y-2">
                <p className="text-sm font-semibold text-slate-900 dark:text-white">
                  Members to invite ({invites.length})
                </p>
                {invites.map((invite) => (
                  <div
                    key={invite.id}
                    className="flex items-center justify-between rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 dark:border-slate-700 dark:bg-slate-900/60"
                  >
                    <div>
                      <p className="font-semibold text-slate-900 dark:text-white">{invite.name}</p>
                      <p className="text-sm text-slate-600 dark:text-slate-400">{invite.phoneNumber}</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => removeInvite(invite.id)}
                      className="rounded-full p-2 text-red-600 transition hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-900/20"
                    >
                      <XIcon size={16} />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="flex gap-3">
          <button
            type="button"
            onClick={() => navigate('/app/groups')}
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
            {loading ? 'Creating...' : 'Create Group'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default CreateGroup;

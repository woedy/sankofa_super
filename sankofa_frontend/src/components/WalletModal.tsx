import { useState } from 'react';
import { XIcon } from 'lucide-react';
import { walletService } from '../services/walletService';
import { useAuth } from '../contexts/AuthContext';

interface WalletModalProps {
  type: 'deposit' | 'withdrawal';
  onClose: () => void;
  onSuccess: () => void;
}

const WalletModal = ({ type, onClose, onSuccess }: WalletModalProps) => {
  const { refreshUser } = useAuth();
  const [formData, setFormData] = useState({
    amount: '',
    channel: 'momo',
    phoneNumber: '',
    description: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const amount = parseFloat(formData.amount);
      
      if (type === 'deposit') {
        await walletService.deposit(
          amount,
          formData.channel,
          undefined, // reference
          undefined, // fee
          formData.description || undefined,
          formData.phoneNumber || undefined // counterparty
        );
      } else {
        await walletService.withdraw(
          amount,
          'pending', // status
          formData.channel,
          undefined, // reference
          undefined, // fee
          formData.description || undefined,
          formData.phoneNumber || undefined // counterparty
        );
      }

      // Refresh user data to update wallet balance
      await refreshUser();
      onSuccess();
    } catch (err: any) {
      setError(err.message || `Failed to ${type} funds`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white capitalize">
            {type} Funds
          </h2>
          <button
            onClick={onClose}
            className="rounded-full p-2 transition hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <XIcon size={20} />
          </button>
        </div>
        <p className="mt-2 text-sm text-slate-600 dark:text-slate-400">
          {type === 'deposit' 
            ? 'Add money to your Sankofa wallet' 
            : 'Withdraw money from your wallet to mobile money'}
        </p>

        {error && (
          <div className="mt-4 rounded-2xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label className="block text-sm font-semibold text-slate-900 dark:text-white">
              Amount (GH₵)
            </label>
            <input
              type="number"
              required
              min="1"
              step="0.01"
              value={formData.amount}
              onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
              placeholder="100.00"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-slate-900 dark:text-white">
              Payment Channel
            </label>
            <select
              required
              value={formData.channel}
              onChange={(e) => setFormData({ ...formData, channel: e.target.value })}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
            >
              <option value="momo">Mobile Money (MTN/Vodafone/AirtelTigo)</option>
              <option value="card">Card Payment</option>
              <option value="bank">Bank Transfer</option>
            </select>
          </div>

          {formData.channel === 'momo' && (
            <div>
              <label className="block text-sm font-semibold text-slate-900 dark:text-white">
                Mobile Money Number
              </label>
              <input
                type="tel"
                required
                value={formData.phoneNumber}
                onChange={(e) => setFormData({ ...formData, phoneNumber: e.target.value })}
                className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                placeholder="0244123456"
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-semibold text-slate-900 dark:text-white">
              Description (optional)
            </label>
            <input
              type="text"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="mt-2 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-slate-900 focus:border-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-white"
              placeholder="e.g., Monthly savings"
            />
          </div>

          <div className="flex gap-3 pt-2">
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
              {loading ? 'Processing...' : `${type === 'deposit' ? 'Deposit' : 'Withdraw'}`}
            </button>
          </div>
        </form>

        <div className="mt-4 rounded-2xl bg-slate-50 p-4 text-xs text-slate-600 dark:bg-slate-900/60 dark:text-slate-400">
          <p className="font-semibold">Note:</p>
          <p className="mt-1">
            {type === 'deposit' 
              ? 'You will receive a prompt on your phone to authorize this transaction.'
              : 'Withdrawals are processed within 24 hours to your mobile money account.'}
          </p>
        </div>
      </div>
    </div>
  );
};

export default WalletModal;

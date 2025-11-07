import { Link } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { ArrowRightIcon, GiftIcon, PhoneCallIcon, PlusCircleIcon, ShieldCheckIcon } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';
import { groupService } from '../../services/groupService';
import { savingsService } from '../../services/savingsService';
import { transactionService } from '../../services/transactionService';
import { notificationService } from '../../services/notificationService';
import WalletModal from '../../components/WalletModal';
import type { SusuGroup, SavingsGoal, Transaction, Notification } from '../../lib/types';
import { processFlows } from '../../assets/data/mockData';

const Home = () => {
  const { user } = useAuth();
  const [groups, setGroups] = useState<SusuGroup[]>([]);
  const [savingsGoals, setSavingsGoals] = useState<SavingsGoal[]>([]);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [walletModal, setWalletModal] = useState<'deposit' | 'withdrawal' | null>(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [groupsData, goalsData, transactionsData, notificationsData] = await Promise.all([
        groupService.getGroups(),
        savingsService.getSavingsGoals(),
        transactionService.getTransactions(),
        notificationService.getNotifications(),
      ]);
      setGroups(groupsData.slice(0, 2)); // Show top 2
      setSavingsGoals(goalsData);
      setTransactions(transactionsData.slice(0, 3)); // Show top 3
      setNotifications(notificationsData.slice(0, 3)); // Show top 3
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  };

  const quickActions = [
    { label: 'Deposit funds', icon: PlusCircleIcon, onClick: () => setWalletModal('deposit'), description: 'Top up wallet' },
    { label: 'Request payout', icon: GiftIcon, onClick: () => setWalletModal('withdrawal'), description: 'Schedule withdrawal' },
    { label: 'Contact support', icon: PhoneCallIcon, to: '/app/support', description: 'Chat with an agent' }
  ];

  const savingsTotal = savingsGoals.reduce((sum, goal) => sum + goal.savedAmount, 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-center">
          <div className="mb-4 h-12 w-12 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
          <p className="text-sm text-slate-600 dark:text-slate-400">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <section className="grid gap-6 rounded-3xl border border-slate-200 bg-white p-8 shadow-xl shadow-primary/10 dark:border-slate-800 dark:bg-slate-900 md:grid-cols-[1.1fr_0.9fr]">
        <div className="space-y-6">
          <div className="flex flex-wrap items-center gap-4">
            <div>
              <p className="text-sm font-semibold uppercase tracking-widest text-primary">Wallet snapshot</p>
              <h2 className="mt-2 text-3xl font-bold text-slate-900 dark:text-white">GH₵{user?.walletBalance.toLocaleString() || '0'}</h2>
            </div>
            <span className="rounded-full bg-emerald-500/10 px-3 py-1 text-sm font-medium text-emerald-600 dark:bg-emerald-500/20 dark:text-emerald-300">
              {user?.kycStatus === 'verified' ? 'Verified' : user?.kycStatus || 'Pending'}
            </span>
          </div>
          <p className="text-sm text-slate-600 dark:text-slate-300">
            Keep tabs on your wallet, upcoming payouts, and savings milestones. Quick actions mirror the mobile quick action rail.
          </p>
          <div className="flex flex-wrap gap-3">
            {quickActions.map((action) => (
              action.to ? (
                <Link
                  key={action.label}
                  to={action.to}
                  className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-900 shadow-sm transition hover:-translate-y-0.5 hover:border-primary hover:shadow-lg dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                >
                  <action.icon size={20} className="text-primary" />
                  <div className="text-left">
                    <p>{action.label}</p>
                    <p className="text-xs font-normal text-slate-500 dark:text-slate-400">{action.description}</p>
                  </div>
                </Link>
              ) : (
                <button
                  key={action.label}
                  onClick={action.onClick}
                  className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-900 shadow-sm transition hover:-translate-y-0.5 hover:border-primary hover:shadow-lg dark:border-slate-700 dark:bg-slate-900 dark:text-white"
                >
                  <action.icon size={20} className="text-primary" />
                  <div className="text-left">
                    <p>{action.label}</p>
                    <p className="text-xs font-normal text-slate-500 dark:text-slate-400">{action.description}</p>
                  </div>
                </button>
              )
            ))}
          </div>
        </div>
        <div className="rounded-3xl bg-gradient-to-br from-primary via-primary-dark to-slate-900 p-8 text-primary-foreground shadow-2xl">
          <p className="text-sm uppercase tracking-widest text-primary-foreground/70">Savings milestones</p>
          <h3 className="mt-3 text-2xl font-bold">GH₵{savingsTotal.toLocaleString()} saved so far</h3>
          <p className="mt-3 text-sm text-primary-foreground/80">
            Boost your goals faster with auto-contributions and community accountability from your susu groups.
          </p>
          <div className="mt-6 space-y-4">
            {savingsGoals.map((goal) => {
              const progress = Math.round((goal.savedAmount / goal.targetAmount) * 100);
              return (
                <div key={goal.id} className="space-y-2 rounded-2xl bg-white/10 p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-semibold">{goal.name}</p>
                      <p className="text-xs text-primary-foreground/70">Target GH₵{goal.targetAmount.toLocaleString()}</p>
                    </div>
                    <span className="text-sm font-semibold">{progress}%</span>
                  </div>
                  <div className="h-2 rounded-full bg-white/20">
                    <div className="h-2 rounded-full bg-accent" style={{ width: `${progress}%` }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <section className="grid gap-6 md:grid-cols-2">
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Active groups</h3>
            <Link to="/app/groups" className="text-sm font-semibold text-primary hover:underline">
              View all
            </Link>
          </div>
          <div className="mt-4 space-y-4">
            {groups.map((group) => (
              <Link
                key={group.id}
                to={`/app/groups/${group.id}`}
                className="flex gap-4 rounded-2xl border border-slate-200/70 bg-white/70 p-4 transition hover:-translate-y-0.5 hover:border-primary dark:border-slate-700 dark:bg-slate-900/70"
              >
                <div className="h-14 w-14 flex-shrink-0 overflow-hidden rounded-2xl">
                  <img src={group.heroImage} alt={group.name} className="h-full w-full object-cover" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-slate-900 dark:text-white">{group.name}</p>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{group.totalMembers} members • GH₵{group.contributionAmount} {group.contributionFrequency}</p>
                  <p className="mt-1 text-xs text-primary">
                    {group.nextPayoutDate ? `Next payout: ${new Date(group.nextPayoutDate).toLocaleDateString()}` : 'No payout scheduled'} ({group.cycleStatus})
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Latest transactions</h3>
            <Link to="/app/transactions" className="text-sm font-semibold text-primary hover:underline">
              View history
            </Link>
          </div>
          <div className="mt-4 space-y-4">
            {transactions.map((transaction) => (
              <div key={transaction.id} className="flex items-center justify-between rounded-2xl border border-slate-200/70 bg-white/70 p-4 dark:border-slate-700 dark:bg-slate-900/70">
                <div>
                  <p className="text-sm font-semibold text-slate-900 dark:text-white capitalize">{transaction.type}</p>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{new Date(transaction.createdAt).toLocaleDateString()} • {transaction.channel || 'N/A'}</p>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-slate-900 dark:text-white">GH₵{transaction.amount.toLocaleString()}</p>
                  <p className="text-xs text-primary">{transaction.status}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="grid gap-6 md:grid-cols-[1.2fr_0.8fr]">
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Process walkthroughs</h3>
            <Link to="/app/support" className="text-sm font-semibold text-primary hover:underline">
              View guides
            </Link>
          </div>
          <div className="mt-4 space-y-4">
            {processFlows.map((flow) => (
              <div key={flow.id} className="rounded-2xl border border-slate-200/70 bg-white/70 p-4 dark:border-slate-700 dark:bg-slate-900/70">
                <p className="text-sm font-semibold text-slate-900 dark:text-white">{flow.name}</p>
                <p className="mt-2 text-xs text-slate-500 dark:text-slate-400">{flow.description}</p>
                <div className="mt-3 flex flex-wrap gap-2 text-xs text-primary">
                  {flow.steps.map((step) => (
                    <span key={step} className="rounded-full bg-primary/10 px-3 py-1">
                      {step}
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Recent notifications</h3>
          <div className="mt-4 space-y-4">
            {notifications.map((notification) => (
              <div key={notification.id} className="rounded-2xl border border-slate-200/70 bg-white/70 p-4 dark:border-slate-700 dark:bg-slate-900/70">
                <p className="text-sm font-semibold text-slate-900 dark:text-white">{notification.title}</p>
                <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{new Date(notification.createdAt).toLocaleDateString()}</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{notification.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="flex flex-col gap-4 rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center gap-4">
          <div className="rounded-2xl bg-primary/10 p-3 text-primary">
            <ShieldCheckIcon className="h-8 w-8" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Stay protected</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              Enable biometrics and transaction PINs in your profile to mirror the secure defaults of the mobile app.
            </p>
          </div>
        </div>
        <Link to="/app/profile" className="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline">
          Manage security
          <ArrowRightIcon size={16} />
        </Link>
      </section>

      {walletModal && (
        <WalletModal
          type={walletModal}
          onClose={() => setWalletModal(null)}
          onSuccess={() => {
            setWalletModal(null);
            loadData(); // Reload data to show updated transactions
          }}
        />
      )}
    </div>
  );
};

export default Home;

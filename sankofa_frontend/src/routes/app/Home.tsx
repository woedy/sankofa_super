import { Link } from 'react-router-dom';
import {
  memberProfile,
  groups,
  savingsGoals,
  transactions,
  notifications,
  processFlows
} from '../../assets/data/mockData';
import { ArrowRightIcon, GiftIcon, PhoneCallIcon, PlusCircleIcon, ShieldCheckIcon } from 'lucide-react';

const Home = () => {
  const quickActions = [
    { label: 'Deposit funds', icon: PlusCircleIcon, to: '/app/transactions', description: 'Top up wallet' },
    { label: 'Request payout', icon: GiftIcon, to: '/app/transactions', description: 'Schedule withdrawal' },
    { label: 'Contact support', icon: PhoneCallIcon, to: '/app/support', description: 'Chat with an agent' }
  ];

  return (
    <div className="space-y-8">
      <section className="grid gap-6 rounded-3xl border border-slate-200 bg-white p-8 shadow-xl shadow-primary/10 dark:border-slate-800 dark:bg-slate-900 md:grid-cols-[1.1fr_0.9fr]">
        <div className="space-y-6">
          <div className="flex flex-wrap items-center gap-4">
            <div>
              <p className="text-sm font-semibold uppercase tracking-widest text-primary">Wallet snapshot</p>
              <h2 className="mt-2 text-3xl font-bold text-slate-900 dark:text-white">GH₵{memberProfile.walletBalance.toLocaleString()}</h2>
            </div>
            <span className="rounded-full bg-emerald-500/10 px-3 py-1 text-sm font-medium text-emerald-600 dark:bg-emerald-500/20 dark:text-emerald-300">
              {memberProfile.kycStatus}
            </span>
          </div>
          <p className="text-sm text-slate-600 dark:text-slate-300">
            Keep tabs on your wallet, upcoming payouts, and savings milestones. Quick actions mirror the mobile quick action rail.
          </p>
          <div className="flex flex-wrap gap-3">
            {quickActions.map((action) => (
              <Link
                key={action.label}
                to={action.to}
                className="group inline-flex items-center gap-3 rounded-2xl border border-slate-200 bg-white/80 px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:-translate-y-0.5 hover:border-primary hover:text-primary dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-200"
              >
                <action.icon className="h-5 w-5 text-primary transition group-hover:scale-110" />
                <div className="text-left">
                  <p>{action.label}</p>
                  <p className="text-xs font-normal text-slate-500 dark:text-slate-400">{action.description}</p>
                </div>
              </Link>
            ))}
          </div>
        </div>
        <div className="rounded-3xl bg-gradient-to-br from-primary via-primary-dark to-slate-900 p-8 text-primary-foreground shadow-2xl">
          <p className="text-sm uppercase tracking-widest text-primary-foreground/70">Savings milestones</p>
          <h3 className="mt-3 text-2xl font-bold">GH₵{memberProfile.savingsTotal.toLocaleString()} saved so far</h3>
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
                  <p className="text-xs text-slate-500 dark:text-slate-400">{group.members} members • GH₵{group.contribution} weekly</p>
                  <p className="mt-1 text-xs text-primary">
                    Next payout: {group.nextPayout} ({group.cycleStatus})
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
                  <p className="text-sm font-semibold text-slate-900 dark:text-white">{transaction.type}</p>
                  <p className="text-xs text-slate-500 dark:text-slate-400">{transaction.date} • {transaction.channel}</p>
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
                <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{notification.time}</p>
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
    </div>
  );
};

export default Home;

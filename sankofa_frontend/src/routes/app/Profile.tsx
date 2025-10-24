import { memberProfile } from '../../assets/data/mockData';
import ThemeToggle from '../../components/ThemeToggle';
import { ShieldCheckIcon, SmartphoneIcon } from 'lucide-react';

const Profile = () => {
  const preferences = [
    { label: 'Language', value: memberProfile.preferences.language },
    { label: 'Biometrics', value: memberProfile.preferences.biometrics ? 'Enabled' : 'Disabled' },
    { label: 'Marketing updates', value: memberProfile.preferences.marketing ? 'Subscribed' : 'Muted' }
  ];

  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <p className="text-sm font-semibold uppercase tracking-widest text-primary">Profile</p>
        <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Account & preferences</h1>
        <p className="text-sm text-slate-600 dark:text-slate-300">
          Review personal info, security posture, and app preferences just like in the mobile profile hub.
        </p>
      </header>

      <section className="grid gap-6 rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900 md:grid-cols-[1.1fr_0.9fr]">
        <div className="space-y-4">
          <div className="flex items-center gap-4">
            <img src={memberProfile.avatar} alt={memberProfile.name} className="h-16 w-16 rounded-full object-cover shadow-lg" />
            <div>
              <h2 className="text-xl font-semibold text-slate-900 dark:text-white">{memberProfile.name}</h2>
              <p className="text-sm text-slate-600 dark:text-slate-300">{memberProfile.phone}</p>
              <span className="mt-2 inline-flex items-center gap-2 rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-600">
                <ShieldCheckIcon size={14} /> {memberProfile.kycStatus}
              </span>
            </div>
          </div>
          <div className="grid gap-4 text-sm text-slate-600 dark:text-slate-300 md:grid-cols-2">
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Tier</p>
              <p>{memberProfile.tier}</p>
            </div>
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Wallet balance</p>
              <p>GH₵{memberProfile.walletBalance.toLocaleString()}</p>
            </div>
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Savings total</p>
              <p>GH₵{memberProfile.savingsTotal.toLocaleString()}</p>
            </div>
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Notifications</p>
              <p>{memberProfile.notificationCount} unread alerts</p>
            </div>
          </div>
        </div>
        <div className="space-y-4 rounded-3xl bg-slate-50/70 p-6 text-sm text-slate-600 dark:bg-slate-900/60 dark:text-slate-300">
          <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Device security</h3>
          <p className="text-sm">Check your trusted devices and biometric status below.</p>
          <div className="space-y-3">
            <div className="rounded-2xl border border-slate-200/70 bg-white/80 p-4 dark:border-slate-700 dark:bg-slate-900/70">
              <p className="flex items-center gap-2 font-semibold text-slate-900 dark:text-white">
                <SmartphoneIcon size={16} /> iPhone 15 Pro
              </p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Face ID active • Last login 2 hours ago</p>
            </div>
            <div className="rounded-2xl border border-slate-200/70 bg-white/80 p-4 dark:border-slate-700 dark:bg-slate-900/70">
              <p className="flex items-center gap-2 font-semibold text-slate-900 dark:text-white">
                <SmartphoneIcon size={16} /> MacBook Air
              </p>
              <p className="text-xs text-slate-500 dark:text-slate-400">Passcode enabled • Last login yesterday</p>
            </div>
          </div>
        </div>
      </section>

      <section className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
        <h3 className="text-lg font-semibold text-slate-900 dark:text-white">Preferences</h3>
        <div className="mt-4 grid gap-4 md:grid-cols-2">
          <div className="flex items-center justify-between rounded-2xl border border-slate-200/70 bg-white/80 px-4 py-3 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
            <span className="font-semibold text-slate-900 dark:text-white">Theme</span>
            <ThemeToggle />
          </div>
          {preferences.map((item) => (
            <div key={item.label} className="flex items-center justify-between rounded-2xl border border-slate-200/70 bg-white/80 px-4 py-3 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
              <span className="font-semibold text-slate-900 dark:text-white">{item.label}</span>
              <span className="text-slate-600 dark:text-slate-300">{item.value}</span>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

export default Profile;

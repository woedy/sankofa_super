import { useNavigate } from 'react-router-dom';
import ThemeToggle from '../../components/ThemeToggle';
import { ShieldCheckIcon, SmartphoneIcon, LogOutIcon } from 'lucide-react';
import { useAuth } from '../../contexts/AuthContext';

const Profile = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/auth/login');
  };

  const preferences = [
    { label: 'Language', value: 'English' },
    { label: 'Biometrics', value: 'Not configured' },
    { label: 'Marketing updates', value: 'Muted' }
  ];

  if (!user) {
    return null;
  }

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
            <div className="h-16 w-16 rounded-full bg-gradient-to-br from-primary to-primary-dark flex items-center justify-center text-2xl font-bold text-white shadow-lg">
              {user.fullName.charAt(0).toUpperCase()}
            </div>
            <div>
              <h2 className="text-xl font-semibold text-slate-900 dark:text-white">{user.fullName}</h2>
              <p className="text-sm text-slate-600 dark:text-slate-300">{user.phoneNumber}</p>
              {user.email && <p className="text-xs text-slate-500 dark:text-slate-400">{user.email}</p>}
              <span className="mt-2 inline-flex items-center gap-2 rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-600 capitalize">
                <ShieldCheckIcon size={14} /> {user.kycStatus}
              </span>
            </div>
          </div>
          <div className="grid gap-4 text-sm text-slate-600 dark:text-slate-300 md:grid-cols-2">
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Member since</p>
              <p>{new Date(user.createdAt).toLocaleDateString()}</p>
            </div>
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Wallet balance</p>
              <p>GH₵{user.walletBalance.toLocaleString()}</p>
            </div>
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Last updated</p>
              <p>{new Date(user.walletUpdatedAt).toLocaleDateString()}</p>
            </div>
            <div className="rounded-2xl bg-slate-50/80 p-4 dark:bg-slate-900/60">
              <p className="font-semibold text-slate-900 dark:text-white">Account status</p>
              <p className="capitalize">{user.kycStatus}</p>
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

      <section className="rounded-3xl border border-red-200 bg-red-50 p-6 dark:border-red-900/30 dark:bg-red-900/10">
        <h3 className="text-lg font-semibold text-red-900 dark:text-red-400">Danger zone</h3>
        <p className="mt-2 text-sm text-red-700 dark:text-red-300">
          Sign out of your account. You'll need to verify your phone number again to sign back in.
        </p>
        <button
          onClick={handleLogout}
          className="mt-4 inline-flex items-center gap-2 rounded-2xl bg-red-600 px-6 py-3 text-sm font-semibold text-white shadow-lg transition hover:bg-red-700"
        >
          <LogOutIcon size={16} />
          Sign out
        </button>
      </section>
    </div>
  );
};

export default Profile;

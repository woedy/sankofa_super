import { notifications } from '../../assets/data/mockData';
import { BellRingIcon, CheckIcon } from 'lucide-react';

const Notifications = () => {
  const today = notifications.filter((notification) => !notification.read);
  const earlier = notifications.filter((notification) => notification.read);

  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <p className="text-sm font-semibold uppercase tracking-widest text-primary">Notifications</p>
        <h1 className="text-3xl font-bold text-slate-900 dark:text-white">Inbox</h1>
        <p className="text-sm text-slate-600 dark:text-slate-300">
          Mirror the mobile experience with Today vs Earlier sections, read states, and inline context.
        </p>
      </header>

      <section className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
        <div className="flex items-center gap-3 text-sm text-slate-600 dark:text-slate-300">
          <BellRingIcon className="h-5 w-5 text-primary" />
          <span>{today.length} unread • {earlier.length} earlier</span>
        </div>
      </section>

      <section className="space-y-6">
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-slate-500 dark:text-slate-400">Today</h2>
          <div className="mt-3 space-y-4">
            {today.map((notification) => (
              <div key={notification.id} className="rounded-3xl border border-primary/30 bg-primary/5 p-6 shadow-lg shadow-primary/10 dark:bg-primary/10">
                <p className="text-sm font-semibold text-slate-900 dark:text-white">{notification.title}</p>
                <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{notification.time}</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{notification.body}</p>
              </div>
            ))}
          </div>
        </div>
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-slate-500 dark:text-slate-400">Earlier</h2>
          <div className="mt-3 space-y-4">
            {earlier.map((notification) => (
              <div key={notification.id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-semibold text-slate-900 dark:text-white">{notification.title}</p>
                  <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-600">
                    <CheckIcon size={14} /> Read
                  </span>
                </div>
                <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{notification.time}</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{notification.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
};

export default Notifications;

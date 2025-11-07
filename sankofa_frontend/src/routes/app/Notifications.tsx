import { useEffect, useState } from 'react';
import { BellRingIcon, CheckIcon, CheckCheckIcon } from 'lucide-react';
import { notificationService } from '../../services/notificationService';
import type { Notification } from '../../lib/types';

const Notifications = () => {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadNotifications();
  }, []);

  const loadNotifications = async () => {
    try {
      const data = await notificationService.getNotifications();
      setNotifications(data);
    } catch (error) {
      console.error('Failed to load notifications:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleMarkAsRead = async (id: string) => {
    try {
      await notificationService.markAsRead(id);
      setNotifications(notifications.map(n => 
        n.id === id ? { ...n, read: true } : n
      ));
    } catch (error) {
      console.error('Failed to mark as read:', error);
    }
  };

  const handleMarkAllAsRead = async () => {
    try {
      await notificationService.markAllAsRead();
      setNotifications(notifications.map(n => ({ ...n, read: true })));
    } catch (error) {
      console.error('Failed to mark all as read:', error);
    }
  };

  const today = notifications.filter((notification) => !notification.read);
  const earlier = notifications.filter((notification) => notification.read);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-center">
          <div className="mb-4 h-12 w-12 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
          <p className="text-sm text-slate-600 dark:text-slate-400">Loading notifications...</p>
        </div>
      </div>
    );
  }

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
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3 text-sm text-slate-600 dark:text-slate-300">
            <BellRingIcon className="h-5 w-5 text-primary" />
            <span>{today.length} unread • {earlier.length} earlier</span>
          </div>
          {today.length > 0 && (
            <button
              onClick={handleMarkAllAsRead}
              className="inline-flex items-center gap-2 rounded-2xl bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90"
            >
              <CheckCheckIcon size={16} />
              Mark all read
            </button>
          )}
        </div>
      </section>

      <section className="space-y-6">
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-slate-500 dark:text-slate-400">Today</h2>
          <div className="mt-3 space-y-4">
            {today.length === 0 ? (
              <div className="rounded-3xl border border-slate-200 bg-white p-12 text-center dark:border-slate-800 dark:bg-slate-900">
                <p className="text-slate-600 dark:text-slate-400">No new notifications</p>
              </div>
            ) : (
              today.map((notification) => (
                <div 
                  key={notification.id} 
                  className="rounded-3xl border border-primary/30 bg-primary/5 p-6 shadow-lg shadow-primary/10 dark:bg-primary/10 cursor-pointer transition hover:border-primary/50"
                  onClick={() => handleMarkAsRead(notification.id)}
                >
                  <p className="text-sm font-semibold text-slate-900 dark:text-white">{notification.title}</p>
                  <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{new Date(notification.createdAt).toLocaleString()}</p>
                  <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{notification.body}</p>
                  <p className="mt-3 text-xs text-primary">Click to mark as read</p>
                </div>
              ))
            )}
          </div>
        </div>
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-slate-500 dark:text-slate-400">Earlier</h2>
          <div className="mt-3 space-y-4">
            {earlier.length === 0 ? (
              <div className="rounded-3xl border border-slate-200 bg-white p-12 text-center dark:border-slate-800 dark:bg-slate-900">
                <p className="text-slate-600 dark:text-slate-400">No earlier notifications</p>
              </div>
            ) : (
              earlier.map((notification) => (
                <div key={notification.id} className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-semibold text-slate-900 dark:text-white">{notification.title}</p>
                    <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-600">
                      <CheckIcon size={14} /> Read
                    </span>
                  </div>
                  <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">{new Date(notification.createdAt).toLocaleString()}</p>
                  <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{notification.body}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </section>
    </div>
  );
};

export default Notifications;

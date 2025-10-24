import { supportArticles } from '../../assets/data/mockData';
import { LifeBuoyIcon, MailIcon, MessageSquareIcon } from 'lucide-react';

const Support = () => {
  return (
    <div className="space-y-6">
      <header className="flex flex-col gap-2">
        <p className="text-sm font-semibold uppercase tracking-widest text-primary">Support centre</p>
        <h1 className="text-3xl font-bold text-slate-900 dark:text-white">How can we help?</h1>
        <p className="text-sm text-slate-600 dark:text-slate-300">
          Search FAQs, contact community managers, or review dispute timelines mirroring the app experience.
        </p>
      </header>

      <section className="rounded-3xl border border-slate-200 bg-white p-6 shadow-lg dark:border-slate-800 dark:bg-slate-900">
        <div className="grid gap-4 md:grid-cols-3">
          <div className="rounded-2xl border border-slate-200/70 bg-white/80 p-4 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
            <p className="flex items-center gap-2 font-semibold text-slate-900 dark:text-white">
              <MessageSquareIcon size={16} /> In-app chat
            </p>
            <p className="mt-1">Live agents Mon–Sat, 8am–9pm GMT.</p>
          </div>
          <div className="rounded-2xl border border-slate-200/70 bg-white/80 p-4 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
            <p className="flex items-center gap-2 font-semibold text-slate-900 dark:text-white">
              <MailIcon size={16} /> Email
            </p>
            <p className="mt-1">support@sankofa.co • 24h response time.</p>
          </div>
          <div className="rounded-2xl border border-slate-200/70 bg-white/80 p-4 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
            <p className="flex items-center gap-2 font-semibold text-slate-900 dark:text-white">
              <LifeBuoyIcon size={16} /> Phone
            </p>
            <p className="mt-1">0800-SANKOFA • Urgent support line.</p>
          </div>
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Guides & FAQs</h2>
        <div className="grid gap-4 md:grid-cols-2">
          {supportArticles.map((article) => (
            <div key={article.id} className="rounded-3xl border border-slate-200 bg-white/80 p-6 shadow-lg transition hover:-translate-y-1 dark:border-slate-800 dark:bg-slate-900/80">
              <p className="text-xs font-semibold uppercase tracking-widest text-primary">{article.category}</p>
              <h3 className="mt-2 text-lg font-semibold text-slate-900 dark:text-white">{article.question}</h3>
              <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{article.answer}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

export default Support;

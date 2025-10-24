import { Link, useNavigate } from 'react-router-dom';
import ThemeToggle from '../components/ThemeToggle';
import PrimaryButton from '../components/PrimaryButton';
import { CheckCircle2, Smartphone, Users, Wallet, ShieldCheck } from 'lucide-react';

const Landing = () => {
  const navigate = useNavigate();

  const highlights = [
    {
      title: 'Mobile & Web, perfectly in sync',
      description: 'Continue your Sankofa journey seamlessly between the Ghana-first mobile app and the new responsive web experience.',
      icon: Smartphone
    },
    {
      title: 'Community-powered savings',
      description: 'Run susu cycles with transparent rosters, contribution receipts, and payout reminders that keep everyone accountable.',
      icon: Users
    },
    {
      title: 'Wallets built for MoMo',
      description: 'Instant deposits and withdrawals with MTN, AirtelTigo, and Vodafone, complete with compliance-ready receipts.',
      icon: Wallet
    },
    {
      title: 'Enterprise-grade safety',
      description: 'Tiered KYC, device security controls, and audit trails that build trust with every transaction.',
      icon: ShieldCheck
    }
  ];

  const steps = [
    'Sign in with your Ghana number',
    'Verify with OTP and submit KYC',
    'Join a susu group and contribute',
    'Track savings, payouts, and receipts'
  ];

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 transition-colors dark:bg-slate-950 dark:text-slate-100">
      <div className="absolute inset-0 -z-10 bg-[length:40px_40px] bg-grid-light opacity-70 dark:bg-grid-dark" />
      <header className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <Link to="/" className="flex items-center gap-2 text-lg font-semibold text-primary">
            <span className="inline-flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground">SF</span>
            Sankofa Cooperative
          </Link>
          <div className="flex items-center gap-4">
            <button onClick={() => navigate('/auth/login')} className="text-sm font-semibold text-slate-600 hover:text-primary dark:text-slate-300">
              Sign in
            </button>
            <ThemeToggle />
          </div>
        </div>
      </header>

      <main className="mx-auto flex max-w-6xl flex-col gap-16 px-4 pb-24">
        <section className="grid gap-12 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
          <div className="space-y-6">
            <span className="inline-flex items-center gap-2 rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
              New • Web experience for members
            </span>
            <h1 className="text-4xl font-bold leading-tight tracking-tight text-slate-900 dark:text-white sm:text-5xl">
              All the power of Sankofa. Now on the web for every member.
            </h1>
            <p className="text-lg text-slate-600 dark:text-slate-300">
              From onboarding to payouts, mirror every flow from the beloved mobile app. Explore a polished web interface with
              demo data, dark mode, and responsive layouts tailored for Ghanaian savings communities.
            </p>
            <div className="flex flex-wrap items-center gap-4">
              <PrimaryButton label="Take the onboarding tour" onClick={() => navigate('/onboarding')} />
              <button onClick={() => navigate('/auth/login')} className="text-sm font-semibold text-primary hover:underline">
                Already a member? Sign in →
              </button>
            </div>
            <div className="rounded-3xl border border-slate-200/70 bg-white/70 p-6 shadow-xl shadow-primary/10 backdrop-blur dark:border-slate-800 dark:bg-slate-900/60">
              <p className="text-sm font-semibold uppercase tracking-wider text-primary">How it works</p>
              <ol className="mt-4 grid gap-3 text-sm text-slate-600 dark:text-slate-300 md:grid-cols-2">
                {steps.map((step, index) => (
                  <li key={step} className="flex items-start gap-2">
                    <CheckCircle2 className="mt-0.5 h-5 w-5 text-accent" />
                    <span>
                      <span className="font-semibold text-slate-800 dark:text-white">Step {index + 1}.</span> {step}
                    </span>
                  </li>
                ))}
              </ol>
            </div>
          </div>
          <div className="relative">
            <div className="absolute -inset-4 rounded-3xl bg-primary/20 blur-3xl dark:bg-primary/30" />
            <div className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-800 dark:bg-slate-900">
              <img
                src="https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&w=1200&q=80"
                alt="Sankofa members collaborating"
                className="h-full w-full object-cover"
              />
            </div>
          </div>
        </section>

        <section className="space-y-10">
          <div className="space-y-3 text-center">
            <p className="text-sm font-semibold uppercase tracking-widest text-primary">Member journeys</p>
            <h2 className="text-3xl font-bold text-slate-900 dark:text-white">Everything from the app. Crafted for desktop too.</h2>
            <p className="mx-auto max-w-3xl text-base text-slate-600 dark:text-slate-300">
              Explore every page from splash, onboarding, login, KYC, wallet, savings, groups, and support. Each screen mirrors the
              mobile flow with tailored layouts and Ghana-first copywriting.
            </p>
          </div>
          <div className="grid gap-6 md:grid-cols-2">
            {highlights.map((item) => (
              <div
                key={item.title}
                className="card-shadow rounded-3xl border border-slate-200 bg-white/80 p-6 transition hover:-translate-y-1 dark:border-slate-800 dark:bg-slate-900/70"
              >
                <item.icon className="mb-4 h-10 w-10 text-primary" />
                <h3 className="text-xl font-semibold text-slate-900 dark:text-white">{item.title}</h3>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{item.description}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-slate-200 bg-white/80 p-10 shadow-2xl dark:border-slate-800 dark:bg-slate-900">
          <div className="grid gap-8 lg:grid-cols-2 lg:items-center">
            <div className="space-y-4">
              <h3 className="text-2xl font-bold text-slate-900 dark:text-white">Stay in sync with the mobile experience</h3>
              <p className="text-base text-slate-600 dark:text-slate-300">
                Use the same demo data, receipt flows, and milestone celebrations across platforms. With responsive design and dark
                mode, members feel at home whether on phone, tablet, or laptop.
              </p>
              <div className="flex flex-wrap gap-3 text-sm text-slate-500 dark:text-slate-400">
                <span className="rounded-full bg-primary/10 px-3 py-1 text-primary">Wallet & cashflow wizards</span>
                <span className="rounded-full bg-primary/10 px-3 py-1 text-primary">Notifications inbox</span>
                <span className="rounded-full bg-primary/10 px-3 py-1 text-primary">Support & FAQ</span>
              </div>
            </div>
            <div className="rounded-3xl border border-slate-200 bg-slate-50/70 p-6 dark:border-slate-800 dark:bg-slate-900/70">
              <h4 className="text-lg font-semibold text-slate-900 dark:text-white">Ready to explore?</h4>
              <p className="mt-3 text-sm text-slate-600 dark:text-slate-300">
                Launch the static demo with seed data and walkthroughs of each Sankofa journey. Perfect for stakeholder reviews or
                onboarding new partners.
              </p>
              <div className="mt-6 flex flex-wrap gap-4">
                <PrimaryButton label="Enter member portal" onClick={() => navigate('/auth/login')} />
                <button onClick={() => navigate('/app/home')} className="text-sm font-semibold text-primary hover:underline">
                  Jump to dashboard →
                </button>
              </div>
            </div>
          </div>
        </section>
      </main>
    </div>
  );
};

export default Landing;

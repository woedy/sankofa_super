import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import ThemeToggle from '../../components/ThemeToggle';
import PrimaryButton from '../../components/PrimaryButton';

const Login = () => {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [stage, setStage] = useState<'phone' | 'otp'>('phone');
  const navigate = useNavigate();

  const submitPhone = (event: FormEvent) => {
    event.preventDefault();
    if (phone.trim().length >= 10) {
      setStage('otp');
    }
  };

  const submitOtp = (event: FormEvent) => {
    event.preventDefault();
    if (otp.length === 6) {
      navigate('/auth/kyc');
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 transition-colors dark:bg-slate-950 dark:text-slate-100">
      <header className="mx-auto flex max-w-4xl items-center justify-between px-4 py-6">
        <Link to="/" className="text-lg font-semibold text-primary">
          Sankofa Sign-in
        </Link>
        <ThemeToggle />
      </header>
      <main className="mx-auto flex max-w-4xl flex-col gap-10 px-4 pb-16">
        <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-800 dark:bg-slate-900">
          <div className="grid gap-0 md:grid-cols-2">
            <div className="space-y-6 p-10">
              <div>
                <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">Secure access</span>
                <h1 className="mt-4 text-3xl font-bold text-slate-900 dark:text-white">{stage === 'phone' ? 'Enter your Ghana number' : 'Enter the 6-digit OTP'}</h1>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">
                  We keep your account safe with OTP verification and biometric-ready settings.
                </p>
              </div>

              {stage === 'phone' ? (
                <form onSubmit={submitPhone} className="space-y-4">
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-200">
                    Mobile number
                    <input
                      type="tel"
                      value={phone}
                      onChange={(event) => setPhone(event.target.value)}
                      placeholder="e.g. 024 123 4567"
                      className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-base text-slate-900 shadow-inner focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/30 dark:border-slate-700 dark:bg-slate-900"
                    />
                  </label>
                  <PrimaryButton label="Send OTP" type="submit" />
                </form>
              ) : (
                <form onSubmit={submitOtp} className="space-y-4">
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-200">
                    Verification code
                    <input
                      type="text"
                      value={otp}
                      onChange={(event) => setOtp(event.target.value.slice(0, 6))}
                      placeholder="••••••"
                      className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-center text-2xl tracking-[0.5em] focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/30 dark:border-slate-700 dark:bg-slate-900"
                    />
                  </label>
                  <PrimaryButton label="Verify & continue" type="submit" />
                  <button type="button" className="text-sm font-semibold text-primary hover:underline" onClick={() => setStage('phone')}>
                    Back to phone number
                  </button>
                </form>
              )}
            </div>
            <div className="relative hidden md:block">
              <img
                src="https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80"
                alt="Member smiling"
                className="h-full w-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-slate-950/70 to-transparent" />
              <div className="absolute bottom-6 left-6 right-6 rounded-3xl bg-white/90 p-6 text-sm text-slate-600 shadow-xl backdrop-blur dark:bg-slate-900/80 dark:text-slate-300">
                <p className="font-semibold text-slate-900 dark:text-white">Security snapshot</p>
                <ul className="mt-3 space-y-2">
                  <li>• Device binding & biometric-ready settings</li>
                  <li>• OTP delivered in under 10 seconds</li>
                  <li>• Real-time fraud monitoring</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-8 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Need help signing in?</h2>
          <div className="mt-4 grid gap-4 text-sm text-slate-600 dark:text-slate-300 md:grid-cols-2">
            <div>
              <p className="font-semibold">No OTP received</p>
              <p className="mt-1">Resend the OTP or contact our support team via WhatsApp for manual verification.</p>
            </div>
            <div>
              <p className="font-semibold">New to Sankofa?</p>
              <p className="mt-1">
                Take the <Link to="/onboarding" className="text-primary hover:underline">guided onboarding</Link> to explore the full member experience.
              </p>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Login;

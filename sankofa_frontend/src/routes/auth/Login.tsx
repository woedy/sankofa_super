import { FormEvent, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import ThemeToggle from '../../components/ThemeToggle';
import PrimaryButton from '../../components/PrimaryButton';
import { authService } from '../../services/authService';
import { useAuth } from '../../contexts/AuthContext';
import { ApiException } from '../../lib/apiException';

const Login = () => {
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [stage, setStage] = useState<'phone' | 'otp'>('phone');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const { login } = useAuth();

  const submitPhone = async (event: FormEvent) => {
    event.preventDefault();
    if (phone.trim().length < 10) {
      setError('Please enter a valid phone number');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await authService.requestOtp(phone, 'login');
      setStage('otp');
    } catch (err) {
      if (err instanceof ApiException) {
        setError(err.message);
      } else {
        setError('Failed to send OTP. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  const submitOtp = async (event: FormEvent) => {
    event.preventDefault();
    if (otp.length !== 6) {
      setError('Please enter a 6-digit OTP');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await login(phone, otp);
      // Check if user needs KYC
      const user = await authService.getStoredUser();
      if (user && user.kycStatus === 'pending') {
        navigate('/auth/kyc');
      } else {
        navigate('/app/home');
      }
    } catch (err) {
      if (err instanceof ApiException) {
        setError(err.message);
      } else {
        setError('Failed to verify OTP. Please try again.');
      }
    } finally {
      setLoading(false);
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
                  {error && (
                    <div className="rounded-2xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400">
                      {error}
                    </div>
                  )}
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-200">
                    Mobile number
                    <input
                      type="tel"
                      value={phone}
                      onChange={(event) => setPhone(event.target.value)}
                      placeholder="e.g. 024 123 4567"
                      disabled={loading}
                      className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-base text-slate-900 shadow-inner focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900"
                    />
                  </label>
                  <PrimaryButton label={loading ? 'Sending...' : 'Send OTP'} type="submit" />
                </form>
              ) : (
                <form onSubmit={submitOtp} className="space-y-4">
                  {error && (
                    <div className="rounded-2xl bg-red-50 p-4 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400">
                      {error}
                    </div>
                  )}
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-200">
                    Verification code
                    <input
                      type="text"
                      value={otp}
                      onChange={(event) => setOtp(event.target.value.slice(0, 6))}
                      placeholder="••••••"
                      disabled={loading}
                      className="mt-2 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-center text-2xl tracking-[0.5em] focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/30 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-900"
                    />
                  </label>
                  <PrimaryButton label={loading ? 'Verifying...' : 'Verify & continue'} type="submit" />
                  <button 
                    type="button" 
                    className="text-sm font-semibold text-primary hover:underline disabled:opacity-50" 
                    onClick={() => { setStage('phone'); setError(null); }}
                    disabled={loading}
                  >
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

import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { onboardingSlides } from '../../assets/data/mockData';
import ThemeToggle from '../../components/ThemeToggle';
import PrimaryButton from '../../components/PrimaryButton';

const Onboarding = () => {
  const [step, setStep] = useState(0);
  const navigate = useNavigate();
  const slide = onboardingSlides[step];

  const next = () => {
    if (step === onboardingSlides.length - 1) {
      navigate('/auth/login');
    } else {
      setStep((prev) => prev + 1);
    }
  };

  const skip = () => navigate('/auth/login');

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 transition-colors dark:bg-slate-950 dark:text-slate-100">
      <header className="mx-auto flex max-w-4xl items-center justify-between px-4 py-6">
        <Link to="/" className="text-lg font-semibold text-primary">
          Sankofa Onboarding
        </Link>
        <div className="flex items-center gap-3 text-sm">
          <button onClick={skip} className="font-semibold text-slate-500 hover:text-primary">
            Skip
          </button>
          <ThemeToggle />
        </div>
      </header>
      <main className="mx-auto flex max-w-4xl flex-1 flex-col gap-8 px-4 pb-16">
        <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-800 dark:bg-slate-900">
          <div className="grid gap-0 md:grid-cols-2">
            <div className="p-8">
              <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
                Step {step + 1} of {onboardingSlides.length}
              </span>
              <h1 className="mt-6 text-3xl font-bold text-slate-900 dark:text-white">{slide.title}</h1>
              <p className="mt-4 text-base text-slate-600 dark:text-slate-300">{slide.description}</p>
              <div className="mt-8 flex flex-wrap items-center gap-4">
                <PrimaryButton label={step === onboardingSlides.length - 1 ? 'Continue to sign in' : 'Next step'} onClick={next} />
                <button className="text-sm font-semibold text-primary hover:underline" onClick={skip}>
                  Skip walkthrough
                </button>
              </div>
              <div className="mt-10 flex gap-2">
                {onboardingSlides.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setStep(index)}
                    className={`h-2.5 flex-1 rounded-full transition ${
                      index <= step ? 'bg-primary' : 'bg-slate-200 dark:bg-slate-700'
                    }`}
                  />
                ))}
              </div>
            </div>
            <div className="relative hidden md:block">
              <img src={slide.image} alt={slide.title} className="h-full w-full object-cover" />
              <div className="absolute inset-0 bg-gradient-to-t from-slate-950/70 to-transparent" />
            </div>
          </div>
        </div>
        <div className="grid gap-4 rounded-3xl border border-slate-200 bg-white p-6 text-sm text-slate-600 shadow-lg dark:border-slate-800 dark:bg-slate-900 dark:text-slate-300 md:grid-cols-2">
          <div>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">What we cover</h2>
            <ul className="mt-2 list-disc space-y-1 pl-5">
              <li>Wallet overview, GH₵ balances, and badges</li>
              <li>How groups cycles and payout rosters work</li>
              <li>Saving goals, boosts, and milestone celebrations</li>
            </ul>
          </div>
          <div>
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Why it matters</h2>
            <ul className="mt-2 list-disc space-y-1 pl-5">
              <li>Transparency for Ghana-focused susu communities</li>
              <li>Confidence in KYC and compliance readiness</li>
              <li>Consistency between mobile app and new web portal</li>
            </ul>
          </div>
        </div>
      </main>
    </div>
  );
};

export default Onboarding;

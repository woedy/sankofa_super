import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import PrimaryButton from '../../components/PrimaryButton';
import ThemeToggle from '../../components/ThemeToggle';

const steps = [
  {
    title: 'Upload Ghana Card',
    description: 'Provide clear photos of the front and back of your Ghana Card or passport.'
  },
  {
    title: 'Confirm personal details',
    description: 'Verify your full name, date of birth, and residential address for compliance.'
  },
  {
    title: 'Review & submit',
    description: 'Double-check everything and submit for a 24-hour verification turnaround.'
  }
];

const KycFlow = () => {
  const [currentStep, setCurrentStep] = useState(0);
  const navigate = useNavigate();

  const next = () => {
    if (currentStep === steps.length - 1) {
      navigate('/app/home');
    } else {
      setCurrentStep((prev) => prev + 1);
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900 transition-colors dark:bg-slate-950 dark:text-slate-100">
      <header className="mx-auto flex max-w-4xl items-center justify-between px-4 py-6">
        <Link to="/" className="text-lg font-semibold text-primary">
          Sankofa KYC
        </Link>
        <ThemeToggle />
      </header>
      <main className="mx-auto flex max-w-4xl flex-col gap-10 px-4 pb-16">
        <div className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl dark:border-slate-800 dark:bg-slate-900">
          <div className="grid gap-0 md:grid-cols-2">
            <div className="p-10">
              <span className="rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
                Step {currentStep + 1} of {steps.length}
              </span>
              <h1 className="mt-6 text-3xl font-bold text-slate-900 dark:text-white">{steps[currentStep].title}</h1>
              <p className="mt-4 text-base text-slate-600 dark:text-slate-300">{steps[currentStep].description}</p>
              <div className="mt-6 space-y-3 rounded-3xl bg-slate-50/80 p-6 text-sm text-slate-600 shadow-inner dark:bg-slate-900/60 dark:text-slate-300">
                <p className="font-semibold text-slate-900 dark:text-white">Verification checklist</p>
                <ul className="space-y-2">
                  <li>• Ghana Card number matches mobile registration</li>
                  <li>• Selfie for liveness check ready</li>
                  <li>• Utility bill or digital address captured</li>
                </ul>
              </div>
              <div className="mt-8 flex flex-wrap gap-4">
                <PrimaryButton label={currentStep === steps.length - 1 ? 'Finish & enter app' : 'Next step'} onClick={next} />
                {currentStep > 0 && (
                  <button
                    className="text-sm font-semibold text-primary hover:underline"
                    onClick={() => setCurrentStep((prev) => prev - 1)}
                  >
                    Back
                  </button>
                )}
              </div>
            </div>
            <div className="space-y-4 bg-gradient-to-br from-primary/10 via-white to-accent/10 p-10 dark:from-primary/30 dark:via-slate-950 dark:to-accent/20">
              <div className="rounded-3xl border border-slate-200 bg-white/80 p-6 shadow-lg dark:border-slate-700 dark:bg-slate-900/70">
                <p className="text-sm font-semibold text-primary">Why KYC matters</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">
                  We protect members, keep regulators confident, and unlock higher wallet limits for you.
                </p>
              </div>
              <div className="rounded-3xl border border-slate-200 bg-white/80 p-6 shadow-lg dark:border-slate-700 dark:bg-slate-900/70">
                <p className="text-sm font-semibold text-primary">Support hours</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">Mon–Sat, 8am–9pm GMT via WhatsApp and in-app chat.</p>
              </div>
              <div className="rounded-3xl border border-slate-200 bg-white/80 p-6 shadow-lg dark:border-slate-700 dark:bg-slate-900/70">
                <p className="text-sm font-semibold text-primary">Preview next steps</p>
                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">After approval, explore wallet, savings, and group dashboards.</p>
              </div>
            </div>
          </div>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-8 shadow-lg dark:border-slate-800 dark:bg-slate-900">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Need an agent?</h2>
          <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">
            Call 0800-SANKOFA or email <span className="font-semibold text-primary">compliance@sankofa.co</span> for any upload challenges.
          </p>
        </div>
      </main>
    </div>
  );
};

export default KycFlow;

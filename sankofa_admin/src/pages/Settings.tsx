import { type ChangeEvent, useEffect, useMemo, useState } from 'react';
import { BookText, Check, Globe2, Languages, Save, Moon, Sun, XCircle } from 'lucide-react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Slider } from '@/components/ui/slider';
import { Textarea } from '@/components/ui/textarea';
import { Separator } from '@/components/ui/separator';
import { Checkbox } from '@/components/ui/checkbox';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { useTheme } from '@/hooks/useTheme';
import { useToast } from '@/hooks/use-toast';
import { platformConfiguration } from '@/lib/mockData';

type PlatformConfiguration = typeof platformConfiguration;

const STORAGE_KEY = 'sankofa-admin-platform-configuration';

const buildConfiguration = (
  seed?: Partial<Omit<PlatformConfiguration, 'notifications'>> & {
    notifications?: {
      templates?: PlatformConfiguration['notifications']['templates'];
    };
  },
): PlatformConfiguration => ({
  fees: {
    ...platformConfiguration.fees,
    ...(seed?.fees ?? {}),
  },
  notifications: {
    catalogue: platformConfiguration.notifications.catalogue,
    templates: {
      ...platformConfiguration.notifications.templates,
      ...(seed?.notifications?.templates ?? {}),
    },
  },
  localization: {
    ...platformConfiguration.localization,
    ...(seed?.localization ?? {}),
  },
});

const languageCatalogue = [
  {
    code: 'en',
    label: 'English',
    previewGreeting: 'Welcome back, Ama! Your dashboard is ready.',
    description: 'Default operating language for statements, toasts, and notifications.',
  },
  {
    code: 'tw',
    label: 'Twi',
    previewGreeting: 'Akwaaba Ama! Wo dashboard no yɛ pɛ.',
    description: 'Member-facing push notifications for Ashanti-region cohorts.',
  },
  {
    code: 'ee',
    label: 'Ewe',
    previewGreeting: 'Woezɔ Ama! Wò dashboard le nu siawo ta.',
    description: 'Susu cycle reminders for Volta regional groups.',
  },
];

export default function Settings() {
  const { theme, toggleTheme } = useTheme();
  const { toast } = useToast();
  const [config, setConfig] = useState<PlatformConfiguration>(() => buildConfiguration());
  const [errors, setErrors] = useState<{ fees?: string; templates?: Record<string, string>; languages?: string }>({});

  useEffect(() => {
    if (typeof window === 'undefined') {
      return;
    }

    const stored = window.localStorage.getItem(STORAGE_KEY);
    if (!stored) {
      return;
    }

    try {
      const parsed = JSON.parse(stored) as Partial<PlatformConfiguration> & {
        notifications?: { templates?: PlatformConfiguration['notifications']['templates'] };
      };
      setConfig(buildConfiguration(parsed));
    } catch (error) {
      console.error('Failed to parse stored configuration', error);
    }
  }, []);

  const languagePreview = useMemo(() => {
    const defaultLanguage = languageCatalogue.find((language) => language.code === config.localization.defaultLanguage);
    if (!defaultLanguage) {
      return languageCatalogue[0];
    }

    return defaultLanguage;
  }, [config.localization.defaultLanguage]);

  const handleFeeChange = (key: keyof PlatformConfiguration['fees']) => (value: number[]) => {
    setConfig((previous) => ({
      ...previous,
      fees: {
        ...previous.fees,
        [key]: Number(value[0].toFixed(1)),
      },
    }));
  };

  const handleTemplateChange = (
    templateKey: keyof PlatformConfiguration['notifications']['templates'],
    field: 'subject' | 'body',
  ) =>
    (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
      const value = event.target.value;
      setConfig((previous) => ({
        ...previous,
        notifications: {
          ...previous.notifications,
          templates: {
            ...previous.notifications.templates,
            [templateKey]: {
              ...previous.notifications.templates[templateKey],
              [field]: value,
            },
          },
        },
      }));
    };

  const handleLanguageToggle = (code: string) => (checked: boolean) => {
    setConfig((previous) => {
      const existing = new Set(previous.localization.supportedLanguages);
      if (checked) {
        existing.add(code);
      } else {
        existing.delete(code);
      }

      const updated = Array.from(existing);
      const defaultLanguage = updated.includes(previous.localization.defaultLanguage)
        ? previous.localization.defaultLanguage
        : updated[0] ?? 'en';

      return {
        ...previous,
        localization: {
          ...previous.localization,
          supportedLanguages: updated,
          defaultLanguage,
        },
      };
    });
  };

  const handleDefaultLanguageChange = (value: string) => {
    setConfig((previous) => ({
      ...previous,
      localization: {
        ...previous.localization,
        defaultLanguage: value,
      },
    }));
  };

  const validateConfiguration = () => {
    const templateErrors: Record<string, string> = {};
    Object.entries(config.notifications.templates).forEach(([key, template]) => {
      if (!template.subject.trim()) {
        templateErrors[key] = 'Subject is required.';
        return;
      }

      if (template.body.trim().length < 40) {
        templateErrors[key] = 'Body copy must include at least 40 characters for context.';
      }
    });

    const updatedErrors: typeof errors = {};

    if (config.fees.withdrawal < config.fees.deposit) {
      updatedErrors.fees = 'Withdrawal fees must stay equal to or higher than deposit fees to cover risk reviews.';
    } else if (config.fees.deposit + config.fees.withdrawal > 12) {
      updatedErrors.fees = 'Combined deposit and withdrawal fees cannot exceed 12% based on policy thresholds.';
    }

    if (Object.keys(templateErrors).length > 0) {
      updatedErrors.templates = templateErrors;
    }

    if (config.localization.supportedLanguages.length === 0) {
      updatedErrors.languages = 'Select at least one supported language.';
    } else if (!config.localization.supportedLanguages.includes(config.localization.defaultLanguage)) {
      updatedErrors.languages = 'Choose a default language from the supported options.';
    }

    setErrors(updatedErrors);

    return Object.keys(updatedErrors).length === 0;
  };

  const handleSave = () => {
    const isValid = validateConfiguration();
    if (!isValid) {
      toast({
        title: 'Unable to save settings',
        description: 'Review the highlighted fields and try again.',
        variant: 'destructive',
      });
      return;
    }

    if (typeof window !== 'undefined') {
      const payload = {
        fees: config.fees,
        notifications: { templates: config.notifications.templates },
        localization: config.localization,
      };
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    }

    toast({
      title: 'Settings saved',
      description: 'Configuration updates now reflect across dashboards, notifications, and localization previews.',
    });
  };

  const handleReset = () => {
    setConfig(buildConfiguration());
    setErrors({});
    if (typeof window !== 'undefined') {
      window.localStorage.removeItem(STORAGE_KEY);
    }
    toast({
      title: 'Defaults restored',
      description: 'Reverted to the recommended baseline configuration from the product playbook.',
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold text-foreground">Settings</h2>
        <p className="text-muted-foreground">Tune platform levers for fees, notifications, localization, and theming</p>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Transaction &amp; Savings Fees</CardTitle>
          <CardDescription>
            Adjust live fee policies for deposits, withdrawals, and goal boosts. Updates surface across the dashboard and
            cashflow queues.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-6 md:grid-cols-3">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="deposit-fee" className="text-sm font-medium">
                  Deposit fee ({config.fees.deposit.toFixed(1)}%)
                </Label>
                <BadgePill label="Member-facing" />
              </div>
              <Slider
                id="deposit-fee"
                defaultValue={[config.fees.deposit]}
                value={[config.fees.deposit]}
                onValueChange={handleFeeChange('deposit')}
                min={0}
                max={6}
                step={0.1}
              />
              <p className="text-xs text-muted-foreground">
                Applied to mobile deposits and reflected in member receipts.
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="withdrawal-fee" className="text-sm font-medium">
                  Withdrawal fee ({config.fees.withdrawal.toFixed(1)}%)
                </Label>
                <BadgePill label="Compliance hold" />
              </div>
              <Slider
                id="withdrawal-fee"
                defaultValue={[config.fees.withdrawal]}
                value={[config.fees.withdrawal]}
                onValueChange={handleFeeChange('withdrawal')}
                min={0}
                max={8}
                step={0.1}
              />
              <p className="text-xs text-muted-foreground">
                Covers payout processing and fraud checks before release.
              </p>
            </div>

            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="savings-fee" className="text-sm font-medium">
                  Savings boost fee ({config.fees.savingsBoost.toFixed(1)}%)
                </Label>
                <BadgePill label="Goal accelerator" />
              </div>
              <Slider
                id="savings-fee"
                defaultValue={[config.fees.savingsBoost]}
                value={[config.fees.savingsBoost]}
                onValueChange={handleFeeChange('savingsBoost')}
                min={0}
                max={5}
                step={0.1}
              />
              <p className="text-xs text-muted-foreground">
                Optional accelerator fee for members boosting savings goals.
              </p>
            </div>
          </div>

          <div className="grid gap-6 md:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="payout-buffer" className="text-sm font-medium">
                Payout buffer days ({config.fees.payoutBufferDays} day{config.fees.payoutBufferDays === 1 ? '' : 's'})
              </Label>
              <Slider
                id="payout-buffer"
                defaultValue={[config.fees.payoutBufferDays]}
                value={[config.fees.payoutBufferDays]}
                onValueChange={handleFeeChange('payoutBufferDays')}
                min={0}
                max={7}
                step={1}
              />
              <p className="text-xs text-muted-foreground">
                Hold payouts for the configured number of days before releasing to members.
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="audit-threshold" className="text-sm font-medium">
                Manual review threshold (GH₵ {config.fees.manualReviewThreshold.toLocaleString()})
              </Label>
              <Slider
                id="audit-threshold"
                defaultValue={[config.fees.manualReviewThreshold]}
                value={[config.fees.manualReviewThreshold]}
                onValueChange={handleFeeChange('manualReviewThreshold')}
                min={500}
                max={5000}
                step={50}
              />
              <p className="text-xs text-muted-foreground">
                Transactions above this limit route through the compliance cashflow queue.
              </p>
            </div>
          </div>

          {errors.fees ? (
            <div className="flex items-center gap-2 rounded-md border border-destructive/40 bg-destructive/10 px-3 py-2 text-sm text-destructive">
              <XCircle className="h-4 w-4" aria-hidden />
              <span>{errors.fees}</span>
            </div>
          ) : (
            <div className="flex items-center gap-2 rounded-md border border-primary/30 bg-primary/5 px-3 py-2 text-xs text-primary">
              <Check className="h-4 w-4" aria-hidden />
              <span>Fees stay within the compliance guardrails defined in the mobile playbook.</span>
            </div>
          )}
        </CardContent>
        <CardFooter className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="text-xs text-muted-foreground">
            Saving applies across dashboard KPIs, cashflow queues, and receipts instantly.
          </div>
          <div className="flex w-full flex-col gap-2 sm:w-auto sm:flex-row">
            <Button variant="outline" className="w-full sm:w-auto" onClick={handleReset}>
              Reset to defaults
            </Button>
            <Button className="w-full sm:w-auto" onClick={handleSave}>
              <Save className="mr-2 h-4 w-4" />
              Save configuration
            </Button>
          </div>
        </CardFooter>
      </Card>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Notification Templates</CardTitle>
          <CardDescription>
            Edit the templates powering cashflow alerts, payout reminders, and savings milestone nudges with live previews.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-10">
          {Object.entries(config.notifications.templates).map(([key, template]) => {
            const templateError = errors.templates?.[key];
            const templateMeta =
              config.notifications.catalogue[
                key as keyof PlatformConfiguration['notifications']['templates']
              ];
            const Icon = templateMeta.icon;
            return (
              <div key={key} className="grid gap-6 lg:grid-cols-[1fr_0.9fr]">
                <div className="space-y-4">
                  <div className="flex items-center gap-2">
                    <BookText className="h-4 w-4 text-primary" aria-hidden />
                    <div>
                      <h3 className="text-sm font-semibold text-foreground">{templateMeta.title}</h3>
                      <p className="text-xs text-muted-foreground">{templateMeta.description}</p>
                    </div>
                  </div>
                  <div className="space-y-3">
                    <div className="space-y-2">
                      <Label htmlFor={`${key}-subject`} className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
                        Subject line
                      </Label>
                      <Input
                        id={`${key}-subject`}
                        value={template.subject}
                        onChange={handleTemplateChange(key as keyof PlatformConfiguration['notifications']['templates'], 'subject')}
                        placeholder={templateMeta.subjectPlaceholder}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor={`${key}-body`} className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
                        Body copy
                      </Label>
                      <Textarea
                        id={`${key}-body`}
                        value={template.body}
                        onChange={handleTemplateChange(key as keyof PlatformConfiguration['notifications']['templates'], 'body')}
                        rows={5}
                        placeholder={templateMeta.bodyPlaceholder}
                      />
                    </div>
                  </div>
                  {templateError ? (
                    <div className="flex items-center gap-2 text-sm text-destructive">
                      <XCircle className="h-4 w-4" aria-hidden />
                      <span>{templateError}</span>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      <Check className="h-4 w-4 text-emerald-500" aria-hidden />
                      <span>Template meets notification readiness requirements.</span>
                    </div>
                  )}
                </div>
                <Card className="shadow-custom-sm bg-muted/40">
                  <CardHeader className="space-y-1">
                    <CardTitle className="flex items-center gap-2 text-sm font-semibold">
                      <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-primary">
                        <Icon className="h-4 w-4" aria-hidden />
                      </span>
                      {templateMeta.previewTitle}
                    </CardTitle>
                    <CardDescription className="text-xs text-muted-foreground">
                      Preview of the operator-facing notification after saving.
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-2 text-sm">
                    <p className="font-semibold text-foreground">{template.subject || templateMeta.subjectPlaceholder}</p>
                    <Separator className="bg-border" />
                    <p className="whitespace-pre-line text-muted-foreground">
                      {template.body || templateMeta.bodyPlaceholder}
                    </p>
                  </CardContent>
                </Card>
              </div>
            );
          })}
        </CardContent>
      </Card>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Localization &amp; Theme</CardTitle>
          <CardDescription>
            Manage supported languages, set the default operator locale, and keep the admin theme in sync with the mobile app.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-8">
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Languages className="h-4 w-4 text-primary" aria-hidden />
              <div>
                <h3 className="text-sm font-semibold text-foreground">Supported languages</h3>
                <p className="text-xs text-muted-foreground">Toggle which languages the operator console exposes to teams.</p>
              </div>
            </div>
            <div className="space-y-4 rounded-lg border border-dashed border-border/60 p-4">
              {languageCatalogue.map((language) => (
                <div key={language.code} className="flex items-start justify-between gap-4">
                  <div>
                    <p className="text-sm font-medium text-foreground">{language.label}</p>
                    <p className="text-xs text-muted-foreground">{language.description}</p>
                  </div>
                  <Checkbox
                    checked={config.localization.supportedLanguages.includes(language.code)}
                    onCheckedChange={(checked) => handleLanguageToggle(language.code)(Boolean(checked))}
                    aria-label={`Toggle ${language.label}`}
                  />
                </div>
              ))}
            </div>
          </div>

          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Globe2 className="h-4 w-4 text-primary" aria-hidden />
              <div>
                <h3 className="text-sm font-semibold text-foreground">Default operator language</h3>
                <p className="text-xs text-muted-foreground">Determines the fallback locale for notifications and reports.</p>
              </div>
            </div>
            <RadioGroup
              value={config.localization.defaultLanguage}
              onValueChange={handleDefaultLanguageChange}
              className="grid gap-3 sm:grid-cols-3"
            >
              {languageCatalogue.map((language) => (
                <div key={language.code} className="flex items-center space-x-2 rounded-lg border border-border/60 p-3">
                  <RadioGroupItem
                    value={language.code}
                    id={`default-language-${language.code}`}
                    disabled={!config.localization.supportedLanguages.includes(language.code)}
                  />
                  <Label htmlFor={`default-language-${language.code}`} className="text-sm">
                    {language.label}
                  </Label>
                </div>
              ))}
            </RadioGroup>
          </div>

          <div className="grid gap-6 lg:grid-cols-[1fr_0.75fr]">
            <div className="space-y-3">
              <div className="flex items-center gap-2">
                <Moon className="h-4 w-4 text-primary" aria-hidden={theme !== 'dark'} />
                <Sun className="h-4 w-4 text-primary" aria-hidden={theme === 'dark'} />
                <div>
                  <h3 className="text-sm font-semibold text-foreground">Theme preferences</h3>
                  <p className="text-xs text-muted-foreground">Toggle between light and dark mode to preview UI contrast.</p>
                </div>
              </div>
              <div className="flex items-center justify-between rounded-lg border border-border/60 p-4">
                <div>
                  <p className="text-sm font-medium text-foreground">Dark mode</p>
                  <p className="text-xs text-muted-foreground">Matches member apps for after-hours monitoring.</p>
                </div>
                <Switch id="theme-toggle" checked={theme === 'dark'} onCheckedChange={toggleTheme} />
              </div>
            </div>
            <Card className="shadow-custom-sm bg-muted/40">
              <CardHeader className="space-y-1">
                <CardTitle className="text-sm font-semibold">Localization preview</CardTitle>
                <CardDescription className="text-xs text-muted-foreground">
                  Sample experience for the selected default language.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3 text-sm">
                <div className="rounded-md bg-background/80 p-3 shadow-sm">
                  <p className="font-semibold text-foreground">{languagePreview.label}</p>
                  <p className="text-muted-foreground">{languagePreview.previewGreeting}</p>
                </div>
                {errors.languages ? (
                  <div className="flex items-center gap-2 text-sm text-destructive">
                    <XCircle className="h-4 w-4" aria-hidden />
                    <span>{errors.languages}</span>
                  </div>
                ) : (
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <Check className="h-4 w-4 text-emerald-500" aria-hidden />
                    <span>Default language is aligned with your supported set.</span>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function BadgePill({ label }: { label: string }) {
  return (
    <span className="inline-flex items-center rounded-full border border-primary/30 bg-primary/10 px-2 py-0.5 text-[11px] font-medium uppercase tracking-wide text-primary">
      {label}
    </span>
  );
}

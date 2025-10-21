import { useState } from 'react';
import { Save, Moon, Sun } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { useTheme } from '@/hooks/useTheme';
import { useToast } from '@/hooks/use-toast';

export default function Settings() {
  const { theme, toggleTheme } = useTheme();
  const { toast } = useToast();
  const [transactionFee, setTransactionFee] = useState('2.5');
  const [loanInterestRate, setLoanInterestRate] = useState('15');
  const [momoApiKey, setMomoApiKey] = useState('');

  const handleSave = () => {
    toast({
      title: 'Settings Saved',
      description: 'Your platform configuration has been updated successfully.',
    });
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold text-foreground">Settings</h2>
        <p className="text-muted-foreground">Configure platform settings and preferences</p>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Platform Configuration</CardTitle>
          <CardDescription>Manage transaction fees, interest rates, and other platform settings</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="transaction-fee">Transaction Fee (%)</Label>
              <Input
                id="transaction-fee"
                type="number"
                step="0.1"
                value={transactionFee}
                onChange={(e) => setTransactionFee(e.target.value)}
                placeholder="2.5"
              />
              <p className="text-xs text-muted-foreground">
                Percentage charged on each transaction
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="loan-interest">Loan Interest Rate (%)</Label>
              <Input
                id="loan-interest"
                type="number"
                step="0.1"
                value={loanInterestRate}
                onChange={(e) => setLoanInterestRate(e.target.value)}
                placeholder="15"
              />
              <p className="text-xs text-muted-foreground">
                Annual interest rate for loans
              </p>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="momo-api">Mobile Money API Key</Label>
            <Input
              id="momo-api"
              type="password"
              value={momoApiKey}
              onChange={(e) => setMomoApiKey(e.target.value)}
              placeholder="Enter your MoMo API key"
            />
            <p className="text-xs text-muted-foreground">
              API key for mobile money payment integration
            </p>
          </div>

          <div className="pt-4 border-t border-border">
            <Button onClick={handleSave} className="w-full sm:w-auto">
              <Save className="h-4 w-4 mr-2" />
              Save Configuration
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Appearance</CardTitle>
          <CardDescription>Customize the look and feel of your admin console</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="theme-toggle" className="text-base">Dark Mode</Label>
              <p className="text-sm text-muted-foreground">
                Toggle between light and dark theme
              </p>
            </div>
            <div className="flex items-center gap-3">
              {theme === 'dark' ? (
                <Moon className="h-5 w-5 text-muted-foreground" />
              ) : (
                <Sun className="h-5 w-5 text-muted-foreground" />
              )}
              <Switch
                id="theme-toggle"
                checked={theme === 'dark'}
                onCheckedChange={toggleTheme}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Notifications</CardTitle>
          <CardDescription>Configure notification preferences</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="email-notifications" className="text-base">Email Notifications</Label>
              <p className="text-sm text-muted-foreground">
                Receive email alerts for important events
              </p>
            </div>
            <Switch id="email-notifications" defaultChecked />
          </div>

          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="dispute-alerts" className="text-base">Dispute Alerts</Label>
              <p className="text-sm text-muted-foreground">
                Get notified when new disputes are filed
              </p>
            </div>
            <Switch id="dispute-alerts" defaultChecked />
          </div>

          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <Label htmlFor="kyc-alerts" className="text-base">KYC Verification Alerts</Label>
              <p className="text-sm text-muted-foreground">
                Alerts for pending KYC verifications
              </p>
            </div>
            <Switch id="kyc-alerts" defaultChecked />
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

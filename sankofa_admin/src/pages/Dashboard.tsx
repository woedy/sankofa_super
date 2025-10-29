import { useMemo } from 'react';
import {
  Users,
  PiggyBank,
  Wallet,
  ShieldAlert,
  AlertTriangle,
  CheckCircle2,
  Info,
  RefreshCcw,
} from 'lucide-react';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { useQuery } from '@tanstack/react-query';

import KPICard from '@/components/dashboard/KPICard';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Skeleton } from '@/components/ui/skeleton';
import { useAuthorizedApi } from '@/lib/auth';
import type { DashboardMetrics } from '@/lib/types';

const palette: Record<string, string> = {
  deposit: 'hsl(var(--primary))',
  withdrawal: 'hsl(var(--warning))',
  contribution: 'hsl(var(--muted-foreground))',
  payout: 'hsl(var(--secondary))',
  savings: 'hsl(var(--success))',
};

const notificationMeta = {
  alert: { icon: AlertTriangle, tone: 'text-destructive', background: 'bg-destructive/10' },
  warning: { icon: AlertTriangle, tone: 'text-warning', background: 'bg-warning/10' },
  success: { icon: CheckCircle2, tone: 'text-success', background: 'bg-success/10' },
  info: { icon: Info, tone: 'text-primary', background: 'bg-primary/10' },
} as const;

const formatCurrency = (value: number) =>
  `GH₵ ${value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

const formatNumber = (value: number) => value.toLocaleString();

const toDateLabel = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString('en-GB', { month: 'short', day: 'numeric' });
};

const toMonthLabel = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString('en-GB', { month: 'short', year: 'numeric' });
};

export default function Dashboard() {
  const api = useAuthorizedApi();
  const {
    data,
    isLoading,
    isError,
    refetch,
    isFetching,
  } = useQuery<DashboardMetrics>({
    queryKey: ['dashboard-metrics'],
    queryFn: () => api('/api/admin/dashboard/'),
    staleTime: 60_000,
  });

  const dailyTransactions = useMemo(() => {
    if (!data?.daily_volume) return [] as Array<{ date: string; volume: number }>;
    return data.daily_volume.map((entry) => ({
      date: toDateLabel(entry.date),
      volume: Number(entry.volume ?? 0),
    }));
  }, [data?.daily_volume]);

  const memberGrowthSeries = useMemo(() => {
    if (!data?.member_growth) return [] as Array<{ month: string; newMembers: number; totalMembers: number }>;
    return data.member_growth.map((entry) => ({
      month: toMonthLabel(entry.month),
      newMembers: entry.new_members,
      totalMembers: entry.total_members,
    }));
  }, [data?.member_growth]);

  const contributionMix = useMemo(() => {
    if (!data?.contribution_mix) return [] as Array<{ name: string; value: number; fill: string }>;
    return data.contribution_mix.map((entry) => ({
      name: entry.type,
      value: Number(entry.amount ?? 0),
      fill: palette[entry.type] ?? 'hsl(var(--primary))',
    }));
  }, [data?.contribution_mix]);

  const upcomingPayouts = useMemo(() => {
    if (!data?.upcoming_payouts) return [] as Array<{ id: string; reference: string | null; scheduled_for: string; group: string | null; amount: number }>;
    return data.upcoming_payouts.map((payout) => ({
      id: payout.id,
      reference: payout.reference,
      scheduled_for: new Date(payout.scheduled_for).toLocaleString('en-GB', {
        day: '2-digit',
        month: 'short',
        hour: '2-digit',
        minute: '2-digit',
      }),
      group: payout.group,
      amount: Number(payout.amount ?? 0),
    }));
  }, [data?.upcoming_payouts]);

  const notifications = useMemo(() => data?.notifications ?? [], [data?.notifications]);

  const renderContent = () => {
    if (isLoading && !data) {
      return (
        <div className="space-y-6">
          <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
            {Array.from({ length: 4 }).map((_, index) => (
              <Skeleton key={index} className="h-40 w-full rounded-xl" />
            ))}
          </div>
          <Skeleton className="h-[420px] w-full rounded-xl" />
          <Skeleton className="h-[420px] w-full rounded-xl" />
        </div>
      );
    }

    if (isError) {
      return (
        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Unable to load metrics</CardTitle>
            <CardDescription>Please try refreshing the dashboard.</CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => refetch()} disabled={isFetching}>
              <RefreshCcw className="mr-2 h-4 w-4" />
              Retry
            </Button>
          </CardContent>
        </Card>
      );
    }

    const kpis = data?.kpis ?? {
      active_members: 0,
      total_wallet_balance: 0,
      pending_payouts: 0,
      pending_withdrawals: 0,
    };

    return (
      <div className="space-y-6">
        <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
          <KPICard title="Active Members" value={formatNumber(kpis.active_members)} icon={Users} />
          <KPICard title="Total Wallet Float" value={formatCurrency(kpis.total_wallet_balance)} icon={PiggyBank} />
          <KPICard title="Pending Payouts" value={formatNumber(kpis.pending_payouts)} icon={Wallet} />
          <KPICard title="Pending Withdrawals" value={formatNumber(kpis.pending_withdrawals)} icon={ShieldAlert} />
        </div>

        <div className="grid gap-6 xl:grid-cols-[2fr_1fr]">
          <Card className="shadow-custom-md">
            <CardHeader className="flex flex-row items-start justify-between gap-4">
              <div>
                <CardTitle>7-day Cashflow Volume</CardTitle>
                <CardDescription>Successful transactions processed in the last month</CardDescription>
              </div>
              <Button variant="outline" size="icon" onClick={() => refetch()} disabled={isFetching} aria-label="Refresh metrics">
                <RefreshCcw className={`h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
              </Button>
            </CardHeader>
            <CardContent className="h-[360px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={dailyTransactions}>
                  <defs>
                    <linearGradient id="volumeGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="4 4" className="stroke-border" />
                  <XAxis dataKey="date" className="text-xs text-muted-foreground" />
                  <YAxis className="text-xs text-muted-foreground" />
                  <Tooltip
                    formatter={(value: number) => formatCurrency(value)}
                    labelStyle={{ color: 'hsl(var(--muted-foreground))' }}
                    contentStyle={{
                      backgroundColor: 'hsl(var(--card))',
                      border: '1px solid hsl(var(--border))',
                      borderRadius: '8px',
                    }}
                  />
                  <Area type="monotone" dataKey="volume" stroke="hsl(var(--primary))" fill="url(#volumeGradient)" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card className="shadow-custom-md">
            <CardHeader>
              <CardTitle>Contribution Mix</CardTitle>
              <CardDescription>Share of transaction volume by type</CardDescription>
            </CardHeader>
            <CardContent className="flex flex-col items-center justify-center">
              <ResponsiveContainer width="100%" height={280}>
                <PieChart>
                  <Pie dataKey="value" data={contributionMix} innerRadius={60} outerRadius={100} paddingAngle={4}>
                    {contributionMix.map((entry, index) => (
                      <Cell key={`${entry.name}-${index}`} fill={entry.fill} />
                    ))}
                  </Pie>
                  <Tooltip
                    formatter={(value: number, name: string) => [formatCurrency(value as number), name]}
                    contentStyle={{
                      backgroundColor: 'hsl(var(--card))',
                      border: '1px solid hsl(var(--border))',
                      borderRadius: '8px',
                    }}
                  />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
              <div className="mt-6 w-full space-y-2">
                {contributionMix.map((entry) => (
                  <div key={entry.name} className="flex items-center justify-between text-sm">
                    <span className="font-medium text-foreground">{entry.name}</span>
                    <span className="text-muted-foreground">{formatCurrency(entry.value)}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid gap-6 lg:grid-cols-2">
          <Card className="shadow-custom-md">
            <CardHeader>
              <CardTitle>Member Growth</CardTitle>
              <CardDescription>New members joining the platform</CardDescription>
            </CardHeader>
            <CardContent className="h-[360px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={memberGrowthSeries}>
                  <CartesianGrid strokeDasharray="4 4" className="stroke-border" />
                  <XAxis dataKey="month" className="text-xs text-muted-foreground" />
                  <YAxis className="text-xs text-muted-foreground" />
                  <Tooltip
                    formatter={(value: number, name: string) =>
                      name === 'newMembers' ? [`${value} new`, 'New Members'] : [`${value}`, 'Total Members']
                    }
                    contentStyle={{
                      backgroundColor: 'hsl(var(--card))',
                      border: '1px solid hsl(var(--border))',
                      borderRadius: '8px',
                    }}
                  />
                  <Legend formatter={(value) => (value === 'newMembers' ? 'New Members' : 'Total Members')} />
                  <Line type="monotone" dataKey="newMembers" stroke="hsl(var(--secondary))" strokeWidth={3} dot />
                  <Line type="monotone" dataKey="totalMembers" stroke="hsl(var(--primary))" strokeWidth={2} dot={false} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card className="shadow-custom-md">
            <CardHeader>
              <CardTitle>Upcoming Payouts</CardTitle>
              <CardDescription>Groups with payouts scheduled this week</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {upcomingPayouts.length === 0 ? (
                <p className="text-sm text-muted-foreground">No payouts scheduled for the next few days.</p>
              ) : (
                <ScrollArea className="h-[300px]">
                  <div className="space-y-3 pr-4">
                    {upcomingPayouts.map((payout) => (
                      <div key={payout.id} className="rounded-lg border border-border p-4">
                        <div className="flex items-center justify-between text-sm">
                          <span className="font-semibold text-foreground">{payout.group ?? 'Direct payout'}</span>
                          <span className="text-muted-foreground">{payout.scheduled_for}</span>
                        </div>
                        <p className="mt-2 text-sm text-muted-foreground">Reference: {payout.reference ?? 'N/A'}</p>
                        <p className="text-sm font-semibold text-primary">{formatCurrency(payout.amount)}</p>
                      </div>
                    ))}
                  </div>
                </ScrollArea>
              )}
            </CardContent>
          </Card>
        </div>

        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Operational Alerts</CardTitle>
            <CardDescription>Cashflow events and tasks requiring attention</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              {notifications.map((notification) => {
                const meta = notificationMeta[notification.level];
                const Icon = meta.icon;
                return (
                  <div
                    key={notification.id}
                    className={`rounded-lg border border-border p-4 ${meta.background} space-y-2`}
                  >
                    <div className="flex items-center gap-2">
                      <div className="rounded-full bg-background p-2 shadow-sm">
                        <Icon className={`h-4 w-4 ${meta.tone}`} />
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-foreground">{notification.title}</p>
                        <p className="text-xs text-muted-foreground">
                          {new Date(notification.created_at).toLocaleString('en-GB', {
                            day: '2-digit',
                            month: 'short',
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </p>
                      </div>
                    </div>
                    <p className="text-sm text-muted-foreground">{notification.message}</p>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      </div>
    );
  };

  return renderContent();
}

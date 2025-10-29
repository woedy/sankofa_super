import { useMemo } from 'react';
import {
  Users,
  PiggyBank,
  Wallet,
  ShieldAlert,
  AlertTriangle,
  CheckCircle2,
  Info,
  Bell,
  TrendingUp,
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

const toTimeLabel = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleString('en-GB', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const buildTrendLabel = (
  current: number,
  previous: number,
  formatter: (value: number) => string,
): { change: string; trend: 'up' | 'down' } => {
  const delta = current - previous;
  const direction = delta >= 0 ? 'up' : 'down';
  const absolute = Math.abs(delta);
  const symbol = delta >= 0 ? '↑' : '↓';
  return {
    trend: direction,
    change: `${symbol} ${formatter(absolute)} vs last week`,
  };
};

export default function Dashboard() {
  const api = useAuthorizedApi();
  const { data, isLoading, isError } = useQuery<DashboardMetrics>({
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
    if (!data?.member_growth)
      return [] as Array<{ month: string; newMembers: number; totalMembers: number }>;
    return data.member_growth.map((entry) => ({
      month: toMonthLabel(entry.month),
      newMembers: entry.new_members,
      totalMembers: entry.total_members,
    }));
  }, [data?.member_growth]);

  const contributionMix = useMemo(() => {
    if (!data?.contribution_mix)
      return [] as Array<{ name: string; value: number; fill: string }>;
    return data.contribution_mix.map((entry) => ({
      name: entry.type,
      value: Number(entry.amount ?? 0),
      fill: palette[entry.type] ?? 'hsl(var(--primary))',
    }));
  }, [data?.contribution_mix]);

  const upcomingPayouts = useMemo(() => {
    if (!data?.upcoming_payouts)
      return [] as Array<{
        id: string;
        reference: string | null;
        scheduledFor: string;
        group: string | null;
        amount: number;
        description: string;
        user: string | null;
        status: string;
      }>;
    return data.upcoming_payouts.map((payout) => ({
      id: payout.id,
      reference: payout.reference,
      scheduledFor: toTimeLabel(payout.scheduled_for),
      group: payout.group,
      amount: Number(payout.amount ?? 0),
      description: payout.description,
      user: payout.user,
      status: payout.status,
    }));
  }, [data?.upcoming_payouts]);

  const notifications = useMemo(
    () =>
      (data?.notifications ?? []).map((notification) => ({
        ...notification,
        time: toTimeLabel(notification.created_at),
      })),
    [data?.notifications],
  );

  if (isLoading && !data) {
    return (
      <div className="space-y-6">
        <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
          {Array.from({ length: 4 }).map((_, index) => (
            <Skeleton key={index} className="h-40 w-full rounded-xl" />
          ))}
        </div>
        <Skeleton className="h-[360px] w-full rounded-xl" />
        <Skeleton className="h-[360px] w-full rounded-xl" />
        <Skeleton className="h-[280px] w-full rounded-xl" />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Unable to load metrics</CardTitle>
          <CardDescription>Please try again shortly.</CardDescription>
        </CardHeader>
      </Card>
    );
  }

  const kpiConfig = [
    {
      key: 'active_members',
      title: 'Active Members',
      icon: Users,
      formatter: formatNumber,
    },
    {
      key: 'total_wallet_balance',
      title: 'Total Savings Wallets',
      icon: PiggyBank,
      formatter: formatCurrency,
    },
    {
      key: 'pending_payouts',
      title: 'Pending Payouts',
      icon: Wallet,
      formatter: formatNumber,
    },
    {
      key: 'pending_withdrawals',
      title: 'Pending Withdrawals',
      icon: ShieldAlert,
      formatter: formatNumber,
    },
  ] as const;

  return (
    <div className="space-y-6">
      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
        {kpiConfig.map(({ key, title, icon, formatter }) => {
          const metrics = data.kpis[key] ?? { current: 0, previous: 0 };
          const trend = buildTrendLabel(metrics.current, metrics.previous, formatter);
          return (
            <KPICard
              key={key}
              title={title}
              value={formatter(metrics.current)}
              change={trend.change}
              trend={trend.trend}
              icon={icon}
            />
          );
        })}
      </div>

      <div className="grid gap-6 xl:grid-cols-7">
        <Card className="xl:col-span-4 shadow-custom-md">
          <CardHeader>
            <CardTitle>Daily Transactions</CardTitle>
            <CardDescription>Aggregate successful volume across the last 7 days</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={dailyTransactions}>
                <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                <XAxis dataKey="date" className="text-muted-foreground" />
                <YAxis className="text-muted-foreground" />
                <Tooltip
                  formatter={(value: number) => formatCurrency(Number(value))}
                  contentStyle={{
                    backgroundColor: 'hsl(var(--card))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px',
                  }}
                />
                <Line type="monotone" dataKey="volume" stroke="hsl(var(--primary))" strokeWidth={2} dot />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card className="xl:col-span-3 shadow-custom-md">
          <CardHeader>
            <CardTitle>Member Growth</CardTitle>
            <CardDescription>New joiners and cumulative totals per month</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={memberGrowthSeries}>
                <defs>
                  <linearGradient id="colorMembers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.8} />
                    <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0.1} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                <XAxis dataKey="month" className="text-muted-foreground" />
                <YAxis className="text-muted-foreground" allowDecimals={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'hsl(var(--card))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px',
                  }}
                  formatter={(value: number, name) => {
                    if (name === 'newMembers') {
                      return [value, 'New Members'];
                    }
                    return [value, 'Total Members'];
                  }}
                />
                <Legend />
                <Area
                  type="monotone"
                  dataKey="totalMembers"
                  stroke="hsl(var(--primary))"
                  fill="url(#colorMembers)"
                  name="Total Members"
                />
                <Line
                  type="monotone"
                  dataKey="newMembers"
                  stroke="hsl(var(--success))"
                  strokeWidth={2}
                  dot={{ fill: 'hsl(var(--success))', r: 4 }}
                  name="New Members"
                />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 xl:grid-cols-7">
        <Card className="xl:col-span-3 shadow-custom-md">
          <CardHeader>
            <CardTitle>Contribution Mix</CardTitle>
            <CardDescription>Volume share by transaction type</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={contributionMix}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={90}
                  paddingAngle={4}
                  dataKey="value"
                >
                  {contributionMix.map((entry) => (
                    <Cell key={entry.name} fill={entry.fill} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(value: number, name: string) => [formatCurrency(Number(value)), name]}
                  contentStyle={{
                    backgroundColor: 'hsl(var(--card))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px',
                  }}
                />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card className="xl:col-span-4 shadow-custom-md">
          <CardHeader>
            <div className="flex items-center gap-2">
              <Bell className="h-5 w-5 text-primary" />
              <CardTitle>Recent Notifications</CardTitle>
            </div>
            <CardDescription>Latest platform activities and alerts</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {notifications.length === 0 ? (
              <p className="text-sm text-muted-foreground">No recent notifications.</p>
            ) : (
              notifications.map((notification) => {
                const meta =
                  notificationMeta[notification.level as keyof typeof notificationMeta] ?? notificationMeta.info;
                const Icon = meta.icon;
                return (
                  <div
                    key={notification.id}
                    className="flex items-start gap-3 rounded-lg border border-border p-4 transition-smooth hover:bg-muted/50"
                  >
                    <div className={`rounded-full ${meta.background} p-2`}>
                      <Icon className={`h-4 w-4 ${meta.tone}`} />
                    </div>
                    <div className="flex-1 space-y-1">
                      <p className="text-sm font-semibold text-foreground">{notification.title}</p>
                      <p className="text-sm text-muted-foreground">{notification.message}</p>
                      <p className="text-xs text-muted-foreground">{notification.time}</p>
                    </div>
                  </div>
                );
              })
            )}
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader>
          <div className="flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-primary" />
            <CardTitle>Upcoming Payout Watchlist</CardTitle>
          </div>
          <CardDescription>Monitor pending disbursements aligned with admin payout approvals</CardDescription>
        </CardHeader>
        <CardContent>
          {upcomingPayouts.length === 0 ? (
            <p className="text-sm text-muted-foreground">All payouts are settled for the current cycle.</p>
          ) : (
            <div className="space-y-4">
              {upcomingPayouts.map((payout) => (
                <div
                  key={payout.id}
                  className="flex flex-col gap-1 rounded-lg border border-border p-4 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="space-y-1">
                    <p className="text-sm font-semibold text-foreground">{payout.description}</p>
                    <p className="text-xs text-muted-foreground">
                      Reference: {payout.reference ?? 'N/A'} • {payout.group ?? 'Unassigned'} • {payout.user ?? 'Member'}
                    </p>
                    <p className="text-xs text-muted-foreground capitalize">Status: {payout.status}</p>
                  </div>
                  <div className="space-y-1 text-sm text-muted-foreground sm:text-right">
                    <p>{formatCurrency(payout.amount)}</p>
                    <p>Scheduled: {payout.scheduledFor}</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

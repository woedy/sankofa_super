import { useMemo } from 'react';
import {
  Users,
  PiggyBank,
  Wallet,
  ShieldAlert,
  TrendingUp,
  AlertTriangle,
  Bell,
  CheckCircle2,
  Info,
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
import KPICard from '@/components/dashboard/KPICard';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import {
  mockNotifications,
  mockUsers,
  mockTransactions,
  mockDisputes,
  dashboardKpiPreviousWeek,
} from '@/lib/mockData';

export default function Dashboard() {
  const formatNumber = (value: number) => value.toLocaleString();
  const formatCurrency = (value: number) =>
    `GH₵ ${value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  const activeMembers = mockUsers.filter((user) => user.status === 'Active').length;
  const totalSavings = mockUsers.reduce((sum, user) => sum + user.walletBalance, 0);
  const pendingPayouts = mockTransactions.filter(
    (transaction) => transaction.type === 'Payout' && transaction.status !== 'Success'
  ).length;
  const openDisputes = mockDisputes.filter((dispute) => dispute.status !== 'Resolved').length;

  const trendLabel = (current: number, previous: number, formatter?: (value: number) => string) => {
    const delta = current - previous;
    const absolute = formatter ? formatter(Math.abs(delta)) : Math.abs(delta).toLocaleString();
    const direction = delta >= 0 ? 'up' : 'down';
    const symbol = delta >= 0 ? '↑' : '↓';
    return {
      trend: direction as 'up' | 'down',
      label: `${symbol} ${absolute} vs last week`,
    };
  };

  const activeMemberTrend = trendLabel(activeMembers, dashboardKpiPreviousWeek.activeMembers);
  const totalSavingsTrend = trendLabel(totalSavings, dashboardKpiPreviousWeek.totalSavings, formatCurrency);
  const pendingPayoutTrend = trendLabel(pendingPayouts, dashboardKpiPreviousWeek.pendingPayouts);
  const openDisputeTrend = trendLabel(openDisputes, dashboardKpiPreviousWeek.openDisputes);

  const dailyTransactions = useMemo(() => {
    const formatter = new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric' });
    const totals = new Map<string, { date: string; volume: number }>();

    mockTransactions.forEach((transaction) => {
      const isoTimestamp = transaction.timestamp ?? `${transaction.date.replace(' ', 'T')}:00Z`;
      const timestamp = new Date(isoTimestamp);
      const dayKey = timestamp.toISOString().slice(0, 10);
      const existing = totals.get(dayKey) ?? {
        date: formatter.format(timestamp),
        volume: 0,
      };

      if (transaction.status !== 'Failed') {
        existing.volume += transaction.amount;
      }

      totals.set(dayKey, existing);
    });

    return Array.from(totals.entries())
      .sort(([a], [b]) => (a > b ? 1 : -1))
      .slice(-7)
      .map(([, value]) => value);
  }, []);

  const memberGrowthSeries = useMemo(() => {
    const monthFormatter = new Intl.DateTimeFormat('en-US', { month: 'short' });
    const monthlyCounts = new Map<string, number>();

    mockUsers.forEach((user) => {
      const monthDate = new Date(`${user.joinedDate}T00:00:00Z`);
      const key = `${monthDate.getUTCFullYear()}-${monthDate.getUTCMonth()}`;
      monthlyCounts.set(key, (monthlyCounts.get(key) ?? 0) + 1);
    });

    const sortedMonths = Array.from(monthlyCounts.keys()).sort((a, b) => {
      const [aYear, aMonth] = a.split('-').map(Number);
      const [bYear, bMonth] = b.split('-').map(Number);
      if (aYear === bYear) return aMonth - bMonth;
      return aYear - bYear;
    });

    let cumulative = 0;
    return sortedMonths
      .slice(-6)
      .map((key) => {
        const [year, month] = key.split('-').map(Number);
        const newMembers = monthlyCounts.get(key) ?? 0;
        cumulative += newMembers;
        return {
          month: monthFormatter.format(new Date(Date.UTC(year, month, 1))),
          newMembers,
          totalMembers: cumulative,
        };
      });
  }, []);

  const contributionMix = useMemo(() => {
    const palette: Record<string, string> = {
      Deposit: 'hsl(var(--primary))',
      Contribution: 'hsl(var(--success))',
      Withdrawal: 'hsl(var(--warning))',
      Payout: 'hsl(var(--secondary))',
      Savings: 'hsl(var(--muted-foreground))',
    };

    const totals = new Map<string, { name: string; value: number; fill: string }>();

    mockTransactions.forEach((transaction) => {
      const existing = totals.get(transaction.type) ?? {
        name: transaction.type,
        value: 0,
        fill: palette[transaction.type] ?? 'hsl(var(--primary))',
      };

      if (transaction.status !== 'Failed') {
        existing.value += transaction.amount;
      }

      totals.set(transaction.type, existing);
    });

    return Array.from(totals.values());
  }, []);

  const upcomingPayouts = useMemo(() => {
    const upcomingTransactions = mockTransactions
      .filter((transaction) => transaction.type === 'Payout' && transaction.status !== 'Success')
      .sort((a, b) => {
        const aIso = a.timestamp ?? `${a.date.replace(' ', 'T')}:00Z`;
        const bIso = b.timestamp ?? `${b.date.replace(' ', 'T')}:00Z`;
        const aTime = new Date(aIso).getTime();
        const bTime = new Date(bIso).getTime();
        return aTime - bTime;
      });

    return upcomingTransactions.map((transaction) => ({
      id: transaction.id,
      reference: transaction.reference,
      scheduledFor: transaction.date,
      description: transaction.description,
    }));
  }, []);

  const notificationMeta = {
    alert: { icon: AlertTriangle, tone: 'text-destructive', background: 'bg-destructive/10' },
    warning: { icon: AlertTriangle, tone: 'text-warning', background: 'bg-warning/10' },
    success: { icon: CheckCircle2, tone: 'text-success', background: 'bg-success/10' },
    info: { icon: Info, tone: 'text-primary', background: 'bg-primary/10' },
  } as const;

  return (
    <div className="space-y-6">
      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-4">
        <KPICard
          title="Active Members"
          value={formatNumber(activeMembers)}
          change={activeMemberTrend.label}
          trend={activeMemberTrend.trend}
          icon={Users}
        />
        <KPICard
          title="Total Savings Wallets"
          value={formatCurrency(totalSavings)}
          change={totalSavingsTrend.label}
          trend={totalSavingsTrend.trend}
          icon={PiggyBank}
        />
        <KPICard
          title="Pending Payouts"
          value={formatNumber(pendingPayouts)}
          change={pendingPayoutTrend.label}
          trend={pendingPayoutTrend.trend}
          icon={Wallet}
        />
        <KPICard
          title="Open Disputes"
          value={formatNumber(openDisputes)}
          change={openDisputeTrend.label}
          trend={openDisputeTrend.trend}
          icon={ShieldAlert}
        />
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
                  formatter={(value, name) => {
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
                  formatter={(value: number, name: string) => [formatCurrency(value), name]}
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
            {mockNotifications.map((notification) => {
              const meta = notificationMeta[notification.type as keyof typeof notificationMeta] ?? notificationMeta.info;
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
                    <p className="text-sm font-medium text-foreground">{notification.message}</p>
                    <p className="text-xs text-muted-foreground">{notification.time}</p>
                  </div>
                </div>
              );
            })}
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
                  <div>
                    <p className="text-sm font-semibold text-foreground">{payout.description}</p>
                    <p className="text-xs text-muted-foreground">Reference: {payout.reference}</p>
                  </div>
                  <p className="text-xs text-muted-foreground">Scheduled: {payout.scheduledFor}</p>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

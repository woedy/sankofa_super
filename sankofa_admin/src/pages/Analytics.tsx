import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { DollarSign, Users, Wallet, TrendingUp, RefreshCcw } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';

import KPICard from '@/components/dashboard/KPICard';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { useAuthorizedApi } from '@/lib/auth';
import type { DashboardMetrics } from '@/lib/types';

const formatCurrency = (value: number) =>
  `GH₵ ${value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

const toMonthLabel = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString('en-GB', { month: 'short', year: 'numeric' });
};

export default function Analytics() {
  const api = useAuthorizedApi();
  const { data, isLoading, isFetching, refetch } = useQuery<DashboardMetrics>({
    queryKey: ['admin-dashboard-analytics'],
    queryFn: () => api('/api/admin/dashboard/'),
    staleTime: 60_000,
  });

  const getKpiValue = (key: string) => data?.kpis?.[key]?.current ?? 0;

  const contributionSeries = useMemo(() => {
    if (!data?.daily_volume) return [] as Array<{ date: string; volume: number }>;
    return data.daily_volume.map((entry) => ({ date: entry.date, volume: Number(entry.volume ?? 0) }));
  }, [data?.daily_volume]);

  const memberGrowth = useMemo(() => {
    if (!data?.member_growth) return [] as Array<{ month: string; newMembers: number; totalMembers: number }>;
    return data.member_growth.map((entry) => ({
      month: toMonthLabel(entry.month),
      newMembers: entry.new_members,
      totalMembers: entry.total_members,
    }));
  }, [data?.member_growth]);

  if (isLoading && !data) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-40 w-full rounded-xl" />
        <Skeleton className="h-[400px] w-full rounded-xl" />
        <Skeleton className="h-[400px] w-full rounded-xl" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h2 className="text-3xl font-bold text-foreground">Analytics Dashboard</h2>
          <p className="text-muted-foreground">Track growth metrics and platform performance</p>
        </div>
        <Button variant="outline" onClick={() => refetch()} disabled={isFetching}>
          <RefreshCcw className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Monthly Volume" value={formatCurrency(contributionSeries.reduce((sum, point) => sum + point.volume, 0))} icon={DollarSign} />
        <KPICard title="Active Members" value={getKpiValue('active_members').toLocaleString()} icon={Users} />
        <KPICard title="Wallet Float" value={formatCurrency(getKpiValue('total_wallet_balance'))} icon={Wallet} />
        <KPICard
          title="Pending Cashflow"
          value={`${getKpiValue('pending_payouts') + getKpiValue('pending_withdrawals')}`}
          icon={TrendingUp}
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Daily Transaction Volume</CardTitle>
            <CardDescription>Successful transactions recorded over the last 30 days</CardDescription>
          </CardHeader>
          <CardContent className="h-[360px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={contributionSeries}>
                <CartesianGrid strokeDasharray="4 4" className="stroke-border" />
                <XAxis dataKey="date" className="text-xs text-muted-foreground" />
                <YAxis className="text-xs text-muted-foreground" />
                <Tooltip
                  formatter={(value: number) => formatCurrency(value as number)}
                  contentStyle={{
                    backgroundColor: 'hsl(var(--card))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: '8px',
                  }}
                />
                <Bar dataKey="volume" fill="hsl(var(--primary))" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card className="shadow-custom-md">
          <CardHeader>
            <CardTitle>Member Growth</CardTitle>
            <CardDescription>Monthly new members and cumulative totals</CardDescription>
          </CardHeader>
          <CardContent className="h-[360px]">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={memberGrowth}>
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
      </div>

      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Key Performance Indicators</CardTitle>
          <CardDescription>Pending payouts and withdrawals requiring attention</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-lg border border-border p-4">
            <p className="text-sm text-muted-foreground">Pending payouts</p>
            <p className="text-2xl font-semibold text-foreground">{getKpiValue('pending_payouts')}</p>
          </div>
          <div className="rounded-lg border border-border p-4">
            <p className="text-sm text-muted-foreground">Pending withdrawals</p>
            <p className="text-2xl font-semibold text-foreground">{getKpiValue('pending_withdrawals')}</p>
          </div>
          <div className="rounded-lg border border-border p-4">
            <p className="text-sm text-muted-foreground">Total wallet float</p>
            <p className="text-2xl font-semibold text-foreground">{formatCurrency(getKpiValue('total_wallet_balance'))}</p>
          </div>
          <div className="rounded-lg border border-border p-4">
            <p className="text-sm text-muted-foreground">Active members</p>
            <p className="text-2xl font-semibold text-foreground">{getKpiValue('active_members').toLocaleString()}</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

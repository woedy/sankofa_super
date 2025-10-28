import { useQuery } from '@tanstack/react-query';
import { AlertTriangle, CheckCircle2, Clock, RefreshCcw } from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Skeleton } from '@/components/ui/skeleton';
import { useAuthorizedApi } from '@/lib/auth';
import type { CashflowQueueItem, CashflowQueuesResponse } from '@/lib/types';

const formatCurrency = (value: string | number) => {
  const numeric = typeof value === 'string' ? Number(value) : value;
  return `GH₵ ${numeric.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

const formatDateTime = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
};

const riskMeta = {
  Low: { tone: 'text-success', badge: 'bg-success/10 text-success border-success/20', icon: CheckCircle2 },
  Medium: { tone: 'text-warning', badge: 'bg-warning/10 text-warning border-warning/20', icon: Clock },
  High: { tone: 'text-destructive', badge: 'bg-destructive/10 text-destructive border-destructive/20', icon: AlertTriangle },
} as const;

interface QueueProps {
  title: string;
  description: string;
  items: CashflowQueueItem[];
  emptyLabel: string;
}

function QueueCard({ title, description, items, emptyLabel }: QueueProps) {
  return (
    <Card className="shadow-custom-md">
      <CardHeader>
        <CardTitle>{title}</CardTitle>
        <CardDescription>{description}</CardDescription>
      </CardHeader>
      <CardContent>
        {items.length === 0 ? (
          <p className="text-sm text-muted-foreground">{emptyLabel}</p>
        ) : (
          <ScrollArea className="h-[400px]">
            <div className="space-y-4 pr-4">
              {items.map((item) => {
                const meta = riskMeta[item.risk as keyof typeof riskMeta] ?? riskMeta.Low;
                const Icon = meta.icon;
                return (
                  <div key={item.id} className="rounded-lg border border-border p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-semibold text-foreground">{item.user}</p>
                        <p className="text-xs text-muted-foreground">Reference {item.reference}</p>
                      </div>
                      <Badge className={meta.badge}>{item.risk} risk</Badge>
                    </div>
                    <div className="mt-3 flex items-center justify-between text-sm">
                      <span className="font-semibold text-foreground">{formatCurrency(item.amount)}</span>
                      <span className="text-muted-foreground">{formatDateTime(item.submitted_at)}</span>
                    </div>
                    <div className="mt-3 space-y-1 text-xs text-muted-foreground">
                      {Object.entries(item.checklist).map(([key, value]) => (
                        <div key={key} className="flex items-center justify-between">
                          <span className="capitalize">{key}</span>
                          <span className="font-medium text-foreground">{value}</span>
                        </div>
                      ))}
                    </div>
                    <div className="mt-3 flex items-center gap-2 text-xs text-muted-foreground">
                      <Icon className={`h-4 w-4 ${meta.tone}`} />
                      <span>Channel: {item.channel}</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </ScrollArea>
        )}
      </CardContent>
    </Card>
  );
}

export default function Cashflow() {
  const api = useAuthorizedApi();

  const { data, isLoading, isFetching, refetch } = useQuery<CashflowQueuesResponse>({
    queryKey: ['admin-cashflow-queues'],
    queryFn: () => api('/api/admin/cashflow/queues/'),
    staleTime: 30_000,
  });

  const deposits = data?.deposits ?? [];
  const withdrawals = data?.withdrawals ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">Cashflow Operations Center</h1>
          <p className="text-sm text-muted-foreground">
            Review pending deposits and withdrawals before releasing funds.
          </p>
        </div>
        <Button variant="outline" onClick={() => refetch()} disabled={isFetching}>
          <RefreshCcw className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      {isLoading ? (
        <div className="grid gap-6 lg:grid-cols-2">
          <Skeleton className="h-[420px] w-full rounded-xl" />
          <Skeleton className="h-[420px] w-full rounded-xl" />
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          <QueueCard
            title="Pending deposits"
            description="Deposits awaiting confirmation or review"
            items={deposits}
            emptyLabel="No deposits require action right now."
          />
          <QueueCard
            title="Pending withdrawals"
            description="Withdrawals queued for manual release"
            items={withdrawals}
            emptyLabel="No withdrawals require action right now."
          />
        </div>
      )}
    </div>
  );
}

import { useMemo, useState } from 'react';
import {
  ClipboardList,
  Download,
  FileText,
  Filter,
  Shield,
  CheckCircle2,
  AlertTriangle,
  Clock3,
  XCircle,
} from 'lucide-react';
import {
  mockCashflowQueues,
  CashflowQueueItem,
  CashflowChecklistStatus,
} from '@/lib/mockData';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { StatusBadge } from '@/components/ui/badge-variants';
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';

const currencyFormatter = new Intl.NumberFormat('en-GH', {
  style: 'currency',
  currency: 'GHS',
  minimumFractionDigits: 2,
});

const riskTone: Record<CashflowQueueItem['risk'], string> = {
  Low: 'bg-success/10 text-success border-success/20',
  Medium: 'bg-warning/10 text-warning border-warning/20',
  High: 'bg-destructive/10 text-destructive border-destructive/20',
};

const checklistTone: Record<CashflowChecklistStatus, string> = {
  Complete: 'text-success',
  Pending: 'text-warning',
  Flagged: 'text-destructive',
};

const actionableStatuses = new Set([
  'Pending',
  'In Review',
  'Awaiting Approval',
  'On Hold',
  'Flagged',
]);

const formatDateTime = (value: string) => {
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

const formatDate = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }

  return parsed.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};

type QueueKey = 'deposits' | 'withdrawals';

type FilterState = {
  status: string;
  channel: string;
  risk: string;
};

export default function Cashflow() {
  const { toast } = useToast();
  const [queue, setQueue] = useState<QueueKey>('deposits');
  const [filters, setFilters] = useState<FilterState>({ status: 'all', channel: 'all', risk: 'all' });
  const [selectedItem, setSelectedItem] = useState<CashflowQueueItem | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const queueItems = mockCashflowQueues[queue];

  const uniqueStatuses = useMemo(
    () => Array.from(new Set(queueItems.map((item) => item.status))),
    [queueItems],
  );

  const uniqueChannels = useMemo(
    () => Array.from(new Set(queueItems.map((item) => item.channel))),
    [queueItems],
  );

  const filteredItems = queueItems.filter((item) => {
    const statusMatches = filters.status === 'all' || item.status === filters.status;
    const channelMatches = filters.channel === 'all' || item.channel === filters.channel;
    const riskMatches = filters.risk === 'all' || item.risk === filters.risk;
    return statusMatches && channelMatches && riskMatches;
  });

  const actionableCount = queueItems.filter((item) => actionableStatuses.has(item.status)).length;
  const flaggedCount = queueItems.filter((item) => item.status === 'Flagged' || item.risk === 'High').length;
  const valueInQueue = queueItems
    .filter((item) => item.status !== 'Cleared' && item.status !== 'Released')
    .reduce((sum, item) => sum + item.amount, 0);

  const openDrawer = (item: CashflowQueueItem) => {
    setSelectedItem(item);
    setDrawerOpen(true);
  };

  const closeDrawer = (open: boolean) => {
    setDrawerOpen(open);
    if (!open) {
      setSelectedItem(null);
    }
  };

  const handleFilterChange = (key: keyof FilterState, value: string) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
  };

  const handleExport = (format: 'CSV' | 'PDF') => {
    toast({
      title: `${format} export queued`,
      description: `The ${queue === 'deposits' ? 'deposit' : 'withdrawal'} queue export will download once generated.`,
    });
  };

  const handleAction = (action: 'release' | 'hold' | 'fail') => {
    if (!selectedItem) return;

    const actionCopy: Record<typeof action, { title: string; description: string }> = {
      release: {
        title: 'Funds released',
        description: `${selectedItem.reference} marked as completed. Wallet balance will update in the next refresh.`,
      },
      hold: {
        title: 'Additional documentation requested',
        description: `${selectedItem.reference} remains on hold while you await supporting documents.`,
      },
      fail: {
        title: 'Cashflow failed',
        description: `${selectedItem.reference} closed as failed. Member will be notified to retry.`,
      },
    };

    toast(actionCopy[action]);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">Cashflow Operations Center</h1>
          <p className="text-sm text-muted-foreground">
            Triage deposits and withdrawals with compliance context before funds are released.
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => handleExport('CSV')}>
            <Download className="mr-2 h-4 w-4" />
            Export CSV
          </Button>
          <Button variant="outline" onClick={() => handleExport('PDF')}>
            <FileText className="mr-2 h-4 w-4" />
            Export PDF
          </Button>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <Card className="shadow-custom-md">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Actionable cases</CardTitle>
            <ClipboardList className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-semibold text-foreground">{actionableCount}</p>
            <p className="text-xs text-muted-foreground mt-1">Pending analyst or supervisor input</p>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">High risk & flagged</CardTitle>
            <Shield className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-semibold text-foreground">{flaggedCount}</p>
            <p className="text-xs text-muted-foreground mt-1">Requires enhanced due diligence</p>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Value in queue</CardTitle>
            <AlertTriangle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-semibold text-foreground">{currencyFormatter.format(valueInQueue)}</p>
            <p className="text-xs text-muted-foreground mt-1">Outstanding until holds resolve</p>
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader className="pb-4">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <CardTitle>Realtime queues</CardTitle>
              <CardDescription>
                Switch between deposit and withdrawal operations, then filter by status, channel, or risk.
              </CardDescription>
            </div>
            <Tabs value={queue} onValueChange={(value) => setQueue(value as QueueKey)} className="w-full lg:w-auto">
              <TabsList className="w-full lg:w-auto">
                <TabsTrigger value="deposits" className="flex-1">Deposits</TabsTrigger>
                <TabsTrigger value="withdrawals" className="flex-1">Withdrawals</TabsTrigger>
              </TabsList>
            </Tabs>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-3 sm:grid-cols-3">
            <Select value={filters.status} onValueChange={(value) => handleFilterChange('status', value)}>
              <SelectTrigger className="bg-background">
                <SelectValue placeholder="Status">
                  {filters.status === 'all' ? 'All statuses' : filters.status}
                </SelectValue>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                {uniqueStatuses.map((status) => (
                  <SelectItem key={status} value={status}>
                    {status}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={filters.channel} onValueChange={(value) => handleFilterChange('channel', value)}>
              <SelectTrigger className="bg-background">
                <SelectValue placeholder="Channel">
                  {filters.channel === 'all' ? 'All channels' : filters.channel}
                </SelectValue>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All channels</SelectItem>
                {uniqueChannels.map((channel) => (
                  <SelectItem key={channel} value={channel}>
                    {channel}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>

            <Select value={filters.risk} onValueChange={(value) => handleFilterChange('risk', value)}>
              <SelectTrigger className="bg-background">
                <SelectValue placeholder="Risk">
                  {filters.risk === 'all' ? 'All risk levels' : filters.risk}
                </SelectValue>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All risk levels</SelectItem>
                <SelectItem value="Low">Low risk</SelectItem>
                <SelectItem value="Medium">Medium risk</SelectItem>
                <SelectItem value="High">High risk</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="rounded-lg border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="hidden xl:table-cell">Reference</TableHead>
                  <TableHead>Submitted</TableHead>
                  <TableHead>Member</TableHead>
                  <TableHead className="hidden lg:table-cell">Group</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead className="hidden md:table-cell">Channel</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="hidden lg:table-cell">Risk</TableHead>
                  <TableHead className="hidden xl:table-cell">Analyst</TableHead>
                  <TableHead className="w-[60px] text-right">Review</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredItems.map((item) => (
                  <TableRow key={item.id}>
                    <TableCell className="hidden xl:table-cell font-mono text-xs text-muted-foreground">
                      {item.reference}
                    </TableCell>
                    <TableCell className="text-sm font-medium text-foreground">
                      {formatDateTime(item.submittedAt)}
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-col">
                        <span className="font-medium text-foreground">{item.member}</span>
                        <span className="text-xs text-muted-foreground">{item.group}</span>
                      </div>
                    </TableCell>
                    <TableCell className="hidden lg:table-cell text-sm text-muted-foreground">
                      {item.group ?? '—'}
                    </TableCell>
                    <TableCell className="font-semibold text-foreground">
                      {currencyFormatter.format(item.amount)}
                    </TableCell>
                    <TableCell className="hidden md:table-cell text-sm text-muted-foreground">
                      {item.channel}
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={item.status} />
                    </TableCell>
                    <TableCell className="hidden lg:table-cell">
                      <Badge variant="outline" className={cn('font-medium', riskTone[item.risk])}>
                        {item.risk}
                      </Badge>
                    </TableCell>
                    <TableCell className="hidden xl:table-cell text-sm text-muted-foreground">
                      {item.analyst}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="sm" onClick={() => openDrawer(item)}>
                        Review
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
                {filteredItems.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={10} className="py-10 text-center text-sm text-muted-foreground">
                      <Filter className="mx-auto mb-2 h-5 w-5" />
                      No queue items match the selected filters.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </div>

          <p className="text-xs text-muted-foreground">
            Showing {filteredItems.length} of {queueItems.length} {queue === 'deposits' ? 'deposits' : 'withdrawals'} in queue
            ({filters.status === 'all' ? 'all statuses' : filters.status.toLowerCase()}).
          </p>
        </CardContent>
      </Card>

      <Drawer open={drawerOpen} onOpenChange={closeDrawer}>
        <DrawerContent className="sm:left-1/2 sm:w-full sm:max-w-3xl sm:-translate-x-1/2 sm:rounded-t-[24px] flex h-[85vh] flex-col overflow-hidden">
          {selectedItem && (
            <>
              <ScrollArea className="flex-1">
                <div className="px-4 py-6 sm:px-8">
                  <div className="space-y-6">
                    <DrawerHeader className="px-0 pb-4">
                      <DrawerTitle className="text-xl text-foreground">{selectedItem.member}</DrawerTitle>
                      <DrawerDescription className="text-sm text-muted-foreground">
                        {selectedItem.type} • {selectedItem.channel} • Reference {selectedItem.reference}
                      </DrawerDescription>
                    </DrawerHeader>

                    <div className="grid gap-6">
                      <Card className="border-dashed">
                        <CardContent className="grid gap-2 py-6 sm:grid-cols-3">
                          <div>
                            <p className="text-xs uppercase text-muted-foreground">Amount</p>
                            <p className="text-lg font-semibold text-foreground">
                              {currencyFormatter.format(selectedItem.amount)}
                            </p>
                          </div>
                          <div>
                            <p className="text-xs uppercase text-muted-foreground">Submitted</p>
                            <p className="text-sm text-foreground">{formatDateTime(selectedItem.submittedAt)}</p>
                          </div>
                          <div>
                            <p className="text-xs uppercase text-muted-foreground">Updated</p>
                            <p className="text-sm text-foreground">{formatDateTime(selectedItem.updatedAt)}</p>
                          </div>
                        </CardContent>
                      </Card>

                      <div className="grid gap-4 md:grid-cols-2">
                        <Card className="shadow-none border-border">
                          <CardHeader className="pb-3">
                            <CardTitle className="text-sm font-semibold text-foreground">Compliance checklist</CardTitle>
                            <CardDescription className="text-xs">
                              Ensure each requirement is satisfied before releasing funds.
                            </CardDescription>
                          </CardHeader>
                          <CardContent className="space-y-3">
                            {selectedItem.compliance.map((item) => (
                              <div key={item.label} className="flex items-start gap-3">
                                {item.status === 'Complete' && <CheckCircle2 className="mt-0.5 h-4 w-4 text-success" />}
                                {item.status === 'Pending' && <Clock3 className="mt-0.5 h-4 w-4 text-warning" />}
                                {item.status === 'Flagged' && <AlertTriangle className="mt-0.5 h-4 w-4 text-destructive" />}
                                <div>
                                  <p className={cn('text-sm font-medium', checklistTone[item.status])}>{item.label}</p>
                                  {item.note && (
                                    <p className="text-xs text-muted-foreground mt-0.5">{item.note}</p>
                                  )}
                                </div>
                              </div>
                            ))}
                          </CardContent>
                        </Card>

                        <Card className="shadow-none border-border">
                          <CardHeader className="pb-3">
                            <CardTitle className="text-sm font-semibold text-foreground">Fee breakdown</CardTitle>
                            <CardDescription className="text-xs">
                              Platform and channel deductions applied to this request.
                            </CardDescription>
                          </CardHeader>
                          <CardContent className="space-y-3">
                            {selectedItem.fees.map((fee) => (
                              <div key={fee.label} className="flex items-center justify-between text-sm">
                                <span className="text-muted-foreground">{fee.label}</span>
                                <span className="font-medium text-foreground">{currencyFormatter.format(fee.amount)}</span>
                              </div>
                            ))}
                            <Separator />
                            <div className="flex items-center justify-between text-sm">
                              <span className="text-muted-foreground">Net amount to member</span>
                              <span className="font-semibold text-foreground">
                                {currencyFormatter.format(
                                  selectedItem.amount - selectedItem.fees.reduce((sum, fee) => sum + fee.amount, 0),
                                )}
                              </span>
                            </div>
                          </CardContent>
                        </Card>
                      </div>

                      <Card className="shadow-none border-border">
                        <CardHeader className="pb-3">
                          <CardTitle className="text-sm font-semibold text-foreground">Activity timeline</CardTitle>
                          <CardDescription className="text-xs">
                            Track the operational touchpoints for this request.
                          </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4">
                          <ScrollArea className="h-48 pr-4">
                            <div className="space-y-4">
                              {selectedItem.timeline.map((event) => (
                                <div key={`${event.label}-${event.timestamp}`} className="flex items-start gap-3">
                                  <div className="relative mt-0.5 flex h-5 w-5 items-center justify-center rounded-full border border-border bg-card">
                                    <div className="h-2 w-2 rounded-full bg-primary" />
                                  </div>
                                  <div>
                                    <p className="text-sm font-medium text-foreground">{event.label}</p>
                                    <p className="text-xs text-muted-foreground">{formatDateTime(event.timestamp)}</p>
                                    {event.note && (
                                      <p className="text-xs text-muted-foreground mt-0.5">{event.note}</p>
                                    )}
                                  </div>
                                </div>
                              ))}
                            </div>
                          </ScrollArea>
                        </CardContent>
                      </Card>

                      <Card className="shadow-none border-border">
                        <CardHeader className="pb-3">
                          <CardTitle className="text-sm font-semibold text-foreground">Analyst notes</CardTitle>
                          <CardDescription className="text-xs">
                            {selectedItem.analyst} — last updated {formatDate(selectedItem.updatedAt)}
                          </CardDescription>
                        </CardHeader>
                        <CardContent>
                          <p className="text-sm leading-relaxed text-foreground">{selectedItem.notes}</p>
                        </CardContent>
                      </Card>
                    </div>
                  </div>
                </div>
              </ScrollArea>

              <DrawerFooter className="border-t border-border px-4 pt-4 sm:px-8">
                <div className="flex flex-col gap-3 sm:flex-row">
                  <Button className="flex-1" onClick={() => handleAction('release')}>
                    Release funds
                  </Button>
                  <Button variant="outline" className="flex-1" onClick={() => handleAction('hold')}>
                    Request docs
                  </Button>
                  <Button variant="destructive" className="flex-1" onClick={() => handleAction('fail')}>
                    Mark as failed
                  </Button>
                </div>
                <DrawerClose asChild>
                  <Button variant="ghost" className="mt-2 flex items-center gap-2 self-center text-sm text-muted-foreground">
                    <XCircle className="h-4 w-4" /> Close review
                  </Button>
                </DrawerClose>
              </DrawerFooter>
            </>
          )}
        </DrawerContent>
      </Drawer>
    </div>
  );
}

import { useMemo, useState } from 'react';
import {
  Search,
  MoreHorizontal,
  CheckCircle2,
  XCircle,
  Wallet,
  Landmark,
  Flag,
  Phone,
  MapPin,
  Mail,
  CalendarDays,
  ArrowUpRight,
  ArrowDownRight,
} from 'lucide-react';
import {
  mockUsers,
  mockTransactions,
  mockSavingsGoals,
  mockMemberDocuments,
} from '@/lib/mockData';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge-variants';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Drawer,
  DrawerClose,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Progress } from '@/components/ui/progress';
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';

const currencyFormatter = new Intl.NumberFormat('en-GH', {
  style: 'currency',
  currency: 'GHS',
  minimumFractionDigits: 2,
});

type Member = (typeof mockUsers)[number];
type SavingsGoal = (typeof mockSavingsGoals)[number];
type Transaction = (typeof mockTransactions)[number];
type MemberDocuments = (typeof mockMemberDocuments)[number];

type MemberOverride = Partial<Pick<Member, 'kycStatus' | 'status' | 'riskLevel' | 'flagged'>>;

type SavingsSummary = {
  goals: SavingsGoal[];
  activeCount: number;
  dormantCount: number;
  completedCount: number;
  totalSaved: number;
  status: 'No Goals' | 'Active Goals' | 'Dormant' | 'Completed';
};

const riskTone: Record<string, string> = {
  Low: 'bg-success/10 text-success border-success/20',
  Medium: 'bg-warning/10 text-warning border-warning/20',
  High: 'bg-destructive/10 text-destructive border-destructive/20',
};

const documentTone: Record<string, string> = {
  Verified: 'bg-success/10 text-success border-success/20',
  'Pending Review': 'bg-warning/10 text-warning border-warning/20',
  Rejected: 'bg-destructive/10 text-destructive border-destructive/20',
  Missing: 'border-dashed border-border text-muted-foreground',
  Expired: 'bg-destructive/10 text-destructive border-destructive/20',
};

const formatDate = (value: string) => {
  const normalized = value.includes(' ') ? value.replace(' ', 'T') : value;
  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
};

const formatDateTime = (value: string) => {
  const normalized = value.includes(' ') ? value.replace(' ', 'T') : value;
  const parsed = new Date(normalized);
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

const getSavingsLabel = (summary: SavingsSummary) => {
  if (summary.goals.length === 0) {
    return 'No goals';
  }

  const parts = [
    summary.activeCount > 0 ? `${summary.activeCount} active` : null,
    summary.dormantCount > 0 ? `${summary.dormantCount} dormant` : null,
    summary.completedCount > 0 ? `${summary.completedCount} completed` : null,
  ].filter(Boolean);

  return parts.join(' • ');
};

export default function Users() {
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [kycFilter, setKycFilter] = useState('all');
  const [savingsFilter, setSavingsFilter] = useState('all');
  const [riskFilter, setRiskFilter] = useState('all');
  const [overrides, setOverrides] = useState<Record<string, MemberOverride>>({});
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const savingsSummaryByUser = useMemo(() => {
    return mockUsers.reduce((acc, user) => {
      const goals = mockSavingsGoals.filter((goal) => goal.userId === user.id);
      const activeCount = goals.filter((goal) => goal.status === 'Active').length;
      const dormantCount = goals.filter((goal) => goal.status === 'Dormant').length;
      const completedCount = goals.filter((goal) => goal.status === 'Completed').length;
      const totalSaved = goals.reduce((sum, goal) => sum + goal.currentAmount, 0);
      let status: SavingsSummary['status'] = 'No Goals';
      if (goals.length > 0) {
        if (activeCount > 0) {
          status = 'Active Goals';
        } else if (dormantCount > 0) {
          status = 'Dormant';
        } else {
          status = 'Completed';
        }
      }

      acc[user.id] = {
        goals,
        activeCount,
        dormantCount,
        completedCount,
        totalSaved,
        status,
      } satisfies SavingsSummary;

      return acc;
    }, {} as Record<string, SavingsSummary>);
  }, []);

  const documentsByUser = useMemo(() => {
    return mockMemberDocuments.reduce((acc, entry) => {
      acc[entry.userId] = entry;
      return acc;
    }, {} as Record<string, MemberDocuments>);
  }, []);

  const transactionsByUser = useMemo(() => {
    return mockTransactions.reduce((acc, transaction) => {
      if (!transaction.userId) {
        return acc;
      }
      if (!acc[transaction.userId]) {
        acc[transaction.userId] = [];
      }
      acc[transaction.userId]!.push(transaction);
      return acc;
    }, {} as Record<string, Transaction[]>);
  }, []);

  const decoratedUsers = useMemo(
    () =>
      mockUsers.map((user) => ({
        ...user,
        ...(overrides[user.id] ?? {}),
      })),
    [overrides],
  );

  const selectedUser = useMemo(
    () => decoratedUsers.find((user) => user.id === selectedUserId) ?? null,
    [decoratedUsers, selectedUserId],
  );

  const updateMember = (userId: string, patch: MemberOverride, message: { title: string; description: string }) => {
    setOverrides((previous) => ({
      ...previous,
      [userId]: {
        ...(previous[userId] ?? {}),
        ...patch,
      },
    }));
    toast(message);
  };

  const handleApproveKyc = (user: Member) => {
    updateMember(user.id, { kycStatus: 'Approved', status: 'Active', riskLevel: 'Low', flagged: false }, {
      title: 'KYC approved',
      description: `${user.name}'s documents are now marked as approved.`,
    });
  };

  const handleRejectKyc = (user: Member) => {
    updateMember(user.id, { kycStatus: 'Rejected', status: 'Inactive', riskLevel: 'High', flagged: true }, {
      title: 'KYC rejected',
      description: `${user.name} has been moved back to KYC review.`,
    });
  };

  const handleManualDeposit = (user: Member) => {
    toast({
      title: 'Manual deposit initiated',
      description: `Begin a wallet top-up workflow for ${user.name}.`,
    });
  };

  const handleManualWithdrawal = (user: Member) => {
    toast({
      title: 'Manual withdrawal initiated',
      description: `Start a withdrawal flow for ${user.name}'s wallet.`,
    });
  };

  const handleFlagAccount = (user: Member) => {
    updateMember(user.id, { status: 'In Review', riskLevel: 'High', flagged: true }, {
      title: 'Account flagged for review',
      description: `${user.name} has been escalated to the compliance queue.`,
    });
  };

  const filteredUsers = useMemo(() => {
    return decoratedUsers.filter((user) => {
      const searchTarget = `${user.name} ${user.phone} ${user.email}`.toLowerCase();
      const matchesSearch = searchTarget.includes(searchQuery.toLowerCase());

      const matchesKyc =
        kycFilter === 'all' ||
        (kycFilter === 'approved' && user.kycStatus === 'Approved') ||
        (kycFilter === 'pending' && user.kycStatus === 'Pending') ||
        (kycFilter === 'rejected' && user.kycStatus === 'Rejected');

      const summary = savingsSummaryByUser[user.id];
      const matchesSavings =
        savingsFilter === 'all' ||
        (savingsFilter === 'active' && summary.status === 'Active Goals') ||
        (savingsFilter === 'dormant' && summary.status === 'Dormant') ||
        (savingsFilter === 'completed' && summary.status === 'Completed') ||
        (savingsFilter === 'none' && summary.status === 'No Goals');

      const matchesRisk = riskFilter === 'all' || user.riskLevel === riskFilter;

      return matchesSearch && matchesKyc && matchesSavings && matchesRisk;
    });
  }, [decoratedUsers, kycFilter, riskFilter, savingsFilter, savingsSummaryByUser, searchQuery]);

  const resetFilters = () => {
    setSearchQuery('');
    setKycFilter('all');
    setSavingsFilter('all');
    setRiskFilter('all');
  };

  const openDrawerForUser = (user: Member) => {
    setSelectedUserId(user.id);
    setDrawerOpen(true);
  };

  const closeDrawer = (open: boolean) => {
    setDrawerOpen(open);
    if (!open) {
      setSelectedUserId(null);
    }
  };

  const pendingKycCount = decoratedUsers.filter((user) => user.kycStatus === 'Pending').length;
  const highRiskCount = decoratedUsers.filter((user) => user.riskLevel === 'High').length;
  const flaggedCount = decoratedUsers.filter((user) => user.flagged).length;

  return (
    <div className="space-y-6">
      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Member Operations</CardTitle>
          <CardDescription>
            Search, filter, and action Sankofa members as they progress through onboarding, savings, and compliance workflows.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <div className="rounded-lg border border-border/80 bg-muted/40 p-4">
              <p className="text-sm text-muted-foreground">Total members</p>
              <p className="text-2xl font-semibold">{decoratedUsers.length}</p>
            </div>
            <div className="rounded-lg border border-border/80 bg-warning/5 p-4">
              <p className="text-sm text-muted-foreground">KYC pending</p>
              <p className="text-2xl font-semibold">{pendingKycCount}</p>
            </div>
            <div className="rounded-lg border border-border/80 bg-destructive/5 p-4">
              <p className="text-sm text-muted-foreground">High-risk wallets</p>
              <p className="text-2xl font-semibold">{highRiskCount}</p>
            </div>
            <div className="rounded-lg border border-border/80 bg-primary/5 p-4">
              <p className="text-sm text-muted-foreground">Flagged for review</p>
              <p className="text-2xl font-semibold">{flaggedCount}</p>
            </div>
          </div>

          <div className="grid gap-4 md:grid-cols-4">
            <div className="md:col-span-2 space-y-2">
              <Label htmlFor="member-search">Search members</Label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  id="member-search"
                  placeholder="Search by name, phone, or email"
                  value={searchQuery}
                  onChange={(event) => setSearchQuery(event.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="kyc-filter">KYC status</Label>
              <Select value={kycFilter} onValueChange={setKycFilter}>
                <SelectTrigger id="kyc-filter">
                  <SelectValue placeholder="All" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All statuses</SelectItem>
                  <SelectItem value="approved">Approved</SelectItem>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="rejected">Rejected</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="savings-filter">Savings participation</Label>
              <Select value={savingsFilter} onValueChange={setSavingsFilter}>
                <SelectTrigger id="savings-filter">
                  <SelectValue placeholder="All" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All members</SelectItem>
                  <SelectItem value="active">Has active goals</SelectItem>
                  <SelectItem value="dormant">Dormant goals</SelectItem>
                  <SelectItem value="completed">Completed goals</SelectItem>
                  <SelectItem value="none">No goals</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="risk-filter">Wallet risk</Label>
              <Select value={riskFilter} onValueChange={setRiskFilter}>
                <SelectTrigger id="risk-filter">
                  <SelectValue placeholder="All" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All risk levels</SelectItem>
                  <SelectItem value="Low">Low</SelectItem>
                  <SelectItem value="Medium">Medium</SelectItem>
                  <SelectItem value="High">High</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Member</TableHead>
                  <TableHead>KYC</TableHead>
                  <TableHead>Savings</TableHead>
                  <TableHead>Wallet</TableHead>
                  <TableHead>Risk</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredUsers.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7}>
                      <div className="flex flex-col items-center justify-center py-12 text-center">
                        <p className="text-sm font-medium">No members match your filters.</p>
                        <p className="mt-1 text-sm text-muted-foreground">
                          Adjust your search criteria or reset the filters to see more results.
                        </p>
                        <Button variant="ghost" size="sm" className="mt-3" onClick={resetFilters}>
                          Reset filters
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredUsers.map((user) => {
                    const summary = savingsSummaryByUser[user.id];

                    return (
                      <TableRow key={user.id}>
                        <TableCell>
                          <div className="flex items-start gap-3">
                            <Avatar>
                              <AvatarFallback>{user.avatar}</AvatarFallback>
                            </Avatar>
                            <div className="space-y-1">
                              <p className="font-medium leading-none">{user.name}</p>
                              <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted-foreground">
                                <span className="flex items-center gap-1">
                                  <Phone className="h-3 w-3" />
                                  {user.phone}
                                </span>
                                <span className="flex items-center gap-1">
                                  <MapPin className="h-3 w-3" />
                                  {user.location}
                                </span>
                              </div>
                              <p className="text-xs text-muted-foreground">
                                Last active {formatDateTime(user.lastActive)}
                              </p>
                            </div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <StatusBadge status={user.kycStatus} />
                        </TableCell>
                        <TableCell>
                          <div className="space-y-1">
                            <p className="text-sm font-medium">{getSavingsLabel(summary)}</p>
                            <p className="text-xs text-muted-foreground">
                              {currencyFormatter.format(summary.totalSaved)} saved
                            </p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="space-y-1">
                            <p className="text-sm font-semibold">
                              {currencyFormatter.format(user.walletBalance)}
                            </p>
                            <p className="text-xs text-muted-foreground">Joined {formatDate(user.joinedDate)}</p>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex flex-col gap-1">
                            <Badge variant="outline" className={cn('w-fit font-medium', riskTone[user.riskLevel] ?? '')}>
                              {user.riskLevel} risk
                            </Badge>
                            {user.flagged && (
                              <Badge variant="destructive" className="w-fit">
                                Flagged
                              </Badge>
                            )}
                          </div>
                        </TableCell>
                        <TableCell>
                          <StatusBadge status={user.status} />
                        </TableCell>
                        <TableCell className="text-right">
                          <div className="flex justify-end gap-2">
                            <Button variant="ghost" size="sm" onClick={() => openDrawerForUser(user)}>
                              View profile
                            </Button>
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="icon">
                                  <MoreHorizontal className="h-4 w-4" />
                                  <span className="sr-only">Open quick actions</span>
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuLabel>Quick actions</DropdownMenuLabel>
                                <DropdownMenuItem onSelect={() => handleApproveKyc(user)}>
                                  <CheckCircle2 className="mr-2 h-4 w-4" /> Approve KYC
                                </DropdownMenuItem>
                                <DropdownMenuItem onSelect={() => handleRejectKyc(user)}>
                                  <XCircle className="mr-2 h-4 w-4" /> Reject KYC
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem onSelect={() => handleManualDeposit(user)}>
                                  <Wallet className="mr-2 h-4 w-4" /> Manual deposit
                                </DropdownMenuItem>
                                <DropdownMenuItem onSelect={() => handleManualWithdrawal(user)}>
                                  <Landmark className="mr-2 h-4 w-4" /> Manual withdrawal
                                </DropdownMenuItem>
                                <DropdownMenuSeparator />
                                <DropdownMenuItem onSelect={() => handleFlagAccount(user)}>
                                  <Flag className="mr-2 h-4 w-4" /> Flag for review
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </div>
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
          <div className="flex flex-col gap-2 text-sm text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
            <p>
              Showing <span className="font-medium text-foreground">{filteredUsers.length}</span> of{' '}
              <span className="font-medium text-foreground">{decoratedUsers.length}</span> members
            </p>
            <p>
              Filters — KYC: <span className="text-foreground">{kycFilter}</span>, Savings: <span className="text-foreground">{savingsFilter}</span>,
              Risk: <span className="text-foreground">{riskFilter}</span>
            </p>
          </div>
        </CardContent>
      </Card>

      <Drawer open={drawerOpen} onOpenChange={closeDrawer}>
        <DrawerContent className="sm:left-1/2 sm:w-full sm:max-w-4xl sm:-translate-x-1/2 sm:rounded-t-[24px]">
          {selectedUser ? (
            <div className="mx-auto w-full max-w-4xl px-4 pb-4">
              <DrawerHeader className="px-0">
                <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                  <div className="flex items-center gap-3">
                    <Avatar className="h-12 w-12 text-lg">
                      <AvatarFallback>{selectedUser.avatar}</AvatarFallback>
                    </Avatar>
                    <div>
                      <DrawerTitle className="text-xl">{selectedUser.name}</DrawerTitle>
                      <DrawerDescription>
                        Member since {formatDate(selectedUser.joinedDate)} · Last active {formatDateTime(selectedUser.lastActive)}
                      </DrawerDescription>
                    </div>
                  </div>
                  <div className="flex flex-wrap items-center gap-2">
                    <StatusBadge status={selectedUser.kycStatus} />
                    <Badge variant="outline" className={cn('font-medium', riskTone[selectedUser.riskLevel] ?? '')}>
                      {selectedUser.riskLevel} risk
                    </Badge>
                    {selectedUser.flagged && <Badge variant="destructive">Flagged</Badge>}
                  </div>
                </div>
              </DrawerHeader>
              <ScrollArea className="max-h-[60vh] pr-3">
                <div className="space-y-6 px-1 pb-4">
                  <section>
                    <h3 className="text-sm font-semibold text-muted-foreground">Profile overview</h3>
                    <div className="mt-3 grid gap-4 sm:grid-cols-2">
                      <div className="space-y-1 rounded-lg border p-4">
                        <p className="text-xs text-muted-foreground">Contact</p>
                        <div className="flex flex-col gap-2 text-sm">
                          <span className="flex items-center gap-2 text-foreground">
                            <Phone className="h-4 w-4 text-muted-foreground" />
                            {selectedUser.phone}
                          </span>
                          <span className="flex items-center gap-2">
                            <Mail className="h-4 w-4 text-muted-foreground" />
                            {selectedUser.email}
                          </span>
                          <span className="flex items-center gap-2">
                            <MapPin className="h-4 w-4 text-muted-foreground" />
                            {selectedUser.location}
                          </span>
                        </div>
                      </div>
                      <div className="space-y-1 rounded-lg border p-4">
                        <p className="text-xs text-muted-foreground">Account milestones</p>
                        <div className="flex flex-col gap-2 text-sm">
                          <span className="flex items-center gap-2">
                            <CalendarDays className="h-4 w-4 text-muted-foreground" />
                            Joined {formatDate(selectedUser.joinedDate)}
                          </span>
                          <span className="flex items-center gap-2">
                            <StatusBadge status={selectedUser.status} />
                          </span>
                        </div>
                      </div>
                    </div>
                  </section>

                  <Separator />

                  <section>
                    <h3 className="text-sm font-semibold text-muted-foreground">Wallet snapshot</h3>
                    <div className="mt-3 grid gap-4 sm:grid-cols-3">
                      <div className="rounded-lg border bg-muted/40 p-4">
                        <p className="text-xs text-muted-foreground">Wallet balance</p>
                        <p className="text-2xl font-semibold text-foreground">
                          {currencyFormatter.format(selectedUser.walletBalance)}
                        </p>
                        <div className="mt-2 flex items-center gap-1 text-xs text-muted-foreground">
                          {selectedUser.walletDelta >= 0 ? (
                            <ArrowUpRight className="h-3 w-3 text-success" />
                          ) : (
                            <ArrowDownRight className="h-3 w-3 text-destructive" />
                          )}
                          <span>{Math.abs(selectedUser.walletDelta).toFixed(1)}% vs last 7 days</span>
                        </div>
                      </div>
                      <div className="rounded-lg border bg-muted/40 p-4">
                        <p className="text-xs text-muted-foreground">Savings goals</p>
                        <p className="text-lg font-semibold text-foreground">
                          {getSavingsLabel(savingsSummaryByUser[selectedUser.id]) || 'No goals'}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {currencyFormatter.format(savingsSummaryByUser[selectedUser.id].totalSaved)} saved to date
                        </p>
                      </div>
                      <div className="rounded-lg border bg-muted/40 p-4">
                        <p className="text-xs text-muted-foreground">Recent activity</p>
                        <p className="text-lg font-semibold text-foreground">
                          {(transactionsByUser[selectedUser.id]?.[0]?.type ?? '—')}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {transactionsByUser[selectedUser.id]?.[0]?.date ?? 'No transactions logged'}
                        </p>
                      </div>
                    </div>
                  </section>

                  <Separator />

                  <section>
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="text-sm font-semibold text-muted-foreground">Active savings goals</h3>
                      <span className="text-xs text-muted-foreground">
                        {savingsSummaryByUser[selectedUser.id].goals.length} goal(s)
                      </span>
                    </div>
                    <div className="mt-3 space-y-3">
                      {savingsSummaryByUser[selectedUser.id].goals.length === 0 ? (
                        <p className="text-sm text-muted-foreground">No savings goals are associated with this member.</p>
                      ) : (
                        savingsSummaryByUser[selectedUser.id].goals.map((goal) => {
                          const progress = Math.min(
                            100,
                            Math.round((goal.currentAmount / goal.targetAmount) * 100),
                          );

                          return (
                            <div key={goal.id} className="rounded-lg border p-4">
                              <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                                <div>
                                  <p className="text-sm font-semibold text-foreground">{goal.title}</p>
                                  <p className="text-xs text-muted-foreground">
                                    Target {currencyFormatter.format(goal.targetAmount)} · Due {formatDate(goal.deadline)}
                                  </p>
                                </div>
                                <Badge
                                  variant="outline"
                                  className={cn(
                                    'w-fit text-xs',
                                    goal.status === 'Active'
                                      ? 'bg-success/10 text-success border-success/20'
                                      : goal.status === 'Dormant'
                                      ? 'bg-warning/10 text-warning border-warning/20'
                                      : 'bg-muted text-muted-foreground border-border',
                                  )}
                                >
                                  {goal.status}
                                </Badge>
                              </div>
                              <div className="mt-3 space-y-1">
                                <Progress value={progress} className="h-2" />
                                <div className="flex justify-between text-xs text-muted-foreground">
                                  <span>{currencyFormatter.format(goal.currentAmount)} saved</span>
                                  <span>{progress}% complete</span>
                                </div>
                                <p className="text-xs text-muted-foreground">
                                  Last contribution {goal.lastContributionDate ? formatDate(goal.lastContributionDate) : '—'} · Next{' '}
                                  {goal.nextContributionDate ? formatDate(goal.nextContributionDate) : 'not scheduled'}
                                </p>
                              </div>
                            </div>
                          );
                        })
                      )}
                    </div>
                  </section>

                  <Separator />

                  <section>
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="text-sm font-semibold text-muted-foreground">Recent transactions</h3>
                      <span className="text-xs text-muted-foreground">Latest 5 entries</span>
                    </div>
                    <div className="mt-3 rounded-lg border">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Date</TableHead>
                            <TableHead>Type</TableHead>
                            <TableHead>Amount</TableHead>
                            <TableHead>Status</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {(() => {
                            const transactions = [...(transactionsByUser[selectedUser.id] ?? [])]
                              .sort(
                                (a, b) =>
                                  new Date(b.timestamp ?? b.date).getTime() -
                                  new Date(a.timestamp ?? a.date).getTime(),
                              )
                              .slice(0, 5);

                            if (transactions.length === 0) {
                              return (
                                <TableRow>
                                  <TableCell colSpan={4} className="text-center text-sm text-muted-foreground">
                                    No wallet transactions recorded yet.
                                  </TableCell>
                                </TableRow>
                              );
                            }

                            return transactions.map((transaction) => (
                              <TableRow key={transaction.id}>
                                <TableCell className="text-sm text-muted-foreground">{transaction.date}</TableCell>
                                <TableCell className="text-sm font-medium">{transaction.type}</TableCell>
                                <TableCell className="text-sm font-medium">
                                  {currencyFormatter.format(transaction.amount)}
                                </TableCell>
                                <TableCell>
                                  <StatusBadge status={transaction.status} />
                                </TableCell>
                              </TableRow>
                            ));
                          })()}
                        </TableBody>
                      </Table>
                    </div>
                  </section>

                  <Separator />

                  <section>
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="text-sm font-semibold text-muted-foreground">KYC documents</h3>
                      <span className="text-xs text-muted-foreground">
                        Updated {formatDate(documentsByUser[selectedUser.id]?.updatedAt ?? selectedUser.joinedDate)}
                      </span>
                    </div>
                    <div className="mt-3 space-y-3">
                      {documentsByUser[selectedUser.id] ? (
                        documentsByUser[selectedUser.id].documents.map((document) => (
                          <div key={document.id} className="rounded-lg border p-4">
                            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                              <div>
                                <p className="text-sm font-semibold text-foreground">{document.type}</p>
                                <p className="text-xs text-muted-foreground">Reference {document.reference ?? '—'}</p>
                              </div>
                              <Badge
                                variant="outline"
                                className={cn('w-fit text-xs font-medium', documentTone[document.status] ?? '')}
                              >
                                {document.status}
                              </Badge>
                            </div>
                            <p className="mt-2 text-xs text-muted-foreground">
                              Uploaded {document.uploadedAt ? formatDate(document.uploadedAt) : '—'}
                            </p>
                          </div>
                        ))
                      ) : (
                        <p className="text-sm text-muted-foreground">No documents uploaded yet.</p>
                      )}
                      {documentsByUser[selectedUser.id]?.pendingAction && (
                        <div className="rounded-lg border border-warning/40 bg-warning/5 p-3 text-xs text-warning">
                          Next action: {documentsByUser[selectedUser.id]!.pendingAction}
                        </div>
                      )}
                    </div>
                  </section>
                </div>
              </ScrollArea>
              <DrawerFooter className="border-t border-border px-0">
                <div className="flex flex-col gap-2 sm:flex-row sm:flex-wrap">
                  <Button onClick={() => handleApproveKyc(selectedUser)} size="sm">
                    <CheckCircle2 className="mr-2 h-4 w-4" /> Approve KYC
                  </Button>
                  <Button variant="outline" onClick={() => handleRejectKyc(selectedUser)} size="sm">
                    <XCircle className="mr-2 h-4 w-4" /> Reject KYC
                  </Button>
                  <Button variant="outline" onClick={() => handleManualDeposit(selectedUser)} size="sm">
                    <Wallet className="mr-2 h-4 w-4" /> Manual deposit
                  </Button>
                  <Button variant="outline" onClick={() => handleManualWithdrawal(selectedUser)} size="sm">
                    <Landmark className="mr-2 h-4 w-4" /> Manual withdrawal
                  </Button>
                  <Button variant="destructive" onClick={() => handleFlagAccount(selectedUser)} size="sm">
                    <Flag className="mr-2 h-4 w-4" /> Flag for review
                  </Button>
                </div>
                <DrawerClose asChild>
                  <Button variant="ghost" className="w-full sm:w-auto">
                    Close
                  </Button>
                </DrawerClose>
              </DrawerFooter>
            </div>
          ) : null}
        </DrawerContent>
      </Drawer>
    </div>
  );
}

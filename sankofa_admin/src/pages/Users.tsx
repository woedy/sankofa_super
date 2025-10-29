import { useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Search,
  MoreHorizontal,
  CheckCircle2,
  XCircle,
  Wallet as WalletIcon,
  Landmark,
  Flag,
  Phone,
  Mail,
  ArrowUpRight,
  ArrowDownRight,
  RefreshCcw,
} from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { StatusBadge } from '@/components/ui/badge-variants';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
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
import { ScrollArea } from '@/components/ui/scroll-area';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { Progress } from '@/components/ui/progress';
import { useToast } from '@/hooks/use-toast';
import { useAuthorizedApi } from '@/lib/auth';
import type { AdminGroup, AdminTransaction, AdminUserDetail, AdminUserSummary, PaginatedResponse } from '@/lib/types';

const formatCurrency = (value: string | number) => {
  const numeric = typeof value === 'string' ? Number(value) : value;
  return `GH₵ ${numeric.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

const formatDate = (value: string | null | undefined) => {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
};

const formatDateTime = (value: string | null | undefined) => {
  if (!value) return '—';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleString('en-GB', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const getInitials = (value: string) => {
  return value
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join('') || 'SM';
};

const kycLabels: Record<string, string> = {
  approved: 'Approved',
  pending: 'Pending',
  submitted: 'Submitted',
  rejected: 'Rejected',
};

const riskTone: Record<'Low' | 'Medium' | 'High', string> = {
  Low: 'bg-success/10 text-success border-success/20',
  Medium: 'bg-warning/10 text-warning border-warning/20',
  High: 'bg-destructive/10 text-destructive border-destructive/20',
};

type SavingsFilter = 'all' | 'active' | 'dormant' | 'completed' | 'none';
type RiskFilter = 'all' | 'Low' | 'Medium' | 'High';

type DecoratedUser = AdminUserSummary & {
  displayKyc: string;
  riskLevel: 'Low' | 'Medium' | 'High';
  savingsStatus: 'Active Goals' | 'Dormant' | 'Completed' | 'No Goals';
  savingsLabel: string;
  savingsSummary: string;
  flagged: boolean;
  walletAmount: number;
};

const deriveSavingsStatus = (user: AdminUserSummary): Pick<DecoratedUser, 'savingsStatus' | 'savingsLabel' | 'savingsSummary'> => {
  const walletAmount = Number(user.wallet_balance ?? 0);
  if (user.savings_goal_count === 0) {
    return {
      savingsStatus: 'No Goals',
      savingsLabel: 'No goals',
      savingsSummary: 'Members has not created any savings goals yet.',
    };
  }

  if (walletAmount > 0) {
    return {
      savingsStatus: 'Active Goals',
      savingsLabel: `${user.savings_goal_count} goals`,
      savingsSummary: 'Actively contributing to savings goals.',
    };
  }

  if (user.pending_transactions > 0) {
    return {
      savingsStatus: 'Dormant',
      savingsLabel: `${user.savings_goal_count} goals`,
      savingsSummary: 'Pending transactions suggest stalled savings activity.',
    };
  }

  return {
    savingsStatus: 'Completed',
    savingsLabel: `${user.savings_goal_count} goals`,
    savingsSummary: 'Savings goals have been completed or paused.',
  };
};

const deriveRiskLevel = (user: AdminUserSummary): 'Low' | 'Medium' | 'High' => {
  if (user.pending_transactions >= 3) {
    return 'High';
  }
  if (user.pending_transactions > 0) {
    return 'Medium';
  }
  return 'Low';
};

export default function Users() {
  const api = useAuthorizedApi();
  const queryClient = useQueryClient();
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [kycFilter, setKycFilter] = useState('all');
  const [savingsFilter, setSavingsFilter] = useState<SavingsFilter>('all');
  const [riskFilter, setRiskFilter] = useState<RiskFilter>('all');
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  const buildQueryParams = () => {
    const params = new URLSearchParams();
    if (searchQuery) params.set('search', searchQuery);
    if (kycFilter !== 'all') params.set('kyc_status', kycFilter);
    if (riskFilter !== 'all') params.set('risk', riskFilter.toLowerCase());
    return params.toString();
  };

  const usersQuery = useQuery<PaginatedResponse<AdminUserSummary>>({
    queryKey: ['admin-users', searchQuery, kycFilter, riskFilter],
    queryFn: () => api(`/api/admin/users/?${buildQueryParams()}`),
    keepPreviousData: true,
  });

  const userDetailQuery = useQuery<AdminUserDetail>({
    queryKey: ['admin-user-detail', selectedUserId],
    queryFn: () => api(`/api/admin/users/${selectedUserId}/`),
    enabled: Boolean(selectedUserId && isDrawerOpen),
  });

  const updateUserMutation = useMutation({
    mutationFn: (payload: { id: string; body: Partial<Pick<AdminUserSummary, 'kyc_status' | 'is_active'>> }) =>
      api(`/api/admin/users/${payload.id}/`, {
        method: 'PATCH',
        body: JSON.stringify(payload.body),
        headers: { 'Content-Type': 'application/json' },
      }),
    onSuccess: (_, variables) => {
      toast({ title: 'User updated', description: 'Changes saved successfully.' });
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      queryClient.invalidateQueries({ queryKey: ['admin-user-detail', variables.id] });
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to update user';
      toast({ title: 'Update failed', description: message, variant: 'destructive' });
    },
  });

  const users = usersQuery.data?.results ?? [];

  const decoratedUsers = useMemo<DecoratedUser[]>(() => {
    return users.map((user) => {
      const displayKyc = kycLabels[user.kyc_status] ?? user.kyc_status;
      const riskLevel = deriveRiskLevel(user);
      const savingsMeta = deriveSavingsStatus(user);
      const walletAmount = Number(user.wallet_balance ?? 0);

      return {
        ...user,
        displayKyc,
        riskLevel,
        savingsStatus: savingsMeta.savingsStatus,
        savingsLabel: savingsMeta.savingsLabel,
        savingsSummary: savingsMeta.savingsSummary,
        flagged: !user.is_active,
        walletAmount,
      };
    });
  }, [users]);

  const normalizedSearch = searchQuery.trim().toLowerCase();

  const filteredUsers = useMemo(() => {
    return decoratedUsers.filter((user) => {
      if (kycFilter !== 'all' && user.kyc_status !== kycFilter) {
        return false;
      }

      if (savingsFilter !== 'all') {
        if (savingsFilter === 'none' && user.savingsStatus !== 'No Goals') return false;
        if (savingsFilter === 'active' && user.savingsStatus !== 'Active Goals') return false;
        if (savingsFilter === 'dormant' && user.savingsStatus !== 'Dormant') return false;
        if (savingsFilter === 'completed' && user.savingsStatus !== 'Completed') return false;
      }

      if (riskFilter !== 'all' && user.riskLevel !== riskFilter) {
        return false;
      }

      if (normalizedSearch) {
        const haystack = [user.full_name, user.phone_number, user.email ?? '']
          .join(' ')
          .toLowerCase();
        if (!haystack.includes(normalizedSearch)) {
          return false;
        }
      }

      return true;
    });
  }, [decoratedUsers, kycFilter, normalizedSearch, riskFilter, savingsFilter]);

  const summary = useMemo(() => {
    const totalMembers = decoratedUsers.length;
    const kycPending = decoratedUsers.filter((user) => user.kyc_status !== 'approved').length;
    const highRisk = decoratedUsers.filter((user) => user.riskLevel === 'High').length;
    const flagged = decoratedUsers.filter((user) => user.flagged).length;
    return { totalMembers, kycPending, highRisk, flagged };
  }, [decoratedUsers]);

  const openDrawer = (id: string) => {
    setSelectedUserId(id);
    setIsDrawerOpen(true);
  };

  const closeDrawer = (open: boolean) => {
    setIsDrawerOpen(open);
    if (!open) {
      setSelectedUserId(null);
    }
  };

  const handleStatusChange = (user: DecoratedUser) => {
    updateUserMutation.mutate({ id: user.id, body: { is_active: !user.is_active } });
  };

  const handleApproveKyc = (user: DecoratedUser) => {
    updateUserMutation.mutate({ id: user.id, body: { kyc_status: 'approved' } });
  };

  const handleRejectKyc = (user: DecoratedUser) => {
    updateUserMutation.mutate({ id: user.id, body: { kyc_status: 'rejected' } });
  };

  const handleManualDeposit = (user: DecoratedUser) => {
    toast({
      title: 'Manual deposit queued',
      description: `Schedule a deposit for ${user.full_name} through the finance queue.`,
    });
  };

  const handleManualWithdrawal = (user: DecoratedUser) => {
    toast({
      title: 'Withdrawal review created',
      description: `${user.full_name} will receive a payout once compliance confirms.`,
    });
  };

  const handleFlagAccount = (user: DecoratedUser) => {
    updateUserMutation.mutate({ id: user.id, body: { is_active: false } });
  };

  const resetFilters = () => {
    setKycFilter('all');
    setSavingsFilter('all');
    setRiskFilter('all');
    setSearchQuery('');
  };

  const emptyState = !usersQuery.isLoading && filteredUsers.length === 0;

  const renderDrawerContent = () => {
    if (userDetailQuery.isLoading) {
      return (
        <div className="space-y-4 p-6">
          {Array.from({ length: 5 }).map((_, index) => (
            <Skeleton key={index} className="h-24 w-full rounded-xl" />
          ))}
        </div>
      );
    }

    if (!userDetailQuery.data) {
      return (
        <div className="p-6 text-sm text-muted-foreground">
          Unable to load additional details for this member.
        </div>
      );
    }

    const detail = userDetailQuery.data;

    return (
      <ScrollArea className="h-[70vh]">
        <div className="space-y-6 p-6 pr-8">
          <section className="space-y-3">
            <h3 className="text-sm font-semibold text-muted-foreground">Member overview</h3>
            <Card className="border border-border">
              <CardContent className="flex items-center justify-between p-4">
                <div className="space-y-1">
                  <p className="text-base font-semibold text-foreground">{detail.full_name}</p>
                  <div className="flex flex-wrap gap-3 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Phone className="h-3 w-3" /> {detail.phone_number}
                    </span>
                    {detail.email && (
                      <span className="flex items-center gap-1">
                        <Mail className="h-3 w-3" /> {detail.email}
                      </span>
                    )}
                  </div>
                </div>
                <Badge variant="outline">{detail.is_active ? 'Active' : 'Suspended'}</Badge>
              </CardContent>
            </Card>
          </section>

          <section className="space-y-3">
            <h3 className="text-sm font-semibold text-muted-foreground">Wallet snapshot</h3>
            {detail.wallet ? (
              <Card className="border border-border">
                <CardContent className="space-y-2 p-4">
                  <p className="text-sm text-muted-foreground">{detail.wallet.name}</p>
                  <p className="text-2xl font-semibold text-foreground">{formatCurrency(detail.wallet.balance)}</p>
                  <p className="text-xs text-muted-foreground">Updated {formatDateTime(detail.wallet.updated_at)}</p>
                </CardContent>
              </Card>
            ) : (
              <p className="text-sm text-muted-foreground">Wallet not provisioned.</p>
            )}
          </section>

          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-muted-foreground">Savings goals</h3>
              <Badge variant="outline">{detail.savings_goals.length} tracked</Badge>
            </div>
            {detail.savings_goals.length === 0 ? (
              <p className="text-sm text-muted-foreground">This member has not set up any savings goals.</p>
            ) : (
              <div className="space-y-3">
                {detail.savings_goals.map((goal) => (
                  <Card key={goal.id} className="border border-border">
                    <CardContent className="space-y-2 p-4">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-sm font-semibold text-foreground">{goal.title}</p>
                          <p className="text-xs text-muted-foreground">{goal.category}</p>
                        </div>
                        <Badge variant="outline">{formatCurrency(goal.current_amount)}</Badge>
                      </div>
                      <Progress value={goal.progress} className="h-2" />
                      <div className="flex items-center justify-between text-xs text-muted-foreground">
                        <span>Target {formatCurrency(goal.target_amount)}</span>
                        <span>Due {formatDate(goal.deadline)}</span>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </section>

          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-muted-foreground">Groups</h3>
              <Badge variant="outline">{detail.groups.length} joined</Badge>
            </div>
            {detail.groups.length === 0 ? (
              <p className="text-sm text-muted-foreground">Member has not joined any Susu groups.</p>
            ) : (
              <div className="space-y-2">
                {detail.groups.map((group: AdminGroup) => (
                  <Card key={group.id} className="border border-border">
                    <CardContent className="flex items-center justify-between p-4">
                      <div>
                        <p className="text-sm font-semibold text-foreground">{group.name}</p>
                        <p className="text-xs text-muted-foreground">Next payout {formatDate(group.next_payout_date)}</p>
                      </div>
                      <Badge variant="outline">{group.member_count} members</Badge>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </section>

          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-muted-foreground">Recent transactions</h3>
              <Badge variant="outline">{detail.recent_transactions.length}</Badge>
            </div>
            {detail.recent_transactions.length === 0 ? (
              <p className="text-sm text-muted-foreground">No recent activity recorded.</p>
            ) : (
              <div className="space-y-2">
                {detail.recent_transactions.map((transaction: AdminTransaction) => (
                  <div
                    key={transaction.id}
                    className="flex items-center justify-between rounded-lg border border-border p-3 text-sm"
                  >
                    <div className="space-y-1">
                      <p className="font-medium text-foreground">{transaction.transaction_type}</p>
                      <p className="text-xs text-muted-foreground">{transaction.description}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-semibold text-foreground">{formatCurrency(transaction.amount)}</p>
                      <p className="text-xs text-muted-foreground">{formatDateTime(transaction.occurred_at)}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>
      </ScrollArea>
    );
  };

  return (
    <div className="space-y-6">
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Card className="shadow-custom-md">
          <CardContent className="space-y-1 p-4">
            <p className="text-sm text-muted-foreground">Total members</p>
            <p className="text-2xl font-semibold text-foreground">{summary.totalMembers}</p>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardContent className="space-y-1 p-4">
            <p className="text-sm text-muted-foreground">KYC pending</p>
            <div className="flex items-center gap-2">
              <p className="text-2xl font-semibold text-warning">{summary.kycPending}</p>
              <Badge variant="outline" className="text-xs text-muted-foreground">
                Awaiting verification
              </Badge>
            </div>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardContent className="space-y-1 p-4">
            <p className="text-sm text-muted-foreground">High-risk wallets</p>
            <p className="text-2xl font-semibold text-destructive">{summary.highRisk}</p>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardContent className="space-y-1 p-4">
            <p className="text-sm text-muted-foreground">Flagged for review</p>
            <p className="text-2xl font-semibold text-primary">{summary.flagged}</p>
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader className="pb-4">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <CardTitle>Member operations</CardTitle>
              <CardDescription>Review onboarding progress, savings participation, and risk signals.</CardDescription>
            </div>
            <Button
              variant="outline"
              onClick={() => usersQuery.refetch()}
              disabled={usersQuery.isFetching}
            >
              <RefreshCcw className={`mr-2 h-4 w-4 ${usersQuery.isFetching ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-4 md:grid-cols-4">
            <div className="md:col-span-2 space-y-2">
              <label className="text-xs font-medium text-muted-foreground" htmlFor="member-search">
                Search members
              </label>
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
              <label className="text-xs font-medium text-muted-foreground" htmlFor="kyc-filter">
                KYC status
              </label>
              <Select value={kycFilter} onValueChange={setKycFilter}>
                <SelectTrigger id="kyc-filter">
                  <SelectValue placeholder="All" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All statuses</SelectItem>
                  <SelectItem value="approved">Approved</SelectItem>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="submitted">Submitted</SelectItem>
                  <SelectItem value="rejected">Rejected</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <label className="text-xs font-medium text-muted-foreground" htmlFor="savings-filter">
                Savings participation
              </label>
              <Select value={savingsFilter} onValueChange={(value) => setSavingsFilter(value as SavingsFilter)}>
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
              <label className="text-xs font-medium text-muted-foreground" htmlFor="risk-filter">
                Wallet risk
              </label>
              <Select value={riskFilter} onValueChange={(value) => setRiskFilter(value as RiskFilter)}>
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
                {usersQuery.isLoading ? (
                  <TableRow>
                    <TableCell colSpan={7}>
                      <Skeleton className="h-12 w-full" />
                    </TableCell>
                  </TableRow>
                ) : emptyState ? (
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
                  filteredUsers.map((user) => (
                    <TableRow key={user.id} onClick={() => openDrawer(user.id)} className="cursor-pointer hover:bg-muted/30">
                      <TableCell>
                        <div className="flex items-start gap-3">
                          <Avatar className="h-9 w-9">
                            <AvatarFallback>{getInitials(user.full_name)}</AvatarFallback>
                          </Avatar>
                          <div className="space-y-1">
                            <p className="font-medium leading-none text-foreground">{user.full_name}</p>
                            <div className="flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted-foreground">
                              <span className="flex items-center gap-1">
                                <Phone className="h-3 w-3" />
                                {user.phone_number}
                              </span>
                              {user.email && (
                                <span className="flex items-center gap-1">
                                  <Mail className="h-3 w-3" />
                                  {user.email}
                                </span>
                              )}
                            </div>
                            <p className="text-xs text-muted-foreground">Last login {formatDateTime(user.last_login)}</p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={user.displayKyc} />
                      </TableCell>
                      <TableCell>
                        <div className="space-y-1">
                          <p className="text-sm font-medium text-foreground">{user.savingsLabel}</p>
                          <p className="text-xs text-muted-foreground">{user.savingsSummary}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="space-y-1">
                          <p className="text-sm font-semibold text-foreground">{formatCurrency(user.wallet_balance)}</p>
                          <p className="flex items-center gap-1 text-xs text-muted-foreground">
                            <WalletIcon className="h-3 w-3" /> Pending {user.pending_transactions}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col gap-1">
                          <Badge variant="outline" className={`w-fit font-medium ${riskTone[user.riskLevel]}`}>
                            {user.riskLevel} risk
                          </Badge>
                          {user.flagged && <Badge variant="destructive">Flagged</Badge>}
                        </div>
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={user.is_active ? 'Active' : 'Suspended'} />
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={(event) => {
                              event.stopPropagation();
                              openDrawer(user.id);
                            }}
                          >
                            View profile
                          </Button>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" onClick={(event) => event.stopPropagation()}>
                                <MoreHorizontal className="h-4 w-4" />
                                <span className="sr-only">Open quick actions</span>
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              <DropdownMenuLabel>Quick actions</DropdownMenuLabel>
                              <DropdownMenuItem
                                onSelect={() => handleApproveKyc(user)}
                              >
                                <CheckCircle2 className="mr-2 h-4 w-4" /> Approve KYC
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onSelect={() => handleRejectKyc(user)}
                              >
                                <XCircle className="mr-2 h-4 w-4" /> Reject KYC
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem
                                onSelect={() => handleManualDeposit(user)}
                              >
                                <ArrowUpRight className="mr-2 h-4 w-4" /> Manual deposit
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onSelect={() => handleManualWithdrawal(user)}
                              >
                                <ArrowDownRight className="mr-2 h-4 w-4" /> Manual withdrawal
                              </DropdownMenuItem>
                              <DropdownMenuSeparator />
                              <DropdownMenuItem
                                onSelect={() => handleFlagAccount(user)}
                              >
                                <Flag className="mr-2 h-4 w-4" /> Flag for review
                              </DropdownMenuItem>
                              <DropdownMenuItem
                                onSelect={() => handleStatusChange(user)}
                              >
                                <Landmark className="mr-2 h-4 w-4" />
                                {user.is_active ? 'Suspend account' : 'Activate account'}
                              </DropdownMenuItem>
                            </DropdownMenuContent>
                          </DropdownMenu>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <Drawer open={isDrawerOpen} onOpenChange={closeDrawer}>
        <DrawerContent className="sm:max-w-2xl">
          <DrawerHeader>
            <DrawerTitle>Member profile</DrawerTitle>
            <DrawerDescription>Operational view of savings, groups, and recent transactions.</DrawerDescription>
          </DrawerHeader>
          {renderDrawerContent()}
          <DrawerFooter>
            <DrawerClose asChild>
              <Button variant="outline">Close</Button>
            </DrawerClose>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
    </div>
  );
}

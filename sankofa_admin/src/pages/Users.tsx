import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Search, Phone, Mail, Wallet, RefreshCcw } from 'lucide-react';

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
import { Badge } from '@/components/ui/badge';
import { Skeleton } from '@/components/ui/skeleton';
import { useToast } from '@/hooks/use-toast';
import { useAuthorizedApi } from '@/lib/auth';
import type { AdminGroup, AdminTransaction, AdminUserDetail, AdminUserSummary, PaginatedResponse } from '@/lib/types';

const formatCurrency = (value: string | number) => {
  const numeric = typeof value === 'string' ? Number(value) : value;
  return `GH₵ ${numeric.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

const formatDate = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
};

const kycLabels: Record<string, string> = {
  approved: 'Approved',
  pending: 'Pending',
  submitted: 'Submitted',
  rejected: 'Rejected',
};

export default function Users() {
  const api = useAuthorizedApi();
  const queryClient = useQueryClient();
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [kycFilter, setKycFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  const buildQueryParams = () => {
    const params = new URLSearchParams();
    if (searchQuery) params.set('search', searchQuery);
    if (kycFilter !== 'all') params.set('kyc_status', kycFilter);
    if (statusFilter !== 'all') params.set('status', statusFilter);
    return params.toString();
  };

  const usersQuery = useQuery<PaginatedResponse<AdminUserSummary>>({
    queryKey: ['admin-users', searchQuery, kycFilter, statusFilter],
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

  const users = usersQuery.data?.results ?? [];

  const handleStatusChange = (user: AdminUserSummary) => {
    updateUserMutation.mutate({ id: user.id, body: { is_active: !user.is_active } });
  };

  const handleApproveKyc = (user: AdminUserSummary) => {
    updateUserMutation.mutate({ id: user.id, body: { kyc_status: 'approved' } });
  };

  const renderTableBody = () => {
    if (usersQuery.isLoading) {
      return (
        <TableRow>
          <TableCell colSpan={7}>
            <Skeleton className="h-12 w-full" />
          </TableCell>
        </TableRow>
      );
    }

    if (users.length === 0) {
      return (
        <TableRow>
          <TableCell colSpan={7} className="text-center text-sm text-muted-foreground">
            No users found for the selected filters.
          </TableCell>
        </TableRow>
      );
    }

    return users.map((user) => {
      const kycStatusLabel = kycLabels[user.kyc_status] ?? user.kyc_status;
      return (
      <TableRow key={user.id} onClick={() => openDrawer(user.id)} className="cursor-pointer hover:bg-muted/30">
        <TableCell>
          <div className="flex flex-col">
            <span className="font-semibold text-foreground">{user.full_name}</span>
            <span className="text-xs text-muted-foreground">{user.phone_number}</span>
          </div>
        </TableCell>
        <TableCell>
          <StatusBadge status={kycStatusLabel} />
        </TableCell>
        <TableCell>{formatCurrency(user.wallet_balance)}</TableCell>
        <TableCell>
          <span className="text-sm text-muted-foreground">{user.groups_count} groups</span>
        </TableCell>
        <TableCell>
          <span className="text-sm text-muted-foreground">{user.savings_goal_count} goals</span>
        </TableCell>
        <TableCell>
          <StatusBadge status={user.is_active ? 'Active' : 'Suspended'} />
        </TableCell>
        <TableCell>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={(event) => {
                event.stopPropagation();
                handleStatusChange(user);
              }}
            >
              {user.is_active ? 'Suspend' : 'Activate'}
            </Button>
            {user.kyc_status !== 'approved' && (
              <Button
                variant="outline"
                size="sm"
                onClick={(event) => {
                  event.stopPropagation();
                  handleApproveKyc(user);
                }}
              >
                Approve KYC
              </Button>
            )}
          </div>
        </TableCell>
      </TableRow>
    );
    });
  };

  const detail = userDetailQuery.data;
  const savings = detail?.savings_goals ?? [];
  const transactions = detail?.recent_transactions ?? [];
  const groups = detail?.groups ?? [];

  return (
    <div className="space-y-6">
      <Card className="shadow-custom-md">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <CardTitle>Member Directory</CardTitle>
              <CardDescription>Review member status, KYC progress, and wallet balances</CardDescription>
            </div>
            <Button variant="outline" onClick={() => usersQuery.refetch()} disabled={usersQuery.isFetching}>
              <RefreshCcw className={`mr-2 h-4 w-4 ${usersQuery.isFetching ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Search by name, phone, or email"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={kycFilter} onValueChange={setKycFilter}>
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="KYC status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All KYC</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="submitted">Submitted</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
              </SelectContent>
            </Select>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Statuses</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Suspended</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="rounded-lg border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Member</TableHead>
                  <TableHead>KYC</TableHead>
                  <TableHead>Wallet</TableHead>
                  <TableHead>Groups</TableHead>
                  <TableHead>Savings</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="w-[220px]">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>{renderTableBody()}</TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <Drawer open={isDrawerOpen} onOpenChange={closeDrawer}>
        <DrawerContent className="sm:max-w-3xl">
          <DrawerHeader>
            <DrawerTitle>{detail?.full_name ?? 'Member Details'}</DrawerTitle>
            <DrawerDescription>{detail?.phone_number}</DrawerDescription>
          </DrawerHeader>
          {userDetailQuery.isLoading ? (
            <div className="space-y-4 p-6">
              <Skeleton className="h-24 w-full" />
              <Skeleton className="h-48 w-full" />
              <Skeleton className="h-48 w-full" />
            </div>
          ) : detail ? (
            <ScrollArea className="h-[70vh]">
              <div className="space-y-6 p-6 pr-8">
                <section className="space-y-3">
                  <h3 className="text-sm font-semibold text-muted-foreground">Profile</h3>
                  <div className="grid gap-3 sm:grid-cols-2">
                    <div className="rounded-lg border border-border p-4">
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Phone className="h-4 w-4" />
                        <span>{detail.phone_number}</span>
                      </div>
                      {detail.email && (
                        <div className="mt-2 flex items-center gap-2 text-sm text-muted-foreground">
                          <Mail className="h-4 w-4" />
                          <span>{detail.email}</span>
                        </div>
                      )}
                    </div>
                    <div className="rounded-lg border border-border p-4">
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Wallet className="h-4 w-4" />
                        <span>Wallet balance</span>
                      </div>
                      <p className="mt-2 text-lg font-semibold text-foreground">
                        {detail.wallet ? formatCurrency(detail.wallet.balance) : 'GH₵ 0.00'}
                      </p>
                      <p className="text-xs text-muted-foreground">
                        Updated {detail.wallet?.updated_at ? formatDate(detail.wallet.updated_at) : '—'}
                      </p>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="secondary">KYC: {kycLabels[detail.kyc_status] ?? detail.kyc_status}</Badge>
                    <Badge variant={detail.is_active ? 'default' : 'outline'}>
                      {detail.is_active ? 'Active' : 'Suspended'}
                    </Badge>
                    <Badge variant="outline">Pending cashflow: {detail.pending_transactions}</Badge>
                  </div>
                </section>

                <section className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-muted-foreground">Savings goals</h3>
                    <span className="text-xs text-muted-foreground">{savings.length} goals</span>
                  </div>
                  {savings.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No savings goals recorded.</p>
                  ) : (
                    <div className="space-y-3">
                      {savings.map((goal) => (
                        <div key={goal.id} className="rounded-lg border border-border p-4">
                          <div className="flex items-center justify-between">
                            <div>
                              <p className="font-semibold text-foreground">{goal.title}</p>
                              <p className="text-xs text-muted-foreground">Category: {goal.category}</p>
                            </div>
                            <Badge variant="outline">{Math.round(goal.progress * 100)}% funded</Badge>
                          </div>
                          <div className="mt-2 flex gap-6 text-sm text-muted-foreground">
                            <span>Target: {formatCurrency(goal.target_amount)}</span>
                            <span>Saved: {formatCurrency(goal.current_amount)}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </section>

                <section className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-muted-foreground">Recent transactions</h3>
                    <span className="text-xs text-muted-foreground">Last {transactions.length} records</span>
                  </div>
                  {transactions.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No transactions recorded.</p>
                  ) : (
                    <div className="space-y-3">
                      {transactions.map((transaction: AdminTransaction) => {
                        const statusLabel = transaction.status
                          ? transaction.status.charAt(0).toUpperCase() + transaction.status.slice(1)
                          : transaction.status;
                        return (
                          <div key={transaction.id} className="rounded-lg border border-border p-4">
                          <div className="flex items-center justify-between text-sm">
                            <span className="font-medium text-foreground capitalize">{transaction.transaction_type}</span>
                            <StatusBadge status={statusLabel} />
                          </div>
                          <p className="mt-1 text-sm text-muted-foreground">{transaction.description}</p>
                          <div className="mt-2 flex items-center justify-between text-sm">
                            <span>{formatCurrency(transaction.amount)}</span>
                            <span className="text-muted-foreground">{formatDate(transaction.occurred_at)}</span>
                          </div>
                          {transaction.reference && (
                            <p className="text-xs text-muted-foreground">Reference: {transaction.reference}</p>
                          )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </section>

                <section className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-muted-foreground">Groups</h3>
                    <span className="text-xs text-muted-foreground">{groups.length} memberships</span>
                  </div>
                  {groups.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No active group memberships.</p>
                  ) : (
                    <div className="space-y-3">
                      {groups.map((group: AdminGroup) => (
                        <div key={group.id} className="rounded-lg border border-border p-4">
                          <div className="flex items-center justify-between">
                            <div>
                              <p className="font-semibold text-foreground">{group.name}</p>
                              <p className="text-xs text-muted-foreground">{group.location}</p>
                            </div>
                            <Badge variant="outline">{group.member_count} members</Badge>
                          </div>
                          <p className="mt-2 text-sm text-muted-foreground">Contribution: {formatCurrency(group.contribution_amount)}</p>
                          <p className="text-xs text-muted-foreground">
                            Next payout {formatDate(group.next_payout_date)}
                          </p>
                        </div>
                      ))}
                    </div>
                  )}
                </section>
              </div>
            </ScrollArea>
          ) : (
            <div className="p-6 text-sm text-muted-foreground">Select a user to see detailed activity.</div>
          )}
          <DrawerFooter className="flex items-center justify-end gap-2">
            <DrawerClose asChild>
              <Button variant="outline">Close</Button>
            </DrawerClose>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
    </div>
  );
}

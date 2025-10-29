import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Search, RefreshCcw, Download } from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
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
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { useAuthorizedApi } from '@/lib/auth';
import type { AdminTransaction, PaginatedResponse } from '@/lib/types';

const formatCurrency = (value: string | number) => {
  const numeric = typeof value === 'string' ? Number(value) : value;
  return `GH₵ ${numeric.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

const formatDateTime = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
};

export default function Transactions() {
  const api = useAuthorizedApi();
  const [searchQuery, setSearchQuery] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');

  const buildQueryParams = () => {
    const params = new URLSearchParams();
    if (searchQuery) params.set('search', searchQuery);
    if (typeFilter !== 'all') params.set('type', typeFilter.toLowerCase());
    if (statusFilter !== 'all') params.set('status', statusFilter.toLowerCase());
    return params.toString();
  };

  const { data, isLoading, isFetching, refetch } = useQuery<PaginatedResponse<AdminTransaction>>({
    queryKey: ['admin-transactions', searchQuery, typeFilter, statusFilter],
    queryFn: () => api(`/api/admin/transactions/?${buildQueryParams()}`),
    keepPreviousData: true,
  });

  const transactions = data?.results ?? [];

  return (
    <div className="space-y-6">
      <Card className="shadow-custom-md">
        <CardHeader>
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <CardTitle>Transaction History</CardTitle>
              <CardDescription>Monitor platform cashflow and review transaction statuses</CardDescription>
            </div>
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" onClick={() => refetch()} disabled={isFetching}>
                <RefreshCcw className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
                Refresh
              </Button>
              <Button variant="ghost">
                <Download className="mr-2 h-4 w-4" /> Export CSV
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Search by member or reference"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All types</SelectItem>
                <SelectItem value="deposit">Deposit</SelectItem>
                <SelectItem value="withdrawal">Withdrawal</SelectItem>
                <SelectItem value="contribution">Contribution</SelectItem>
                <SelectItem value="payout">Payout</SelectItem>
                <SelectItem value="savings">Savings</SelectItem>
              </SelectContent>
            </Select>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="success">Success</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="failed">Failed</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="rounded-lg border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Date &amp; Time</TableHead>
                  <TableHead>Member</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Reference</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={6}>
                      <Skeleton className="h-12 w-full" />
                    </TableCell>
                  </TableRow>
                ) : transactions.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center text-sm text-muted-foreground">
                      No transactions match your filters.
                    </TableCell>
                  </TableRow>
                ) : (
                  transactions.map((transaction) => {
                    const isDebit = ['withdrawal', 'savings'].includes(transaction.transaction_type);
                    const statusLabel = transaction.status
                      ? transaction.status.charAt(0).toUpperCase() + transaction.status.slice(1)
                      : transaction.status;
                    return (
                      <TableRow key={transaction.id}>
                        <TableCell className="text-sm text-muted-foreground">
                          {formatDateTime(transaction.occurred_at)}
                        </TableCell>
                        <TableCell className="font-medium text-foreground">{transaction.user_name}</TableCell>
                        <TableCell className="capitalize text-sm text-muted-foreground">{transaction.transaction_type}</TableCell>
                        <TableCell className={`font-semibold ${isDebit ? 'text-destructive' : 'text-success'}`}>
                          {isDebit ? '-' : '+'}
                          {formatCurrency(transaction.amount)}
                        </TableCell>
                        <TableCell>
                          <StatusBadge status={statusLabel} />
                        </TableCell>
                        <TableCell className="font-mono text-xs text-muted-foreground">
                          {transaction.reference || '—'}
                        </TableCell>
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
          <div className="flex items-center justify-between text-xs text-muted-foreground">
            <span>Total results: {data?.count ?? 0}</span>
            <span>Showing {transactions.length} transactions</span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

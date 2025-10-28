import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { RefreshCcw, Phone } from 'lucide-react';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Drawer,
  DrawerContent,
  DrawerDescription,
  DrawerFooter,
  DrawerHeader,
  DrawerTitle,
} from '@/components/ui/drawer';
import { ScrollArea } from '@/components/ui/scroll-area';
import { StatusBadge } from '@/components/ui/badge-variants';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';
import { useAuthorizedApi } from '@/lib/auth';
import type { AdminGroup, PaginatedResponse } from '@/lib/types';

const formatCurrency = (value: string | number) => {
  const numeric = typeof value === 'string' ? Number(value) : value;
  return `GH₵ ${numeric.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

const formatDate = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
};

export default function Groups() {
  const api = useAuthorizedApi();
  const [searchQuery, setSearchQuery] = useState('');
  const [visibility, setVisibility] = useState('all');
  const [selectedGroup, setSelectedGroup] = useState<AdminGroup | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const buildQueryParams = () => {
    const params = new URLSearchParams();
    if (searchQuery) params.set('search', searchQuery);
    if (visibility !== 'all') params.set('is_public', visibility === 'public' ? 'true' : 'false');
    return params.toString();
  };

  const { data, isLoading, isFetching, refetch } = useQuery<PaginatedResponse<AdminGroup>>({
    queryKey: ['admin-groups', searchQuery, visibility],
    queryFn: () => api(`/api/admin/groups/?${buildQueryParams()}`),
    keepPreviousData: true,
  });

  const groups = data?.results ?? [];

  const openGroup = (group: AdminGroup) => {
    setSelectedGroup(group);
    setDrawerOpen(true);
  };

  const closeDrawer = (open: boolean) => {
    setDrawerOpen(open);
    if (!open) {
      setSelectedGroup(null);
    }
  };

  return (
    <div className="space-y-6">
      <Card className="shadow-custom-md">
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <CardTitle>Susu Groups</CardTitle>
              <CardDescription>Monitor group performance, invites, and payout schedules</CardDescription>
            </div>
            <Button variant="outline" onClick={() => refetch()} disabled={isFetching}>
              <RefreshCcw className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
            <Input
              placeholder="Search by group name or owner"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            <Select value={visibility} onValueChange={setVisibility}>
              <SelectTrigger className="w-full lg:w-[200px]">
                <SelectValue placeholder="Visibility" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All groups</SelectItem>
                <SelectItem value="public">Public</SelectItem>
                <SelectItem value="private">Private</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div className="rounded-lg border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Owner</TableHead>
                  <TableHead>Members</TableHead>
                  <TableHead>Invites</TableHead>
                  <TableHead>Contribution</TableHead>
                  <TableHead>Next payout</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  <TableRow>
                    <TableCell colSpan={6}>
                      <Skeleton className="h-12 w-full" />
                    </TableCell>
                  </TableRow>
                ) : groups.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center text-sm text-muted-foreground">
                      No groups found.
                    </TableCell>
                  </TableRow>
                ) : (
                  groups.map((group) => (
                    <TableRow
                      key={group.id}
                      onClick={() => openGroup(group)}
                      className="cursor-pointer hover:bg-muted/30"
                    >
                      <TableCell>
                        <div className="flex flex-col">
                          <span className="font-semibold text-foreground">{group.name}</span>
                          <span className="text-xs text-muted-foreground">
                            {group.is_public ? 'Public circle' : 'Private circle'}
                          </span>
                        </div>
                      </TableCell>
                      <TableCell>{group.owner_name ?? '—'}</TableCell>
                      <TableCell>{group.member_count} / {group.target_member_count}</TableCell>
                      <TableCell>
                        <Badge variant="outline">{group.pending_invites} pending</Badge>
                      </TableCell>
                      <TableCell>{formatCurrency(group.contribution_amount)}</TableCell>
                      <TableCell>{formatDate(group.next_payout_date)}</TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <Drawer open={drawerOpen} onOpenChange={closeDrawer}>
        <DrawerContent className="sm:max-w-2xl">
          <DrawerHeader>
            <DrawerTitle>{selectedGroup?.name ?? 'Group details'}</DrawerTitle>
            <DrawerDescription>
              {selectedGroup ? `${selectedGroup.member_count} of ${selectedGroup.target_member_count} seats filled` : ''}
            </DrawerDescription>
          </DrawerHeader>
          {selectedGroup ? (
            <ScrollArea className="h-[70vh]">
              <div className="space-y-5 p-6 pr-8">
                <section className="space-y-3">
                  <h3 className="text-sm font-semibold text-muted-foreground">Overview</h3>
                  <div className="grid gap-3 sm:grid-cols-2">
                    <Card className="border border-border">
                      <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-semibold text-muted-foreground">Owner</CardTitle>
                      </CardHeader>
                      <CardContent>
                        <p className="text-base font-semibold text-foreground">
                          {selectedGroup.owner_name ?? 'Platform managed'}
                        </p>
                      </CardContent>
                    </Card>
                    <Card className="border border-border">
                      <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-semibold text-muted-foreground">Next payout</CardTitle>
                      </CardHeader>
                      <CardContent>
                        <p className="text-base font-semibold text-foreground">
                          {formatDate(selectedGroup.next_payout_date)}
                        </p>
                      </CardContent>
                    </Card>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Badge variant="secondary">{selectedGroup.is_public ? 'Public' : 'Private'}</Badge>
                    <Badge variant="outline">Cycle {selectedGroup.cycle_number} of {selectedGroup.total_cycles}</Badge>
                  </div>
                </section>

                <section className="space-y-3">
                  <h3 className="text-sm font-semibold text-muted-foreground">Contribution plan</h3>
                  <div className="rounded-lg border border-border p-4">
                    <p className="text-sm text-muted-foreground">Contribution amount</p>
                    <p className="text-lg font-semibold text-foreground">{formatCurrency(selectedGroup.contribution_amount)}</p>
                    {selectedGroup.frequency && (
                      <p className="text-sm text-muted-foreground">Frequency: {selectedGroup.frequency}</p>
                    )}
                  </div>
                </section>

                <section className="space-y-3">
                  <h3 className="text-sm font-semibold text-muted-foreground">Invites</h3>
                  {selectedGroup.invites.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No pending invites.</p>
                  ) : (
                    <div className="space-y-2">
                      {selectedGroup.invites.map((invite) => (
                        <div key={invite.id} className="rounded-lg border border-border p-4">
                          <div className="flex items-center justify-between text-sm">
                            <span className="font-semibold text-foreground">{invite.name}</span>
                            <StatusBadge status={invite.status.charAt(0).toUpperCase() + invite.status.slice(1)} />
                          </div>
                          <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
                            <Phone className="h-3 w-3" />
                            <span>{invite.phone_number}</span>
                          </div>
                          <p className="mt-2 text-xs text-muted-foreground">
                            Sent {formatDate(invite.sent_at)}
                          </p>
                        </div>
                      ))}
                    </div>
                  )}
                </section>
              </div>
            </ScrollArea>
          ) : (
            <div className="p-6 text-sm text-muted-foreground">Select a group to view details.</div>
          )}
          <DrawerFooter className="flex justify-end">
            <Button variant="outline" onClick={() => closeDrawer(false)}>
              Close
            </Button>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>
    </div>
  );
}

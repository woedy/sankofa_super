import { useState } from 'react';
import { Search, Eye, UserX, CheckCircle } from 'lucide-react';
import { mockUsers } from '@/lib/mockData';
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
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';

export default function Users() {
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');

  const filteredUsers = mockUsers.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === 'All' || user.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="space-y-6">
      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>User Management</CardTitle>
          <CardDescription>Manage platform users, verify KYC, and monitor activity</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Search by name or email..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
            <Tabs value={statusFilter} onValueChange={setStatusFilter}>
              <TabsList>
                <TabsTrigger value="All">All</TabsTrigger>
                <TabsTrigger value="Active">Active</TabsTrigger>
                <TabsTrigger value="Suspended">Suspended</TabsTrigger>
                <TabsTrigger value="Inactive">Inactive</TabsTrigger>
              </TabsList>
            </Tabs>
          </div>

          <div className="rounded-lg border border-border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Contact</TableHead>
                  <TableHead>KYC Status</TableHead>
                  <TableHead>Wallet Balance</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredUsers.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary font-semibold">
                          {user.avatar}
                        </div>
                        <div>
                          <p className="font-medium">{user.name}</p>
                          <p className="text-sm text-muted-foreground">{user.email}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="text-sm">{user.phone}</TableCell>
                    <TableCell>
                      <StatusBadge status={user.kycStatus} />
                    </TableCell>
                    <TableCell className="font-medium">GH₵ {user.walletBalance.toFixed(2)}</TableCell>
                    <TableCell>
                      <StatusBadge status={user.status} />
                    </TableCell>
                    <TableCell className="text-right">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <Eye className="h-4 w-4 mr-1" />
                            View
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-2xl">
                          <DialogHeader>
                            <DialogTitle>User Profile</DialogTitle>
                            <DialogDescription>Detailed information for {user.name}</DialogDescription>
                          </DialogHeader>
                          <div className="space-y-4">
                            <div className="grid grid-cols-2 gap-4">
                              <div>
                                <p className="text-sm font-medium text-muted-foreground">Full Name</p>
                                <p className="text-base font-medium">{user.name}</p>
                              </div>
                              <div>
                                <p className="text-sm font-medium text-muted-foreground">Email</p>
                                <p className="text-base font-medium">{user.email}</p>
                              </div>
                              <div>
                                <p className="text-sm font-medium text-muted-foreground">Phone</p>
                                <p className="text-base font-medium">{user.phone}</p>
                              </div>
                              <div>
                                <p className="text-sm font-medium text-muted-foreground">Joined Date</p>
                                <p className="text-base font-medium">{user.joinedDate}</p>
                              </div>
                              <div>
                                <p className="text-sm font-medium text-muted-foreground">KYC Status</p>
                                <StatusBadge status={user.kycStatus} />
                              </div>
                              <div>
                                <p className="text-sm font-medium text-muted-foreground">Account Status</p>
                                <StatusBadge status={user.status} />
                              </div>
                              <div>
                                <p className="text-sm font-medium text-muted-foreground">Wallet Balance</p>
                                <p className="text-lg font-bold text-primary">GH₵ {user.walletBalance.toFixed(2)}</p>
                              </div>
                            </div>
                            <div className="flex gap-2 pt-4 border-t border-border">
                              {user.kycStatus === 'Pending' && (
                                <Button variant="default" size="sm">
                                  <CheckCircle className="h-4 w-4 mr-1" />
                                  Approve KYC
                                </Button>
                              )}
                              {user.status === 'Active' && (
                                <Button variant="destructive" size="sm">
                                  <UserX className="h-4 w-4 mr-1" />
                                  Suspend User
                                </Button>
                              )}
                            </div>
                          </div>
                        </DialogContent>
                      </Dialog>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

import { Users, Calendar, DollarSign, TrendingUp } from 'lucide-react';
import { mockSusuGroups } from '@/lib/mockData';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge-variants';
import { Progress } from '@/components/ui/progress';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';

export default function Groups() {
  return (
    <div className="space-y-6">
      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Susu Groups Management</CardTitle>
          <CardDescription>Monitor and manage all susu savings groups</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {mockSusuGroups.map((group) => (
              <Dialog key={group.id}>
                <DialogTrigger asChild>
                  <Card className="cursor-pointer shadow-custom-sm hover:shadow-custom-md transition-smooth border-2 hover:border-primary/20">
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <CardTitle className="text-lg">{group.name}</CardTitle>
                        <StatusBadge status={group.status} />
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="grid grid-cols-2 gap-4">
                        <div className="flex items-center gap-2">
                          <Users className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Members</p>
                            <p className="text-sm font-semibold">{group.members}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <DollarSign className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Contribution</p>
                            <p className="text-sm font-semibold">GH₵ {group.contributionAmount}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Frequency</p>
                            <p className="text-sm font-semibold">{group.frequency}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <TrendingUp className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Pooled</p>
                            <p className="text-sm font-semibold">GH₵ {group.totalPooled}</p>
                          </div>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <div className="flex justify-between text-xs">
                          <span className="text-muted-foreground">Cycle Progress</span>
                          <span className="font-medium">{group.cycleProgress}%</span>
                        </div>
                        <Progress value={group.cycleProgress} className="h-2" />
                      </div>
                      <div className="pt-2 border-t border-border">
                        <p className="text-xs text-muted-foreground">Next Payout</p>
                        <p className="text-sm font-medium">{group.nextPayoutDate}</p>
                      </div>
                    </CardContent>
                  </Card>
                </DialogTrigger>

                <DialogContent className="max-w-3xl">
                  <DialogHeader>
                    <DialogTitle>{group.name}</DialogTitle>
                    <DialogDescription>Detailed group information and member list</DialogDescription>
                  </DialogHeader>
                  <div className="space-y-6">
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div className="rounded-lg bg-muted p-4">
                        <p className="text-sm text-muted-foreground">Members</p>
                        <p className="text-2xl font-bold">{group.members}</p>
                      </div>
                      <div className="rounded-lg bg-muted p-4">
                        <p className="text-sm text-muted-foreground">Contribution</p>
                        <p className="text-2xl font-bold">GH₵ {group.contributionAmount}</p>
                      </div>
                      <div className="rounded-lg bg-muted p-4">
                        <p className="text-sm text-muted-foreground">Frequency</p>
                        <p className="text-2xl font-bold">{group.frequency}</p>
                      </div>
                      <div className="rounded-lg bg-muted p-4">
                        <p className="text-sm text-muted-foreground">Total Pooled</p>
                        <p className="text-2xl font-bold text-success">GH₵ {group.totalPooled}</p>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <div className="flex justify-between">
                        <span className="text-sm font-medium">Cycle Progress</span>
                        <span className="text-sm font-semibold">{group.cycleProgress}%</span>
                      </div>
                      <Progress value={group.cycleProgress} className="h-3" />
                      <p className="text-sm text-muted-foreground">Next payout: {group.nextPayoutDate}</p>
                    </div>

                    {group.membersList.length > 0 && (
                      <div className="space-y-3">
                        <h3 className="font-semibold">Member Rotation Status</h3>
                        <div className="space-y-2">
                          {group.membersList.map((member, index) => (
                            <div key={index} className="flex items-center justify-between rounded-lg border border-border p-3">
                              <div className="flex items-center gap-3">
                                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary/10 text-primary font-semibold text-sm">
                                  {member.name.split(' ').map(n => n[0]).join('')}
                                </div>
                                <div>
                                  <p className="font-medium">{member.name}</p>
                                  <p className="text-sm text-muted-foreground">Payout Amount: GH₵ {member.amount}</p>
                                </div>
                              </div>
                              <StatusBadge status={member.currentRotation} />
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    <div className="flex gap-2 pt-4 border-t border-border">
                      <Button variant="default">View Transactions</Button>
                      <Button variant="outline">Export Report</Button>
                    </div>
                  </div>
                </DialogContent>
              </Dialog>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

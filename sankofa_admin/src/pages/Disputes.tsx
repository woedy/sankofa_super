import { mockDisputes } from '@/lib/mockData';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge-variants';
import { Button } from '@/components/ui/button';
import { MessageSquare, Calendar, User, Users } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';

export default function Disputes() {
  return (
    <div className="space-y-6">
      <Card className="shadow-custom-md">
        <CardHeader>
          <CardTitle>Dispute Management</CardTitle>
          <CardDescription>Review and resolve user disputes and complaints</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {mockDisputes.map((dispute) => (
              <Card key={dispute.id} className="shadow-custom-sm border-2 hover:border-primary/20 transition-smooth">
                <CardContent className="p-6">
                  <div className="flex items-start justify-between">
                    <div className="space-y-3 flex-1">
                      <div className="flex items-start gap-4">
                        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10">
                          <MessageSquare className="h-6 w-6 text-destructive" />
                        </div>
                        <div className="flex-1 space-y-2">
                          <div className="flex items-start justify-between">
                            <h3 className="text-lg font-semibold text-foreground">{dispute.title}</h3>
                            <StatusBadge status={dispute.status} />
                          </div>
                          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-sm">
                            <div className="flex items-center gap-2 text-muted-foreground">
                              <User className="h-4 w-4" />
                              <span>{dispute.user}</span>
                            </div>
                            <div className="flex items-center gap-2 text-muted-foreground">
                              <Users className="h-4 w-4" />
                              <span>{dispute.group}</span>
                            </div>
                            <div className="flex items-center gap-2 text-muted-foreground">
                              <Calendar className="h-4 w-4" />
                              <span>{dispute.date}</span>
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-medium text-muted-foreground">Priority:</span>
                            <span className={`inline-flex items-center rounded-full px-2 py-1 text-xs font-medium ${
                              dispute.priority === 'High' ? 'bg-destructive/10 text-destructive' :
                              dispute.priority === 'Medium' ? 'bg-warning/10 text-warning' :
                              'bg-muted text-muted-foreground'
                            }`}>
                              {dispute.priority}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div className="mt-4 flex gap-2">
                    <Dialog>
                      <DialogTrigger asChild>
                        <Button variant="default" size="sm">
                          <MessageSquare className="h-4 w-4 mr-2" />
                          View Details
                        </Button>
                      </DialogTrigger>
                      <DialogContent className="max-w-2xl">
                        <DialogHeader>
                          <DialogTitle>{dispute.title}</DialogTitle>
                          <DialogDescription>Dispute case details and resolution</DialogDescription>
                        </DialogHeader>
                        <div className="space-y-6">
                          <div className="grid grid-cols-2 gap-4">
                            <div>
                              <p className="text-sm font-medium text-muted-foreground">User</p>
                              <p className="text-base font-medium">{dispute.user}</p>
                            </div>
                            <div>
                              <p className="text-sm font-medium text-muted-foreground">Group</p>
                              <p className="text-base font-medium">{dispute.group}</p>
                            </div>
                            <div>
                              <p className="text-sm font-medium text-muted-foreground">Date Filed</p>
                              <p className="text-base font-medium">{dispute.date}</p>
                            </div>
                            <div>
                              <p className="text-sm font-medium text-muted-foreground">Status</p>
                              <StatusBadge status={dispute.status} />
                            </div>
                          </div>

                          <div className="space-y-3 rounded-lg border border-border p-4">
                            <h4 className="font-semibold">Dispute Description</h4>
                            <p className="text-sm text-muted-foreground">
                              The user has reported an issue regarding their recent contribution payment. 
                              They claim the payment was deducted from their account but not reflected in 
                              the group's total contribution amount. Investigation is required to verify 
                              the transaction and resolve the discrepancy.
                            </p>
                          </div>

                          <div className="space-y-3">
                            <Label htmlFor="resolution">Resolution Notes</Label>
                            <Textarea 
                              id="resolution" 
                              placeholder="Enter resolution notes or action taken..." 
                              className="min-h-[120px]"
                            />
                          </div>

                          <div className="flex gap-2 pt-4 border-t border-border">
                            <Button variant="default">Mark as Resolved</Button>
                            <Button variant="outline">Request More Info</Button>
                            <Button variant="destructive">Escalate</Button>
                          </div>
                        </div>
                      </DialogContent>
                    </Dialog>
                    {dispute.status === 'Open' && (
                      <Button variant="outline" size="sm">Assign to Me</Button>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

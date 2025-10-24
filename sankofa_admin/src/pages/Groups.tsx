import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  Users,
  Calendar,
  DollarSign,
  TrendingUp,
  AlertTriangle,
  Clock,
  Send,
  Filter,
  RefreshCw,
  BarChart3,
} from 'lucide-react';

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
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';

const currencyFormatter = new Intl.NumberFormat('en-GH', {
  style: 'currency',
  currency: 'GHS',
  minimumFractionDigits: 2,
});

type Group = (typeof mockSusuGroups)[number];

type InviteHealthKey = 'healthy' | 'watch' | 'risk';

type ActionMode = 'reschedule' | 'reminder' | 'adjust' | null;

const stageTone: Record<string, string> = {
  Onboarding: 'bg-primary/10 text-primary border-primary/20',
  Contributions: 'bg-success/10 text-success border-success/20',
  Payout: 'bg-warning/10 text-warning border-warning/20',
  Completed: 'bg-muted text-muted-foreground border-border',
};

const inviteHealthLabels: Record<InviteHealthKey, { label: string; description: string }> = {
  healthy: { label: 'Healthy', description: '≥85% of invited members have joined' },
  watch: { label: 'Monitor', description: '60-84% completion—watch momentum' },
  risk: { label: 'At Risk', description: '<60% completion—needs action' },
};

const defaultActionValues = {
  rescheduleDate: '',
  rescheduleReason: 'float',
  reminderAudience: 'pending',
  reminderMessage: 'Friendly reminder to wrap up your KYC so you can join the next cycle.',
  newContribution: '',
};

const allowedVisibility = ['all', 'private', 'public'] as const;
const allowedStages = ['all', 'Onboarding', 'Contributions', 'Payout', 'Completed'] as const;
const allowedInviteFilters = ['all', 'healthy', 'watch', 'risk'] as const;

type VisibilityFilter = (typeof allowedVisibility)[number];
type StageFilter = (typeof allowedStages)[number];
type InviteFilter = (typeof allowedInviteFilters)[number];

const cloneGroup = (group: Group): Group => ({
  ...group,
  membersList: group.membersList.map((member) => ({ ...member })),
  invites: group.invites.map((invite) => ({ ...invite })),
  payoutTimeline: group.payoutTimeline.map((entry) => ({ ...entry })),
  outstandingReminders: group.outstandingReminders.map((reminder) => ({ ...reminder })),
});

const formatDate = (value: string) => {
  const normalized = value.includes('T') || value.includes(' ') ? value.replace(' ', 'T') : `${value}T00:00:00`;
  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};

const formatDateTime = (value: string | undefined) => {
  if (!value) {
    return '—';
  }
  const normalized = value.includes('T') || value.includes(' ') ? value.replace(' ', 'T') : `${value}T00:00:00`;
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

const toInputDate = (value: string) => {
  const parsed = new Date(value.includes('T') ? value : `${value}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) {
    return '';
  }
  const year = parsed.getFullYear();
  const month = `${parsed.getMonth() + 1}`.padStart(2, '0');
  const day = `${parsed.getDate()}`.padStart(2, '0');
  return `${year}-${month}-${day}`;
};

const daysUntil = (value: string) => {
  const parsed = new Date(value.includes('T') ? value : `${value}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) {
    return Infinity;
  }
  const now = new Date();
  const diff = parsed.getTime() - now.getTime();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
};

const getInviteHealth = (completion: number): InviteHealthKey => {
  if (completion >= 85) {
    return 'healthy';
  }
  if (completion >= 60) {
    return 'watch';
  }
  return 'risk';
};

const addScheduleEntry = (group: Group, scheduledAt: string) => {
  const label = group.nextPayout?.window ? `${group.nextPayout.window} (rescheduled)` : 'Rescheduled payout';
  return [
    {
      label,
      member: group.nextPayout?.member ?? 'Member payout',
      scheduledAt,
      status: 'Scheduled',
    },
    ...group.payoutTimeline,
  ];
};

const parseNumber = (value: string) => {
  const parsed = Number.parseFloat(value);
  return Number.isFinite(parsed) ? parsed : NaN;
};

export default function Groups() {
  const { toast } = useToast();
  const [searchParams, setSearchParams] = useSearchParams();

  const initialVisibility = (() => {
    const value = searchParams.get('visibility');
    return allowedVisibility.includes((value ?? 'all') as VisibilityFilter) ? (value as VisibilityFilter) : 'all';
  })();

  const initialStage = (() => {
    const value = searchParams.get('stage');
    return allowedStages.includes((value ?? 'all') as StageFilter) ? (value as StageFilter) : 'all';
  })();

  const initialInvite = (() => {
    const value = searchParams.get('invite');
    return allowedInviteFilters.includes((value ?? 'all') as InviteFilter) ? (value as InviteFilter) : 'all';
  })();

  const [visibilityFilter, setVisibilityFilter] = useState<VisibilityFilter>(initialVisibility);
  const [stageFilter, setStageFilter] = useState<StageFilter>(initialStage);
  const [inviteFilter, setInviteFilter] = useState<InviteFilter>(initialInvite);
  const [groups, setGroups] = useState(() => mockSusuGroups.map((group) => cloneGroup(group)));
  const [openGroupId, setOpenGroupId] = useState<string | null>(null);
  const [actionMode, setActionMode] = useState<ActionMode>(null);
  const [actionValues, setActionValues] = useState({ ...defaultActionValues });

  useEffect(() => {
    const params = new URLSearchParams();
    params.set('visibility', visibilityFilter);
    params.set('stage', stageFilter);
    params.set('invite', inviteFilter);
    setSearchParams(params, { replace: true });
  }, [visibilityFilter, stageFilter, inviteFilter, setSearchParams]);

  useEffect(() => {
    setActionMode(null);
    setActionValues({ ...defaultActionValues });
  }, [openGroupId]);

  const filteredGroups = useMemo(() => {
    return groups.filter((group) => {
      if (visibilityFilter !== 'all' && group.visibility.toLowerCase() !== visibilityFilter) {
        return false;
      }
      if (stageFilter !== 'all' && group.cycleStage !== stageFilter) {
        return false;
      }
      if (inviteFilter !== 'all' && getInviteHealth(group.inviteCompletion) !== inviteFilter) {
        return false;
      }
      return true;
    });
  }, [groups, visibilityFilter, stageFilter, inviteFilter]);

  const summary = useMemo(() => {
    const total = filteredGroups.length;
    const atRisk = filteredGroups.filter((group) => getInviteHealth(group.inviteCompletion) === 'risk').length;
    const payoutsSoon = filteredGroups.filter((group) => daysUntil(group.nextPayoutDate) <= 7).length;
    const reminders = filteredGroups.reduce((acc, group) => acc + group.remindersDue, 0);
    const averageInviteCompletion =
      total > 0
        ? Math.round(filteredGroups.reduce((acc, group) => acc + group.inviteCompletion, 0) / total)
        : mockSusuGroups.reduce((acc, group) => acc + group.inviteCompletion, 0) / mockSusuGroups.length;

    return { total, atRisk, payoutsSoon, reminders, averageInviteCompletion };
  }, [filteredGroups]);

  const handleReschedule = (groupId: string) => {
    if (!actionValues.rescheduleDate) {
      toast({
        title: 'Select a new payout date',
        description: 'Choose a future date before rescheduling the payout.',
        variant: 'destructive',
      });
      return;
    }

    setGroups((previous) =>
      previous.map((group) => {
        if (group.id !== groupId) {
          return group;
        }

        const updatedTimeline = addScheduleEntry(group, actionValues.rescheduleDate);

        return {
          ...group,
          nextPayoutDate: actionValues.rescheduleDate,
          nextPayout: group.nextPayout
            ? { ...group.nextPayout, scheduledAt: actionValues.rescheduleDate }
            : undefined,
          payoutTimeline: updatedTimeline,
        };
      }),
    );

    toast({
      title: 'Payout rescheduled',
      description: `Next payout moved to ${formatDate(actionValues.rescheduleDate)} for compliance reason (${actionValues.rescheduleReason}).`,
    });

    setActionMode(null);
    setActionValues((values) => ({ ...values, rescheduleDate: '', rescheduleReason: 'float' }));
  };

  const handleReminder = (groupId: string) => {
    setGroups((previous) =>
      previous.map((group) => {
        if (group.id !== groupId) {
          return group;
        }

        const audience = actionValues.reminderAudience;
        const now = new Date().toISOString();
        const updatedInvites = group.invites.map((invite) => {
          if (audience === 'pending' && invite.status !== 'Pending') {
            return invite;
          }
          if (audience === 'accepted' && invite.status !== 'Accepted') {
            return invite;
          }
          return {
            ...invite,
            lastRemindedAt: now,
          };
        });

        const remindersDue = Math.max(0, group.remindersDue - 1);

        return {
          ...group,
          remindersDue,
          remindersSent: group.remindersSent + 1,
          lastReminderAt: now,
          invites: updatedInvites,
        };
      }),
    );

    toast({
      title: 'Reminder queued',
      description: `Reminder sent to ${actionValues.reminderAudience === 'pending' ? 'pending' : 'accepted'} invitees.`,
    });

    setActionMode(null);
    setActionValues((values) => ({ ...values, reminderAudience: 'pending' }));
  };

  const handleContribution = (groupId: string) => {
    const parsedAmount = parseNumber(actionValues.newContribution);
    if (Number.isNaN(parsedAmount) || parsedAmount <= 0) {
      toast({
        title: 'Enter a valid amount',
        description: 'Contribution amount must be greater than zero.',
        variant: 'destructive',
      });
      return;
    }

    setGroups((previous) =>
      previous.map((group) => {
        if (group.id !== groupId) {
          return group;
        }

        const contributionAmount = Math.round(parsedAmount * 100) / 100;
        const recalculatedTotal = Math.round(group.members * contributionAmount * (group.cycleProgress / 100) * 100) / 100;

        return {
          ...group,
          contributionAmount,
          totalPooled: Number.isFinite(recalculatedTotal) ? recalculatedTotal : group.totalPooled,
        };
      }),
    );

    toast({
      title: 'Contribution updated',
      description: `Members will contribute ${currencyFormatter.format(parsedAmount)} each period going forward.`,
    });

    setActionMode(null);
    setActionValues((values) => ({ ...values, newContribution: '' }));
  };

  return (
    <div className="space-y-6">
      <div className="grid gap-4 lg:grid-cols-4">
        <Card className="shadow-custom-md">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
              <Users className="h-4 w-4" /> Active cohorts
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">{summary.total}</p>
            <p className="text-xs text-muted-foreground">Filtered by visibility, cycle stage, and invite health</p>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
              <AlertTriangle className="h-4 w-4 text-warning" /> Invites at risk
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">{summary.atRisk}</p>
            <p className="text-xs text-muted-foreground">Require intervention to unblock onboarding</p>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
              <Clock className="h-4 w-4" /> Payouts in 7 days
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">{summary.payoutsSoon}</p>
            <p className="text-xs text-muted-foreground">Ensure float, approvals, and communication are ready</p>
          </CardContent>
        </Card>
        <Card className="shadow-custom-md">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
              <Send className="h-4 w-4" /> Outstanding reminders
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">{summary.reminders}</p>
            <p className="text-xs text-muted-foreground">Average invite completion {Math.round(summary.averageInviteCompletion)}%</p>
          </CardContent>
        </Card>
      </div>

      <Card className="shadow-custom-md">
        <CardHeader className="pb-4">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <CardTitle>Susu Groups Lifecycle</CardTitle>
              <CardDescription>Track invite health, cycles, and payouts across the platform</CardDescription>
            </div>
            <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
              <Filter className="h-4 w-4" /> Filters persist in the URL so you can copy your current view.
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <Tabs value={visibilityFilter} onValueChange={(value) => setVisibilityFilter(value as VisibilityFilter)}>
              <TabsList className="grid w-full grid-cols-3 lg:w-auto">
                <TabsTrigger value="all">All visibility</TabsTrigger>
                <TabsTrigger value="private">Private cohorts</TabsTrigger>
                <TabsTrigger value="public">Public cohorts</TabsTrigger>
              </TabsList>
            </Tabs>
            <div className="flex flex-col gap-4 md:flex-row md:items-center">
              <Select value={stageFilter} onValueChange={(value) => setStageFilter(value as StageFilter)}>
                <SelectTrigger className="w-full md:w-48">
                  <SelectValue placeholder="Cycle stage" />
                </SelectTrigger>
                <SelectContent>
                  {allowedStages.map((option) => (
                    <SelectItem key={option} value={option}>
                      {option === 'all' ? 'All cycle stages' : option}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Select value={inviteFilter} onValueChange={(value) => setInviteFilter(value as InviteFilter)}>
                <SelectTrigger className="w-full md:w-48">
                  <SelectValue placeholder="Invite health" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All invite states</SelectItem>
                  {(['healthy', 'watch', 'risk'] as InviteHealthKey[]).map((key) => (
                    <SelectItem key={key} value={key}>
                      {inviteHealthLabels[key].label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
            {filteredGroups.map((group) => (
              <Dialog key={group.id} open={openGroupId === group.id} onOpenChange={(open) => setOpenGroupId(open ? group.id : null)}>
                <Button
                  variant="ghost"
                  className="h-auto w-full justify-start rounded-xl border-2 border-transparent p-0 text-left"
                  onClick={() => setOpenGroupId(group.id)}
                  type="button"
                >
                  <Card className="w-full cursor-pointer transition-smooth hover:border-primary/40 hover:shadow-custom-md">
                    <CardHeader className="space-y-4 pb-4">
                      <div className="flex flex-wrap items-start justify-between gap-2">
                        <CardTitle className="text-lg font-semibold">{group.name}</CardTitle>
                        <div className="flex flex-wrap items-center gap-2">
                          <StatusBadge status={group.status} />
                          <Badge variant="outline" className={stageTone[group.cycleStage] ?? 'bg-muted text-muted-foreground border-border'}>
                            {group.cycleStage}
                          </Badge>
                        </div>
                      </div>
                      <div className="grid gap-4 sm:grid-cols-2">
                        <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                          <Users className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Members</p>
                            <p className="text-sm font-semibold">{group.members}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                          <DollarSign className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Contribution</p>
                            <p className="text-sm font-semibold">
                              {currencyFormatter.format(group.contributionAmount)}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Frequency</p>
                            <p className="text-sm font-semibold">{group.frequency}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                          <TrendingUp className="h-4 w-4 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Total pooled</p>
                            <p className="text-sm font-semibold">
                              {currencyFormatter.format(group.totalPooled)}
                            </p>
                          </div>
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div className="space-y-2">
                        <div className="flex items-center justify-between text-xs font-medium">
                          <span>Cycle progress</span>
                          <span>{group.cycleProgress}%</span>
                        </div>
                        <Progress value={group.cycleProgress} className="h-2" />
                      </div>
                      <div className="space-y-2">
                        <div className="flex items-center justify-between text-xs font-medium">
                          <span>Invite completion</span>
                          <span>{group.inviteCompletion}%</span>
                        </div>
                        <Progress value={group.inviteCompletion} className="h-2" />
                        <p className="text-xs text-muted-foreground">
                          {group.inviteStats.accepted} joined • {group.inviteStats.pending} pending • {group.inviteStats.declined} declined
                        </p>
                      </div>
                      <div className="rounded-lg border border-dashed border-primary/40 bg-primary/5 p-4 text-sm">
                        <p className="font-medium text-primary">Upcoming payout</p>
                        <p className="text-muted-foreground">{group.nextPayout?.member ?? '—'} • {formatDate(group.nextPayoutDate)}</p>
                      </div>
                    </CardContent>
                  </Card>
                </Button>

                <DialogContent className="max-w-5xl">
                  <DialogHeader>
                    <DialogTitle className="text-2xl font-semibold">{group.name}</DialogTitle>
                    <DialogDescription>
                      Manage cycle health, invites, and payouts without leaving the console.
                    </DialogDescription>
                  </DialogHeader>
                  <ScrollArea className="mt-4 max-h-[70vh] pr-2">
                    <div className="space-y-6 pb-4">
                      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                        <Card className="shadow-none border">
                          <CardHeader className="pb-2">
                            <CardTitle className="flex items-center gap-2 text-xs font-semibold text-muted-foreground">
                              <Users className="h-4 w-4" /> Active members
                            </CardTitle>
                          </CardHeader>
                          <CardContent>
                            <p className="text-lg font-semibold">{group.members}</p>
                            <p className="text-xs text-muted-foreground">{group.visibility === 'Public' ? 'Public cohort' : 'Private cohort'}</p>
                          </CardContent>
                        </Card>
                        <Card className="shadow-none border">
                          <CardHeader className="pb-2">
                            <CardTitle className="flex items-center gap-2 text-xs font-semibold text-muted-foreground">
                              <BarChart3 className="h-4 w-4" /> Invite health
                            </CardTitle>
                          </CardHeader>
                          <CardContent>
                            <p className="text-lg font-semibold">{group.inviteCompletion}%</p>
                            <p className="text-xs text-muted-foreground">{inviteHealthLabels[getInviteHealth(group.inviteCompletion)].description}</p>
                          </CardContent>
                        </Card>
                        <Card className="shadow-none border">
                          <CardHeader className="pb-2">
                            <CardTitle className="flex items-center gap-2 text-xs font-semibold text-muted-foreground">
                              <Clock className="h-4 w-4" /> Next payout
                            </CardTitle>
                          </CardHeader>
                          <CardContent>
                            <p className="text-lg font-semibold">{group.nextPayout?.member ?? 'TBD'}</p>
                            <p className="text-xs text-muted-foreground">{formatDate(group.nextPayoutDate)}</p>
                          </CardContent>
                        </Card>
                        <Card className="shadow-none border">
                          <CardHeader className="pb-2">
                            <CardTitle className="flex items-center gap-2 text-xs font-semibold text-muted-foreground">
                              <Send className="h-4 w-4" /> Reminders queue
                            </CardTitle>
                          </CardHeader>
                          <CardContent>
                            <p className="text-lg font-semibold">{group.remindersDue}</p>
                            <p className="text-xs text-muted-foreground">Last reminder {formatDateTime(group.lastReminderAt)}</p>
                          </CardContent>
                        </Card>
                      </div>

                      {group.riskFlags.length > 0 && (
                        <div className="flex flex-wrap gap-2">
                          {group.riskFlags.map((flag) => (
                            <Badge key={flag} variant="outline" className="border-warning/40 bg-warning/10 text-warning">
                              {flag}
                            </Badge>
                          ))}
                        </div>
                      )}

                      <Card className="shadow-none border">
                        <CardHeader>
                          <CardTitle className="text-base">Contribution cadence</CardTitle>
                          <CardDescription>Understand how funds move through this cycle.</CardDescription>
                        </CardHeader>
                        <CardContent className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                          <div className="rounded-lg bg-muted p-4 text-sm">
                            <p className="text-muted-foreground">Contribution amount</p>
                            <p className="text-lg font-semibold">{currencyFormatter.format(group.contributionAmount)}</p>
                          </div>
                          <div className="rounded-lg bg-muted p-4 text-sm">
                            <p className="text-muted-foreground">Cycle frequency</p>
                            <p className="text-lg font-semibold">{group.frequency}</p>
                          </div>
                          <div className="rounded-lg bg-muted p-4 text-sm">
                            <p className="text-muted-foreground">Contribution window</p>
                            <p className="text-lg font-semibold">{group.contributionWindow}</p>
                          </div>
                          <div className="rounded-lg bg-muted p-4 text-sm">
                            <p className="text-muted-foreground">Total pooled this stage</p>
                            <p className="text-lg font-semibold">{currencyFormatter.format(group.totalPooled)}</p>
                          </div>
                        </CardContent>
                      </Card>

                      <div className="grid gap-6 lg:grid-cols-2">
                        <Card className="shadow-none border">
                          <CardHeader>
                            <CardTitle className="text-base">Member rotation status</CardTitle>
                            <CardDescription>Roster across payout order and contribution performance.</CardDescription>
                          </CardHeader>
                          <CardContent className="space-y-3">
                            {group.membersList.map((member) => (
                              <div key={`${group.id}-${member.name}`} className="rounded-lg border border-border p-3">
                                <div className="flex flex-wrap items-center justify-between gap-3">
                                  <div>
                                    <p className="font-medium">{member.name}</p>
                                    <p className="text-xs text-muted-foreground">{member.role}</p>
                                  </div>
                                  <Badge variant="outline" className="text-xs">
                                    {member.payoutPosition}
                                  </Badge>
                                </div>
                                <div className="mt-3 grid gap-2 text-xs text-muted-foreground sm:grid-cols-2">
                                  <p>Rotation: {member.currentRotation}</p>
                                  <p>Last contribution: {formatDate(member.lastContribution)}</p>
                                  <p>Amount: {currencyFormatter.format(member.amount)}</p>
                                  <p>Status: {member.status}</p>
                                </div>
                              </div>
                            ))}
                          </CardContent>
                        </Card>

                        <Card className="shadow-none border">
                          <CardHeader>
                            <CardTitle className="text-base">Payout timeline</CardTitle>
                            <CardDescription>Upcoming and historical payouts for the cohort.</CardDescription>
                          </CardHeader>
                          <CardContent className="space-y-3">
                            {group.payoutTimeline.map((entry, index) => (
                              <div key={`${group.id}-payout-${index}`} className="flex items-start justify-between rounded-lg border border-border p-3 text-sm">
                                <div>
                                  <p className="font-medium">{entry.label}</p>
                                  <p className="text-xs text-muted-foreground">{entry.member}</p>
                                </div>
                                <div className="text-right text-xs text-muted-foreground">
                                  <p>{formatDate(entry.scheduledAt)}</p>
                                  <p>{entry.status}</p>
                                </div>
                              </div>
                            ))}
                          </CardContent>
                        </Card>
                      </div>

                      <div className="grid gap-6 lg:grid-cols-2">
                        <Card className="shadow-none border">
                          <CardHeader>
                            <CardTitle className="text-base">Invite pipeline</CardTitle>
                            <CardDescription>Where prospects are in the onboarding funnel.</CardDescription>
                          </CardHeader>
                          <CardContent className="space-y-3">
                            {group.invites.map((invite, index) => (
                              <div key={`${group.id}-invite-${index}`} className="rounded-lg border border-border p-3 text-sm">
                                <div className="flex flex-wrap items-center justify-between gap-2">
                                  <div>
                                    <p className="font-medium">{invite.name}</p>
                                    <p className="text-xs text-muted-foreground">{invite.phone}</p>
                                  </div>
                                  <StatusBadge status={invite.status} />
                                </div>
                                <div className="mt-2 grid gap-2 text-xs text-muted-foreground sm:grid-cols-2">
                                  <p>KYC: {invite.kycCompleted ? 'Complete' : 'Pending'}</p>
                                  <p>Channel: {invite.channel}</p>
                                  <p>Invited: {formatDateTime(invite.sentAt)}</p>
                                  <p>Last reminded: {formatDateTime(invite.lastRemindedAt ?? invite.respondedAt ?? '—')}</p>
                                </div>
                              </div>
                            ))}
                          </CardContent>
                        </Card>
                        <Card className="shadow-none border">
                          <CardHeader>
                            <CardTitle className="text-base">Outstanding reminders</CardTitle>
                            <CardDescription>Coordinate follow-ups to keep the cycle healthy.</CardDescription>
                          </CardHeader>
                          <CardContent className="space-y-3">
                            {group.outstandingReminders.map((reminder, index) => (
                              <div key={`${group.id}-reminder-${index}`} className="rounded-lg border border-dashed border-primary/40 bg-primary/5 p-3 text-sm">
                                <p className="font-medium text-primary">{reminder.title}</p>
                                <p className="text-xs text-muted-foreground">Due {formatDate(reminder.dueAt)} • Owner: {reminder.owner}</p>
                              </div>
                            ))}
                          </CardContent>
                        </Card>
                      </div>

                      <Card className="shadow-none border">
                        <CardHeader>
                          <CardTitle className="text-base">Operations control centre</CardTitle>
                          <CardDescription>Trigger interventions with optimistic UI feedback.</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4">
                          <div className="flex flex-wrap gap-2">
                            <Button
                              variant={actionMode === 'reschedule' ? 'default' : 'outline'}
                              onClick={() => setActionMode(actionMode === 'reschedule' ? null : 'reschedule')}
                            >
                              <Calendar className="mr-2 h-4 w-4" /> Reschedule payout
                            </Button>
                            <Button
                              variant={actionMode === 'reminder' ? 'default' : 'outline'}
                              onClick={() => setActionMode(actionMode === 'reminder' ? null : 'reminder')}
                            >
                              <Send className="mr-2 h-4 w-4" /> Send reminder
                            </Button>
                            <Button
                              variant={actionMode === 'adjust' ? 'default' : 'outline'}
                              onClick={() => setActionMode(actionMode === 'adjust' ? null : 'adjust')}
                            >
                              <RefreshCw className="mr-2 h-4 w-4" /> Adjust contribution
                            </Button>
                          </div>

                          {actionMode === 'reschedule' && (
                            <form
                              className="space-y-4 rounded-lg border border-border p-4"
                              onSubmit={(event) => {
                                event.preventDefault();
                                handleReschedule(group.id);
                              }}
                            >
                              <div className="grid gap-4 md:grid-cols-2">
                                <div className="space-y-2">
                                  <label className="text-xs font-medium text-muted-foreground">New payout date</label>
                                  <Input
                                    type="date"
                                    value={toInputDate(actionValues.rescheduleDate) || ''}
                                    onChange={(event) =>
                                      setActionValues((values) => ({ ...values, rescheduleDate: event.target.value }))
                                    }
                                    min={toInputDate(new Date().toISOString())}
                                  />
                                </div>
                                <div className="space-y-2">
                                  <label className="text-xs font-medium text-muted-foreground">Reason</label>
                                  <Select
                                    value={actionValues.rescheduleReason}
                                    onValueChange={(value) =>
                                      setActionValues((values) => ({ ...values, rescheduleReason: value }))
                                    }
                                  >
                                    <SelectTrigger>
                                      <SelectValue placeholder="Select reason" />
                                    </SelectTrigger>
                                    <SelectContent>
                                      <SelectItem value="float">Float readiness</SelectItem>
                                      <SelectItem value="compliance">Compliance review</SelectItem>
                                      <SelectItem value="member-request">Member request</SelectItem>
                                    </SelectContent>
                                  </Select>
                                </div>
                              </div>
                              <Button type="submit" className="w-full md:w-auto">
                                Confirm reschedule
                              </Button>
                            </form>
                          )}

                          {actionMode === 'reminder' && (
                            <form
                              className="space-y-4 rounded-lg border border-border p-4"
                              onSubmit={(event) => {
                                event.preventDefault();
                                handleReminder(group.id);
                              }}
                            >
                              <div className="grid gap-4 md:grid-cols-2">
                                <div className="space-y-2">
                                  <label className="text-xs font-medium text-muted-foreground">Audience</label>
                                  <Select
                                    value={actionValues.reminderAudience}
                                    onValueChange={(value) =>
                                      setActionValues((values) => ({ ...values, reminderAudience: value }))
                                    }
                                  >
                                    <SelectTrigger>
                                      <SelectValue placeholder="Select audience" />
                                    </SelectTrigger>
                                    <SelectContent>
                                      <SelectItem value="pending">Pending invitees</SelectItem>
                                      <SelectItem value="accepted">Accepted invitees</SelectItem>
                                    </SelectContent>
                                  </Select>
                                </div>
                                <div className="space-y-2">
                                  <label className="text-xs font-medium text-muted-foreground">Last reminder</label>
                                  <Input disabled value={formatDateTime(group.lastReminderAt)} />
                                </div>
                              </div>
                              <div className="space-y-2">
                                <label className="text-xs font-medium text-muted-foreground">Message preview</label>
                                <Textarea
                                  value={actionValues.reminderMessage}
                                  onChange={(event) =>
                                    setActionValues((values) => ({ ...values, reminderMessage: event.target.value }))
                                  }
                                  rows={3}
                                />
                              </div>
                              <Button type="submit" className="w-full md:w-auto">
                                Queue reminder
                              </Button>
                            </form>
                          )}

                          {actionMode === 'adjust' && (
                            <form
                              className="space-y-4 rounded-lg border border-border p-4"
                              onSubmit={(event) => {
                                event.preventDefault();
                                handleContribution(group.id);
                              }}
                            >
                              <div className="grid gap-4 md:grid-cols-2">
                                <div className="space-y-2">
                                  <label className="text-xs font-medium text-muted-foreground">New contribution amount</label>
                                  <Input
                                    type="number"
                                    min="0"
                                    step="0.01"
                                    value={actionValues.newContribution}
                                    onChange={(event) =>
                                      setActionValues((values) => ({ ...values, newContribution: event.target.value }))
                                    }
                                  />
                                </div>
                                <div className="space-y-2">
                                  <label className="text-xs font-medium text-muted-foreground">Current amount</label>
                                  <Input disabled value={currencyFormatter.format(group.contributionAmount)} />
                                </div>
                              </div>
                              <Button type="submit" className="w-full md:w-auto">
                                Update contribution
                              </Button>
                            </form>
                          )}
                        </CardContent>
                      </Card>
                    </div>
                  </ScrollArea>
                </DialogContent>
              </Dialog>
            ))}
          </div>

          {filteredGroups.length === 0 && (
            <div className="rounded-lg border border-dashed border-border p-10 text-center">
              <p className="font-medium">No groups match your filters yet.</p>
              <p className="mt-2 text-sm text-muted-foreground">
                Adjust visibility, cycle stage, or invite health filters to discover additional cohorts.
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

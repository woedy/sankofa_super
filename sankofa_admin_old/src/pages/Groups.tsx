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
  CheckCircle2,
  Plus,
  ArrowLeft,
  ArrowRight,
  Check,
} from 'lucide-react';

import { mockSusuGroups, publicGroupJoinFlow } from '@/lib/mockData';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/badge-variants';
import { Progress } from '@/components/ui/progress';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
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

const createSteps = [
  {
    id: 0,
    title: 'Basics',
    description: 'Name, mission, and organizer details',
  },
  {
    id: 1,
    title: 'Contribution plan',
    description: 'Target members, contribution schedule, invite pipeline',
  },
  {
    id: 2,
    title: 'Review & publish',
    description: 'Confirm details before listing the group publicly',
  },
];

const initialCreateValues = {
  name: '',
  purpose: '',
  location: '',
  organizer: '',
  organizerPhone: '',
  memberTarget: '12',
  contributionAmount: '200',
  frequency: 'Weekly',
  collectionWindow: 'Saturdays 06:00-18:00 GMT',
  startDate: '',
  firstPayoutDate: '',
  prospectList: 'Akua Nyarko\nYaw Boateng\nEfua Adjei',
};

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
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [createStep, setCreateStep] = useState(0);
  const [createValues, setCreateValues] = useState({ ...initialCreateValues });

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

  const resetCreateWizard = () => {
    setCreateStep(0);
    setCreateValues({ ...initialCreateValues });
  };

  const handleCreateOpenChange = (open: boolean) => {
    setIsCreateOpen(open);
    if (!open) {
      resetCreateWizard();
    }
  };

  const validateCreateStep = (step: number) => {
    if (step === 0) {
      if (!createValues.name.trim()) {
        toast({
          title: 'Add a group name',
          description: 'Give the public group a recognizable name members will trust.',
          variant: 'destructive',
        });
        return false;
      }
      if (!createValues.purpose.trim()) {
        toast({
          title: 'Describe the group mission',
          description: 'Include a short purpose so the mobile join flow can communicate expectations.',
          variant: 'destructive',
        });
        return false;
      }
      if (!createValues.organizer.trim()) {
        toast({
          title: 'Identify the lead organizer',
          description: 'Members will see who is sponsoring the public cohort.',
          variant: 'destructive',
        });
        return false;
      }
      if (!createValues.organizerPhone.trim()) {
        toast({
          title: 'Capture organizer contact',
          description: 'Provide a MoMo-ready phone number for the organizer.',
          variant: 'destructive',
        });
        return false;
      }
      if (!createValues.location.trim()) {
        toast({
          title: 'Set the primary location',
          description: 'Location helps marketing and support teams target the right members.',
          variant: 'destructive',
        });
        return false;
      }
    }

    if (step === 1) {
      const parsedContribution = Number.parseFloat(createValues.contributionAmount);
      const parsedMembers = Number.parseInt(createValues.memberTarget, 10);

      if (!Number.isFinite(parsedContribution) || parsedContribution <= 0) {
        toast({
          title: 'Contribution must be greater than GH₵0',
          description: 'Set a positive contribution amount before continuing.',
          variant: 'destructive',
        });
        return false;
      }

      if (!Number.isFinite(parsedMembers) || parsedMembers < 3) {
        toast({
          title: 'Set a realistic member target',
          description: 'Public groups should target at least three members to run a cycle.',
          variant: 'destructive',
        });
        return false;
      }

      if (!createValues.startDate) {
        toast({
          title: 'Choose the contribution start date',
          description: 'Pick when recurring contributions begin so reminders can be scheduled.',
          variant: 'destructive',
        });
        return false;
      }

      if (!createValues.firstPayoutDate) {
        toast({
          title: 'Choose the first payout date',
          description: 'Set expectations for when the first member will receive a payout.',
          variant: 'destructive',
        });
        return false;
      }
    }

    return true;
  };

  const handleCreateBack = () => {
    setCreateStep((previous) => Math.max(previous - 1, 0));
  };

  const handleCreateNext = () => {
    const isValid = validateCreateStep(createStep);
    if (!isValid) {
      return;
    }

    if (createStep >= createSteps.length - 1) {
      const now = new Date().toISOString();
      const contributionAmount = Math.round(Number.parseFloat(createValues.contributionAmount) * 100) / 100;
      const targetMembers = Math.max(Number.parseInt(createValues.memberTarget, 10) || 0, 1);
      const prospects = createValues.prospectList
        .split('\n')
        .map((prospect) => prospect.trim())
        .filter((prospect) => prospect.length > 0);

      const inviteEntries = [
        {
          name: createValues.organizer,
          phone: createValues.organizerPhone,
          status: 'Accepted',
          kycCompleted: true,
          sentAt: now,
          respondedAt: now,
          channel: 'Admin invite',
        },
        ...prospects.map((prospect, index) => ({
          name: prospect,
          phone: 'Pending phone',
          status: 'Pending',
          kycCompleted: false,
          sentAt: now,
          channel: index % 2 === 0 ? 'SMS' : 'WhatsApp',
        })),
      ];

      const acceptedCount = 1;
      const pendingCount = inviteEntries.length - acceptedCount;
      const inviteTotal = inviteEntries.length;
      const inviteCompletion = inviteTotal > 0 ? Math.round((acceptedCount / inviteTotal) * 100) : 0;
      const contributionStart = createValues.startDate || createValues.firstPayoutDate;
      const firstPayoutDate = createValues.firstPayoutDate || createValues.startDate;

      const newGroup: Group = {
        id: `group_${Date.now()}`,
        name: createValues.name.trim(),
        members: acceptedCount,
        contributionAmount,
        frequency: createValues.frequency,
        cycleProgress: 0,
        totalPooled: 0,
        nextPayoutDate: firstPayoutDate,
        status: 'Awaiting Approval',
        visibility: 'Public',
        cycleStage: 'Onboarding',
        inviteCompletion,
        inviteStats: {
          total: inviteTotal,
          accepted: acceptedCount,
          pending: Math.max(pendingCount, 0),
          declined: 0,
        },
        remindersDue: pendingCount > 0 ? 1 : 0,
        remindersSent: 0,
        lastReminderAt: now,
        nextPayout: {
          member: createValues.organizer,
          amount: Math.round(contributionAmount * targetMembers * 100) / 100,
          window: 'Cycle 1',
          scheduledAt: firstPayoutDate,
        },
        contributionWindow: createValues.collectionWindow,
        riskFlags: ['Monitor first cycle contributions during onboarding'],
        membersList: [
          {
            name: createValues.organizer,
            currentRotation: 'Next',
            amount: contributionAmount,
            lastContribution: contributionStart || new Date().toISOString().slice(0, 10),
            status: 'Onboarding',
            payoutPosition: 'Cycle 1',
            role: 'Lead Organizer',
          },
        ],
        invites: inviteEntries,
        payoutTimeline: [],
        outstandingReminders:
          pendingCount > 0
            ? [
                {
                  title: 'Follow up with pending prospects',
                  dueAt: firstPayoutDate,
                  owner: 'Community Growth Desk',
                },
              ]
            : [
                {
                  title: 'Welcome orientation session',
                  dueAt: contributionStart,
                  owner: 'Community Growth Desk',
                },
              ],
      };

      setGroups((previous) => [newGroup, ...previous]);
      setVisibilityFilter('public');
      setStageFilter('Onboarding');
      setInviteFilter('all');
      setOpenGroupId(newGroup.id);
      toast({
        title: 'Public group created',
        description: `${createValues.name.trim()} is now available for members to join from the app.`,
      });
      setIsCreateOpen(false);
      resetCreateWizard();
      return;
    }

    setCreateStep((previous) => Math.min(previous + 1, createSteps.length - 1));
  };

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
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <CardTitle>Susu Groups Lifecycle</CardTitle>
              <CardDescription>Track invite health, cycles, and payouts across the platform</CardDescription>
            </div>
            <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-end">
              <Button
                type="button"
                onClick={() => {
                  setIsCreateOpen(true);
                  setCreateStep(0);
                }}
                className="w-full sm:w-auto"
              >
                <Plus className="mr-2 h-4 w-4" /> Add public group
              </Button>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Filter className="h-4 w-4" /> Filters persist in the URL so you can copy your current view.
              </div>
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

                      {group.visibility === 'Public' && (
                        <Card className="shadow-none border">
                          <CardHeader>
                            <CardTitle className="text-base">Public join flow</CardTitle>
                            <CardDescription>{publicGroupJoinFlow.expectation}</CardDescription>
                          </CardHeader>
                          <CardContent className="space-y-4">
                            <div className="grid gap-4 md:grid-cols-3">
                              {publicGroupJoinFlow.steps.map((step) => {
                                const Icon = step.icon;
                                return (
                                  <div
                                    key={step.id}
                                    className="flex h-full flex-col gap-3 rounded-lg border border-border bg-muted/30 p-4"
                                  >
                                    <div className="flex items-center justify-between text-xs font-semibold text-primary">
                                      <span>{step.badge}</span>
                                      <Icon className="h-4 w-4" />
                                    </div>
                                    <div className="space-y-1">
                                      <h4 className="text-sm font-semibold">{step.title}</h4>
                                      <p className="text-xs text-muted-foreground">{step.description}</p>
                                    </div>
                                    <p className="rounded-md bg-background/80 p-2 text-xs text-muted-foreground">
                                      {step.helper}
                                    </p>
                                  </div>
                                );
                              })}
                            </div>
                            <div className="rounded-lg border border-dashed border-primary/40 bg-primary/5 p-4">
                              <p className="text-xs font-semibold uppercase text-primary/80">What members experience</p>
                              <ul className="mt-3 space-y-2 text-sm text-muted-foreground">
                                {publicGroupJoinFlow.highlights.map((highlight) => (
                                  <li key={highlight} className="flex items-start gap-2">
                                    <CheckCircle2 className="mt-0.5 h-4 w-4 text-primary" />
                                    <span>{highlight}</span>
                                  </li>
                                ))}
                              </ul>
                            </div>
                          </CardContent>
                        </Card>
                      )}

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

      <Dialog open={isCreateOpen} onOpenChange={handleCreateOpenChange}>
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>Launch a public susu group</DialogTitle>
            <DialogDescription>
              Capture the details operators need so members can discover and join this cohort from the mobile app.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-6">
            <div className="grid gap-3 sm:grid-cols-3">
              {createSteps.map((step, index) => {
                const isActive = createStep === index;
                const isComplete = createStep > index;
                return (
                  <div
                    key={step.id}
                    className={`rounded-lg border p-3 text-xs ${
                      isActive
                        ? 'border-primary bg-primary/5 text-primary'
                        : isComplete
                        ? 'border-success bg-success/5 text-success'
                        : 'border-border bg-muted/40 text-muted-foreground'
                    }`}
                  >
                    <p className="flex items-center gap-2 font-semibold uppercase tracking-wide">
                      {isComplete ? <Check className="h-3.5 w-3.5" /> : `Step ${index + 1}`}
                    </p>
                    <p className="mt-2 font-semibold text-foreground">{step.title}</p>
                    <p className="mt-1 text-xs">{step.description}</p>
                  </div>
                );
              })}
            </div>

            {createStep === 0 && (
              <div className="space-y-4">
                <div className="grid gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Group name</label>
                    <Input
                      value={createValues.name}
                      onChange={(event) => setCreateValues((values) => ({ ...values, name: event.target.value }))}
                      placeholder="Accra Market Vendors (Public)"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Primary location</label>
                    <Input
                      value={createValues.location}
                      onChange={(event) => setCreateValues((values) => ({ ...values, location: event.target.value }))}
                      placeholder="Accra — Makola Market"
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-medium text-muted-foreground">Purpose & spotlight</label>
                  <Textarea
                    rows={3}
                    value={createValues.purpose}
                    onChange={(event) => setCreateValues((values) => ({ ...values, purpose: event.target.value }))}
                    placeholder="Create a rotating savings cycle for Makola traders to manage stock restock float."
                  />
                </div>
                <div className="grid gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Lead organizer</label>
                    <Input
                      value={createValues.organizer}
                      onChange={(event) => setCreateValues((values) => ({ ...values, organizer: event.target.value }))}
                      placeholder="Ama Darko"
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Organizer contact</label>
                    <Input
                      value={createValues.organizerPhone}
                      onChange={(event) =>
                        setCreateValues((values) => ({ ...values, organizerPhone: event.target.value }))
                      }
                      placeholder="+233 24 123 4567"
                    />
                  </div>
                </div>
              </div>
            )}

            {createStep === 1 && (
              <div className="space-y-4">
                <div className="grid gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Target members</label>
                    <Input
                      type="number"
                      min="3"
                      value={createValues.memberTarget}
                      onChange={(event) =>
                        setCreateValues((values) => ({ ...values, memberTarget: event.target.value }))
                      }
                    />
                    <p className="text-[11px] text-muted-foreground">
                      We recommend at least 8-12 members for liquidity in public cohorts.
                    </p>
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Contribution amount (GH₵)</label>
                    <Input
                      type="number"
                      min="0"
                      step="0.01"
                      value={createValues.contributionAmount}
                      onChange={(event) =>
                        setCreateValues((values) => ({ ...values, contributionAmount: event.target.value }))
                      }
                    />
                  </div>
                </div>
                <div className="grid gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Contribution frequency</label>
                    <Select
                      value={createValues.frequency}
                      onValueChange={(value) => setCreateValues((values) => ({ ...values, frequency: value }))}
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select frequency" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Weekly">Weekly</SelectItem>
                        <SelectItem value="Bi-weekly">Bi-weekly</SelectItem>
                        <SelectItem value="Monthly">Monthly</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Collection window</label>
                    <Input
                      value={createValues.collectionWindow}
                      onChange={(event) =>
                        setCreateValues((values) => ({ ...values, collectionWindow: event.target.value }))
                      }
                      placeholder="Fridays 07:00-20:00 GMT"
                    />
                  </div>
                </div>
                <div className="grid gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">Contribution start date</label>
                    <Input
                      type="date"
                      value={createValues.startDate}
                      onChange={(event) => setCreateValues((values) => ({ ...values, startDate: event.target.value }))}
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-xs font-medium text-muted-foreground">First payout date</label>
                    <Input
                      type="date"
                      value={createValues.firstPayoutDate}
                      onChange={(event) =>
                        setCreateValues((values) => ({ ...values, firstPayoutDate: event.target.value }))
                      }
                    />
                  </div>
                </div>
                <div className="space-y-2">
                  <label className="text-xs font-medium text-muted-foreground">Invite prospects (one per line)</label>
                  <Textarea
                    rows={3}
                    value={createValues.prospectList}
                    onChange={(event) => setCreateValues((values) => ({ ...values, prospectList: event.target.value }))}
                  />
                  <p className="text-[11px] text-muted-foreground">
                    We’ll pre-fill the invite pipeline so you can track reminders immediately.
                  </p>
                </div>
              </div>
            )}

            {createStep === 2 && (
              <div className="space-y-4">
                <Card className="border border-border shadow-none">
                  <CardHeader>
                    <CardTitle className="text-base">Public listing summary</CardTitle>
                    <CardDescription>Double-check the copy members will read before joining.</CardDescription>
                  </CardHeader>
                  <CardContent className="grid gap-4 text-sm">
                    <div>
                      <p className="text-xs text-muted-foreground">Group</p>
                      <p className="font-medium">{createValues.name || '—'}</p>
                      <p className="text-muted-foreground">{createValues.location || 'Location pending'}</p>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Mission</p>
                      <p>{createValues.purpose || 'No mission provided yet.'}</p>
                    </div>
                    <div className="grid gap-3 md:grid-cols-2">
                      <div>
                        <p className="text-xs text-muted-foreground">Organizer</p>
                        <p className="font-medium">{createValues.organizer || '—'}</p>
                        <p className="text-muted-foreground">{createValues.organizerPhone || '—'}</p>
                      </div>
                      <div>
                        <p className="text-xs text-muted-foreground">Contribution cadence</p>
                        <p className="font-medium">
                          GH₵ {createValues.contributionAmount || '0.00'} • {createValues.frequency}
                        </p>
                        <p className="text-muted-foreground">{createValues.collectionWindow}</p>
                      </div>
                    </div>
                    <div className="grid gap-3 md:grid-cols-2">
                      <div>
                        <p className="text-xs text-muted-foreground">Contribution start</p>
                        <p className="font-medium">{createValues.startDate || '—'}</p>
                      </div>
                      <div>
                        <p className="text-xs text-muted-foreground">First payout</p>
                        <p className="font-medium">{createValues.firstPayoutDate || '—'}</p>
                      </div>
                    </div>
                    <div>
                      <p className="text-xs text-muted-foreground">Prospects</p>
                      <ul className="mt-2 list-disc space-y-1 pl-5">
                        {createValues.prospectList
                          .split('\n')
                          .map((prospect) => prospect.trim())
                          .filter((prospect) => prospect.length > 0)
                          .map((prospect) => (
                            <li key={prospect}>{prospect}</li>
                          ))}
                        {createValues.prospectList
                          .split('\n')
                          .map((prospect) => prospect.trim())
                          .filter((prospect) => prospect.length > 0).length === 0 && (
                          <li>No prospects captured yet.</li>
                        )}
                      </ul>
                    </div>
                  </CardContent>
                </Card>
              </div>
            )}
          </div>

          <DialogFooter className="flex flex-col gap-3 sm:flex-row sm:justify-between">
            <div className="text-xs text-muted-foreground">
              Step {createStep + 1} of {createSteps.length}
            </div>
            <div className="flex flex-col gap-2 sm:flex-row">
              <Button
                type="button"
                variant="outline"
                onClick={() => {
                  if (createStep === 0) {
                    handleCreateOpenChange(false);
                    return;
                  }
                  handleCreateBack();
                }}
              >
                <ArrowLeft className="mr-2 h-4 w-4" /> {createStep === 0 ? 'Cancel' : 'Back'}
              </Button>
              <Button type="button" onClick={handleCreateNext}>
                {createStep === createSteps.length - 1 ? (
                  <>
                    <Check className="mr-2 h-4 w-4" /> Create group
                  </>
                ) : (
                  <>
                    Continue <ArrowRight className="ml-2 h-4 w-4" />
                  </>
                )}
              </Button>
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react';
import { useFieldArray, useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { z } from 'zod';
import {
  RefreshCcw,
  Phone,
  Plus,
  UserPlus,
  Check,
  X,
  Trash2,
  PencilLine,
  Users,
  Calendar,
  DollarSign,
  TrendingUp,
  AlertTriangle,
  Clock,
  Send,
  Filter,
  Search,
} from 'lucide-react';
import { useSearchParams } from 'react-router-dom';

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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { useAuthorizedApi } from '@/lib/auth';
import type {
  AdminGroup,
  AdminGroupInvite,
  AdminGroupMember,
  PaginatedResponse,
} from '@/lib/types';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Progress } from '@/components/ui/progress';

const formatCurrency = (value: string | number) => {
  const numeric = typeof value === 'string' ? Number(value) : value;
  return `GH₵ ${numeric.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
};

const formatDate = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });
};

const formatDateTimeLocal = (value: string) => {
  if (!value) return '';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  const pad = (input: number) => input.toString().padStart(2, '0');
  return `${parsed.getFullYear()}-${pad(parsed.getMonth() + 1)}-${pad(parsed.getDate())}T${pad(parsed.getHours())}:${pad(
    parsed.getMinutes(),
  )}`;
};

const toIsoString = (value: string) => {
  if (!value) return value;
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toISOString();
};

const inviteSchema = z.object({
  name: z.string().min(1, 'Name is required'),
  phone_number: z.string().min(1, 'Phone number is required'),
});

const groupFormSchema = z.object({
  name: z.string().min(1, 'Group name is required'),
  description: z.string().optional(),
  frequency: z.string().optional(),
  location: z.string().optional(),
  requires_approval: z.boolean().default(true),
  is_public: z.boolean().default(true),
  contribution_amount: z.coerce.number().min(1, 'Contribution amount is required'),
  target_member_count: z.coerce.number().min(1, 'Target member count is required'),
  next_payout_date: z.string().min(1, 'Next payout date is required'),
  invites: z.array(inviteSchema).default([]),
});

type GroupFormValues = z.infer<typeof groupFormSchema>;

type GroupPayload = {
  name: string;
  description: string;
  frequency: string;
  location: string;
  requires_approval: boolean;
  is_public: boolean;
  target_member_count: number;
  contribution_amount: string;
  next_payout_date: string;
  invites?: Array<{ name: string; phone_number: string }>;
};

const defaultGroupFormValues: GroupFormValues = {
  name: '',
  description: '',
  frequency: '',
  location: '',
  requires_approval: true,
  is_public: true,
  contribution_amount: 100,
  target_member_count: 10,
  next_payout_date: '',
  invites: [],
};

const allowedVisibility = ['all', 'private', 'public'] as const;
const allowedStages = ['all', 'Onboarding', 'Contributions', 'Payout', 'Completed'] as const;
const allowedInviteFilters = ['all', 'healthy', 'watch', 'risk'] as const;

type VisibilityFilter = (typeof allowedVisibility)[number];
type StageFilter = (typeof allowedStages)[number];
type InviteFilter = (typeof allowedInviteFilters)[number];

const stageTone: Record<Exclude<StageFilter, 'all'>, string> = {
  Onboarding: 'bg-primary/10 text-primary border-primary/20',
  Contributions: 'bg-success/10 text-success border-success/20',
  Payout: 'bg-warning/10 text-warning border-warning/20',
  Completed: 'bg-muted text-muted-foreground border-border',
};

const inviteHealthLabels: Record<Exclude<InviteFilter, 'all'>, { label: string; description: string }> = {
  healthy: { label: 'Healthy', description: '≥85% of invited members have joined' },
  watch: { label: 'Monitor', description: '60-84% completion—watch momentum' },
  risk: { label: 'At Risk', description: '<60% completion—needs action' },
};

const normalizeParam = (value: string | null) => {
  if (!value) return null;
  const trimmed = value.trim();
  if (!trimmed || trimmed === 'null' || trimmed === 'undefined') {
    return null;
  }
  return trimmed;
};

const daysUntil = (value: string) => {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return Infinity;
  }
  const now = new Date();
  const diff = parsed.getTime() - now.getTime();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
};

const getInviteCompletion = (group: AdminGroup) => {
  if (!group.target_member_count) {
    return 0;
  }
  return Math.min(100, Math.round((group.member_count / group.target_member_count) * 100));
};

const getInviteHealth = (completion: number): Exclude<InviteFilter, 'all'> => {
  if (completion >= 85) return 'healthy';
  if (completion >= 60) return 'watch';
  return 'risk';
};

const getCycleProgress = (group: AdminGroup) => {
  if (!group.total_cycles) return 0;
  const progress = Math.round((group.cycle_number / group.total_cycles) * 100);
  return Math.max(0, Math.min(progress, 100));
};

const determineStage = (group: AdminGroup & { inviteCompletion: number; daysUntilPayout: number }): Exclude<StageFilter, 'all'> => {
  if (group.total_cycles && group.cycle_number >= group.total_cycles) {
    return 'Completed';
  }
  if (group.member_count < Math.max(group.target_member_count * 0.7, 1)) {
    return 'Onboarding';
  }
  if (group.daysUntilPayout <= 7) {
    return 'Payout';
  }
  return 'Contributions';
};

type EnrichedGroup = AdminGroup & {
  inviteCompletion: number;
  inviteHealth: Exclude<InviteFilter, 'all'>;
  cycleProgress: number;
  daysUntilPayout: number;
  stage: Exclude<StageFilter, 'all'>;
  estimatedTotalPooled: number;
};

export default function Groups() {
  const api = useAuthorizedApi();
  const queryClient = useQueryClient();
  const { toast } = useToast();
  const [searchParams, setSearchParams] = useSearchParams();

  const initialVisibility = (() => {
    const value = normalizeParam(searchParams.get('visibility'));
    return value && allowedVisibility.includes(value as VisibilityFilter)
      ? (value as VisibilityFilter)
      : 'all';
  })();

  const initialStage = (() => {
    const value = normalizeParam(searchParams.get('stage'));
    return value && allowedStages.includes(value as StageFilter) ? (value as StageFilter) : 'all';
  })();

  const initialInvite = (() => {
    const value = normalizeParam(searchParams.get('invite'));
    return value && allowedInviteFilters.includes(value as InviteFilter)
      ? (value as InviteFilter)
      : 'all';
  })();

  const [searchQuery, setSearchQuery] = useState(() => normalizeParam(searchParams.get('search')) ?? '');
  const [visibilityFilter, setVisibilityFilter] = useState<VisibilityFilter>(initialVisibility);
  const [stageFilter, setStageFilter] = useState<StageFilter>(initialStage);
  const [inviteFilter, setInviteFilter] = useState<InviteFilter>(initialInvite);

  const rawSearchString = searchParams.toString();

  const normalizedSearchString = useMemo(() => {
    const params = new URLSearchParams();
    const sanitizedSearch = normalizeParam(searchParams.get('search'));
    const sanitizedVisibility = normalizeParam(searchParams.get('visibility'));
    const sanitizedStage = normalizeParam(searchParams.get('stage'));
    const sanitizedInvite = normalizeParam(searchParams.get('invite'));

    if (sanitizedSearch) params.set('search', sanitizedSearch);
    if (sanitizedVisibility && allowedVisibility.includes(sanitizedVisibility as VisibilityFilter) && sanitizedVisibility !== 'all') {
      params.set('visibility', sanitizedVisibility);
    }
    if (sanitizedStage && allowedStages.includes(sanitizedStage as StageFilter) && sanitizedStage !== 'all') {
      params.set('stage', sanitizedStage);
    }
    if (sanitizedInvite && allowedInviteFilters.includes(sanitizedInvite as InviteFilter) && sanitizedInvite !== 'all') {
      params.set('invite', sanitizedInvite);
    }

    return params.toString();
  }, [searchParams]);
  const [selectedGroup, setSelectedGroup] = useState<AdminGroup | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [formOpen, setFormOpen] = useState(false);
  const [editingGroup, setEditingGroup] = useState<AdminGroup | null>(null);
  const [inviteDraft, setInviteDraft] = useState({ name: '', phone_number: '' });
  const [inviteActionId, setInviteActionId] = useState<string | null>(null);
  const [inviteDeleteId, setInviteDeleteId] = useState<string | null>(null);
  const [memberActionId, setMemberActionId] = useState<string | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const groupForm = useForm<GroupFormValues>({
    resolver: zodResolver(groupFormSchema),
    defaultValues: defaultGroupFormValues,
  });

  const invitesArray = useFieldArray({ control: groupForm.control, name: 'invites' });

  useEffect(() => {
    const params = new URLSearchParams();
    if (searchQuery) params.set('search', searchQuery);
    if (visibilityFilter !== 'all') params.set('visibility', visibilityFilter);
    if (stageFilter !== 'all') params.set('stage', stageFilter);
    if (inviteFilter !== 'all') params.set('invite', inviteFilter);
    const next = params.toString();
    if (next !== normalizedSearchString || rawSearchString !== normalizedSearchString) {
      setSearchParams(params, { replace: true });
    }
  }, [inviteFilter, normalizedSearchString, rawSearchString, searchQuery, setSearchParams, stageFilter, visibilityFilter]);

  const queryString = useMemo(() => {
    const params = new URLSearchParams();
    if (searchQuery) params.set('search', searchQuery);
    if (visibilityFilter !== 'all') params.set('is_public', visibilityFilter === 'public' ? 'true' : 'false');
    return params.toString();
  }, [searchQuery, visibilityFilter]);

  const endpoint = queryString ? `/api/admin/groups/?${queryString}` : '/api/admin/groups/';

  const groupsQuery = useQuery<PaginatedResponse<AdminGroup>>({
    queryKey: ['admin-groups', endpoint],
    queryFn: () => api(endpoint),
    keepPreviousData: true,
    refetchOnMount: 'always',
  });

  const groupsErrorMessage =
    groupsQuery.error instanceof Error
      ? groupsQuery.error.message
      : 'We could not load Susu groups. Please try again shortly.';

  const groups = groupsQuery.data?.results ?? [];

  const enrichedGroups = useMemo<EnrichedGroup[]>(() => {
    return groups.map((group) => {
      const inviteCompletion = getInviteCompletion(group);
      const inviteHealth = getInviteHealth(inviteCompletion);
      const cycleProgress = getCycleProgress(group);
      const daysUntilPayout = daysUntil(group.next_payout_date);
      const stage = determineStage({ ...group, inviteCompletion, daysUntilPayout });
      const numericContribution = Number(group.contribution_amount ?? 0);
      const estimatedTotalPooled = Number.isFinite(numericContribution)
        ? Math.max(0, Math.round(numericContribution * Math.max(group.member_count, 0)))
        : 0;

      return {
        ...group,
        inviteCompletion,
        inviteHealth,
        cycleProgress,
        daysUntilPayout,
        stage,
        estimatedTotalPooled,
      };
    });
  }, [groups]);

  const normalizedSearch = searchQuery.trim().toLowerCase();

  const filteredGroups = useMemo(() => {
    return enrichedGroups.filter((group) => {
      if (visibilityFilter !== 'all') {
        const isPublic = visibilityFilter === 'public';
        if (group.is_public !== isPublic) {
          return false;
        }
      }

      if (stageFilter !== 'all' && group.stage !== stageFilter) {
        return false;
      }

      if (inviteFilter !== 'all' && group.inviteHealth !== inviteFilter) {
        return false;
      }

      if (normalizedSearch) {
        const owner = group.owner_name?.toLowerCase() ?? '';
        const location = group.location?.toLowerCase() ?? '';
        const matchesName = group.name.toLowerCase().includes(normalizedSearch);
        const matchesOwner = owner.includes(normalizedSearch);
        const matchesLocation = location.includes(normalizedSearch);
        if (!matchesName && !matchesOwner && !matchesLocation) {
          return false;
        }
      }

      return true;
    });
  }, [enrichedGroups, inviteFilter, normalizedSearch, stageFilter, visibilityFilter]);

  const summary = useMemo(() => {
    const total = filteredGroups.length;
    const baselineCompletion = enrichedGroups.length
      ? Math.round(
          enrichedGroups.reduce((acc, group) => acc + group.inviteCompletion, 0) / enrichedGroups.length,
        )
      : 0;
    const averageInviteCompletion =
      total > 0
        ? Math.round(filteredGroups.reduce((acc, group) => acc + group.inviteCompletion, 0) / total)
        : baselineCompletion;

    return {
      total,
      atRisk: filteredGroups.filter((group) => group.inviteHealth === 'risk').length,
      payoutsSoon: filteredGroups.filter((group) => group.daysUntilPayout <= 7).length,
      reminders: filteredGroups.reduce((acc, group) => acc + group.pending_invites, 0),
      averageInviteCompletion: Number.isFinite(averageInviteCompletion) ? averageInviteCompletion : 0,
    };
  }, [enrichedGroups, filteredGroups]);

  const emptyState = !groupsQuery.isLoading && !groupsQuery.isError && filteredGroups.length === 0;

  const resetFilters = () => {
    setVisibilityFilter('all');
    setStageFilter('all');
    setInviteFilter('all');
    setSearchQuery('');
  };

  const refreshGroup = useCallback(
    async (groupId: string, invalidate = false) => {
      const latest = await api<AdminGroup>(`/api/admin/groups/${groupId}/`);
      setSelectedGroup(latest);
      if (invalidate) {
        queryClient.invalidateQueries({ queryKey: ['admin-groups'] });
      }
      return latest;
    },
    [api, queryClient],
  );

  const openGroup = (group: AdminGroup) => {
    setSelectedGroup(group);
    setDrawerOpen(true);
    refreshGroup(group.id).catch(() => {
      toast({ title: 'Unable to load group', description: 'Please try again in a moment.', variant: 'destructive' });
    });
  };

  const closeDrawer = (open: boolean) => {
    setDrawerOpen(open);
    if (!open) {
      setSelectedGroup(null);
      setDeleteDialogOpen(false);
    }
  };

  const openCreateForm = () => {
    setEditingGroup(null);
    groupForm.reset({ ...defaultGroupFormValues, invites: [] });
    invitesArray.replace([]);
    setFormOpen(true);
  };

  const openEditForm = (group: AdminGroup) => {
    setEditingGroup(group);
    groupForm.reset({
      name: group.name,
      description: group.description ?? '',
      frequency: group.frequency ?? '',
      location: group.location ?? '',
      requires_approval: group.requires_approval,
      is_public: group.is_public,
      contribution_amount: Number(group.contribution_amount),
      target_member_count: group.target_member_count,
      next_payout_date: formatDateTimeLocal(group.next_payout_date),
      invites: [],
    });
    invitesArray.replace([]);
    setFormOpen(true);
  };

  const isEditing = Boolean(editingGroup);

  const toPayload = (values: GroupFormValues, includeInvites: boolean): GroupPayload => {
    const filteredInvites = includeInvites
      ? values.invites
          .map((invite) => ({ name: invite.name.trim(), phone_number: invite.phone_number.trim() }))
          .filter((invite) => invite.name && invite.phone_number)
      : undefined;

    return {
      name: values.name.trim(),
      description: values.description?.trim() ?? '',
      frequency: values.frequency?.trim() ?? '',
      location: values.location?.trim() ?? '',
      requires_approval: values.requires_approval,
      is_public: values.is_public,
      target_member_count: values.target_member_count,
      contribution_amount: values.contribution_amount.toFixed(2),
      next_payout_date: toIsoString(values.next_payout_date),
      invites: filteredInvites,
    };
  };

  const createGroupMutation = useMutation({
    mutationFn: (body: GroupPayload) =>
      api<AdminGroup>('/api/admin/groups/', {
        method: 'POST',
        body: JSON.stringify(body),
      }),
    onSuccess: async (data) => {
      toast({ title: 'Public group created', description: 'The group is now available for members to discover.' });
      setFormOpen(false);
      groupForm.reset(defaultGroupFormValues);
      invitesArray.replace([]);
      await refreshGroup(data.id, true);
      setDrawerOpen(true);
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to create the group.';
      toast({ title: 'Creation failed', description: message, variant: 'destructive' });
    },
  });

  const updateGroupMutation = useMutation({
    mutationFn: (payload: { id: string; body: GroupPayload }) =>
      api<AdminGroup>(`/api/admin/groups/${payload.id}/`, {
        method: 'PATCH',
        body: JSON.stringify(payload.body),
      }),
    onSuccess: async (data) => {
      toast({ title: 'Group updated', description: 'Changes have been saved successfully.' });
      setFormOpen(false);
      await refreshGroup(data.id, true);
      setDrawerOpen(true);
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to update the group.';
      toast({ title: 'Update failed', description: message, variant: 'destructive' });
    },
  });

  const deleteGroupMutation = useMutation({
    mutationFn: (groupId: string) =>
      api(`/api/admin/groups/${groupId}/`, {
        method: 'DELETE',
      }),
    onSuccess: (_, groupId) => {
      toast({ title: 'Group deleted', description: 'The group has been removed from discovery.' });
      setDeleteDialogOpen(false);
      closeDrawer(false);
      if (selectedGroup?.id === groupId) {
        setSelectedGroup(null);
      }
      queryClient.invalidateQueries({ queryKey: ['admin-groups'] });
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to delete the group.';
      toast({ title: 'Deletion failed', description: message, variant: 'destructive' });
    },
  });

  const createInviteMutation = useMutation({
    mutationFn: (payload: { groupId: string; invites: Array<{ name: string; phone_number: string }> }) =>
      api<AdminGroup>(`/api/admin/groups/${payload.groupId}/invites/`, {
        method: 'POST',
        body: JSON.stringify({ invites: payload.invites }),
      }),
    onSuccess: async (_, variables) => {
      toast({ title: 'Invite sent', description: 'The member has been invited to join the group.' });
      setInviteDraft({ name: '', phone_number: '' });
      await refreshGroup(variables.groupId, true);
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to create the invite.';
      toast({ title: 'Invite failed', description: message, variant: 'destructive' });
    },
  });

  const approveInviteMutation = useMutation({
    mutationFn: (payload: { groupId: string; inviteId: string }) =>
      api<AdminGroup>(`/api/admin/groups/${payload.groupId}/invites/${payload.inviteId}/approve/`, {
        method: 'POST',
        body: JSON.stringify({}),
      }),
    onMutate: (variables) => {
      setInviteActionId(variables.inviteId);
    },
    onSuccess: async (_, variables) => {
      toast({ title: 'Member approved', description: 'The member has been added to the circle.' });
      await refreshGroup(variables.groupId, true);
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to approve the invite.';
      toast({ title: 'Approval failed', description: message, variant: 'destructive' });
    },
    onSettled: () => {
      setInviteActionId(null);
    },
  });

  const declineInviteMutation = useMutation({
    mutationFn: (payload: { groupId: string; inviteId: string }) =>
      api<AdminGroup>(`/api/admin/groups/${payload.groupId}/invites/${payload.inviteId}/decline/`, {
        method: 'POST',
        body: JSON.stringify({}),
      }),
    onMutate: (variables) => {
      setInviteActionId(variables.inviteId);
    },
    onSuccess: async (_, variables) => {
      toast({ title: 'Invite declined', description: 'The invite has been marked as declined.' });
      await refreshGroup(variables.groupId, true);
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to decline the invite.';
      toast({ title: 'Decline failed', description: message, variant: 'destructive' });
    },
    onSettled: () => {
      setInviteActionId(null);
    },
  });

  const deleteInviteMutation = useMutation({
    mutationFn: (payload: { groupId: string; inviteId: string }) =>
      api<AdminGroup>(`/api/admin/groups/${payload.groupId}/invites/${payload.inviteId}/`, {
        method: 'DELETE',
      }),
    onMutate: (variables) => {
      setInviteDeleteId(variables.inviteId);
    },
    onSuccess: async (_, variables) => {
      toast({ title: 'Invite removed', description: 'The pending invite has been withdrawn.' });
      await refreshGroup(variables.groupId, true);
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to remove the invite.';
      toast({ title: 'Removal failed', description: message, variant: 'destructive' });
    },
    onSettled: () => {
      setInviteDeleteId(null);
    },
  });

  const removeMemberMutation = useMutation({
    mutationFn: (payload: { groupId: string; memberId: string }) =>
      api<AdminGroup>(`/api/admin/groups/${payload.groupId}/members/${payload.memberId}/`, {
        method: 'DELETE',
      }),
    onMutate: (variables) => {
      setMemberActionId(variables.memberId);
    },
    onSuccess: async (_, variables) => {
      toast({ title: 'Member removed', description: 'The member has been removed from the circle.' });
      await refreshGroup(variables.groupId, true);
    },
    onError: (error: unknown) => {
      const message = error instanceof Error ? error.message : 'Unable to remove the member.';
      toast({ title: 'Removal failed', description: message, variant: 'destructive' });
    },
    onSettled: () => {
      setMemberActionId(null);
    },
  });

  const handleInviteSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!selectedGroup) return;
    if (!inviteDraft.name.trim() || !inviteDraft.phone_number.trim()) {
      toast({ title: 'Invite details required', description: 'Add a name and phone number before sending.', variant: 'destructive' });
      return;
    }
    createInviteMutation.mutate({
      groupId: selectedGroup.id,
      invites: [{ name: inviteDraft.name.trim(), phone_number: inviteDraft.phone_number.trim() }],
    });
  };

  const handleFormSubmit = (values: GroupFormValues) => {
    const payload = toPayload(values, !isEditing);
    if (isEditing && editingGroup) {
      updateGroupMutation.mutate({ id: editingGroup.id, body: payload });
    } else {
      createGroupMutation.mutate(payload);
    }
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
            <p className="text-xs text-muted-foreground">
              Average invite completion {summary.averageInviteCompletion}%
            </p>
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
              <Button type="button" onClick={openCreateForm} className="w-full sm:w-auto">
                <Plus className="mr-2 h-4 w-4" /> Add public group
              </Button>
              <Button
                variant="outline"
                onClick={() => groupsQuery.refetch()}
                disabled={groupsQuery.isFetching}
                className="w-full sm:w-auto"
              >
                <RefreshCcw className={`mr-2 h-4 w-4 ${groupsQuery.isFetching ? 'animate-spin' : ''}`} />
                Refresh
              </Button>
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
                  {(Object.keys(inviteHealthLabels) as Array<Exclude<InviteFilter, 'all'>>).map((key) => (
                    <SelectItem key={key} value={key}>
                      {inviteHealthLabels[key].label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Search by group name, owner, or location"
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                className="pl-10"
              />
            </div>
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <Filter className="h-4 w-4" />
              <span>Filters persist in the URL so you can share this view.</span>
            </div>
          </div>

          {groupsQuery.isLoading ? (
            <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 3 }).map((_, index) => (
                <Skeleton key={index} className="h-[300px] w-full rounded-xl" />
              ))}
            </div>
          ) : groupsQuery.isError ? (
            <div className="flex flex-col items-center justify-center gap-4 rounded-lg border border-destructive/40 bg-destructive/5 p-10 text-center">
              <div className="space-y-2">
                <p className="text-sm font-semibold text-destructive">We ran into an issue loading Susu groups.</p>
                <p className="text-sm text-muted-foreground">{groupsErrorMessage}</p>
              </div>
              <Button onClick={() => groupsQuery.refetch()} disabled={groupsQuery.isFetching}>
                <RefreshCcw className={`mr-2 h-4 w-4 ${groupsQuery.isFetching ? 'animate-spin' : ''}`} />
                Try again
              </Button>
            </div>
          ) : emptyState ? (
            <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-border p-12 text-center">
              <p className="text-sm font-medium text-foreground">No groups match your filters.</p>
              <p className="mt-2 text-sm text-muted-foreground">
                Adjust the visibility, cycle stage, or invite health filters to explore other cohorts.
              </p>
              <Button variant="ghost" size="sm" className="mt-3" onClick={resetFilters}>
                Reset filters
              </Button>
            </div>
          ) : (
            <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
              {filteredGroups.map((group) => {
                const stageBadgeTone = stageTone[group.stage] ?? stageTone.Contributions;
                const inviteMeta = inviteHealthLabels[group.inviteHealth];
                return (
                  <button
                    type="button"
                    key={group.id}
                    onClick={() => openGroup(group)}
                    className="text-left"
                  >
                    <Card className="h-full cursor-pointer transition-smooth hover:border-primary/40 hover:shadow-custom-md">
                      <CardHeader className="space-y-4 pb-4">
                        <div className="flex flex-wrap items-start justify-between gap-2">
                          <CardTitle className="text-lg font-semibold">{group.name}</CardTitle>
                          <div className="flex flex-wrap items-center gap-2">
                            <StatusBadge status={group.requires_approval ? 'Approval required' : 'Active'} />
                            <Badge variant="outline" className={stageBadgeTone}>
                              {group.stage}
                            </Badge>
                          </div>
                        </div>
                        <div className="flex flex-wrap gap-2">
                          <Badge variant="secondary">{group.is_public ? 'Public' : 'Private'}</Badge>
                          <Badge variant="outline">{group.owner_name ?? 'Platform managed'}</Badge>
                        </div>
                        <div className="grid gap-3 sm:grid-cols-2">
                          <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                            <Users className="h-4 w-4 text-muted-foreground" />
                            <div>
                              <p className="text-xs text-muted-foreground">Members</p>
                              <p className="text-sm font-semibold">
                                {group.member_count} / {group.target_member_count}
                              </p>
                            </div>
                          </div>
                          <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                            <DollarSign className="h-4 w-4 text-muted-foreground" />
                            <div>
                              <p className="text-xs text-muted-foreground">Contribution</p>
                              <p className="text-sm font-semibold">{formatCurrency(group.contribution_amount)}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                            <Calendar className="h-4 w-4 text-muted-foreground" />
                            <div>
                              <p className="text-xs text-muted-foreground">Frequency</p>
                              <p className="text-sm font-semibold">{group.frequency || 'Not set'}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-3 rounded-lg border border-border p-3">
                            <TrendingUp className="h-4 w-4 text-muted-foreground" />
                            <div>
                              <p className="text-xs text-muted-foreground">Est. pooled</p>
                              <p className="text-sm font-semibold">{formatCurrency(group.estimatedTotalPooled)}</p>
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
                          <p className="text-xs text-muted-foreground">{inviteMeta.description}</p>
                        </div>
                        <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-muted-foreground">
                          <Badge variant="outline">Pending invites: {group.pending_invites}</Badge>
                          <span>
                            {group.daysUntilPayout === Infinity
                              ? 'Payout schedule TBC'
                              : group.daysUntilPayout > 0
                                ? `Payout in ${group.daysUntilPayout} days`
                                : 'Payout in progress'}
                          </span>
                        </div>
                      </CardContent>
                    </Card>
                  </button>
                );
              })}
            </div>
          )}
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
                    {selectedGroup.requires_approval && <Badge variant="outline">Approval required</Badge>}
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
                  <h3 className="text-sm font-semibold text-muted-foreground">Active members</h3>
                  {selectedGroup.members.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No approved members yet.</p>
                  ) : (
                    <div className="space-y-3">
                      {selectedGroup.members.map((member: AdminGroupMember) => (
                        <div key={member.id} className="flex items-center justify-between rounded-lg border border-border p-4">
                          <div>
                            <p className="text-sm font-semibold text-foreground">{member.name}</p>
                            <p className="text-xs text-muted-foreground">{member.phone_number}</p>
                            <p className="text-xs text-muted-foreground">Joined {formatDate(member.joined_at)}</p>
                          </div>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() =>
                              removeMemberMutation.mutate({ groupId: selectedGroup.id, memberId: member.id })
                            }
                            disabled={memberActionId === member.id && removeMemberMutation.isPending}
                          >
                            <Trash2 className="mr-2 h-4 w-4" /> Remove
                          </Button>
                        </div>
                      ))}
                    </div>
                  )}
                </section>

                <section className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-muted-foreground">Invites</h3>
                    <Badge variant="outline">{selectedGroup.pending_invites} pending</Badge>
                  </div>
                  {selectedGroup.invites.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No pending invites.</p>
                  ) : (
                    <div className="space-y-2">
                      {selectedGroup.invites.map((invite: AdminGroupInvite) => (
                        <div key={invite.id} className="rounded-lg border border-border p-4">
                          <div className="flex items-center justify-between text-sm">
                            <span className="font-semibold text-foreground">{invite.name}</span>
                            <StatusBadge status={invite.status.charAt(0).toUpperCase() + invite.status.slice(1)} />
                          </div>
                          <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
                            <Phone className="h-3 w-3" />
                            <span>{invite.phone_number}</span>
                          </div>
                          <p className="mt-2 text-xs text-muted-foreground">Sent {formatDate(invite.sent_at)}</p>
                          <div className="mt-3 flex flex-wrap gap-2">
                            {invite.status === 'pending' && (
                              <>
                                <Button
                                  size="sm"
                                  onClick={() =>
                                    approveInviteMutation.mutate({ groupId: selectedGroup.id, inviteId: invite.id })
                                  }
                                  disabled={inviteActionId === invite.id && approveInviteMutation.isPending}
                                >
                                  <Check className="mr-2 h-4 w-4" /> Approve
                                </Button>
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() =>
                                    declineInviteMutation.mutate({ groupId: selectedGroup.id, inviteId: invite.id })
                                  }
                                  disabled={inviteActionId === invite.id && declineInviteMutation.isPending}
                                >
                                  <X className="mr-2 h-4 w-4" /> Decline
                                </Button>
                              </>
                            )}
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() =>
                                deleteInviteMutation.mutate({ groupId: selectedGroup.id, inviteId: invite.id })
                              }
                              disabled={inviteDeleteId === invite.id && deleteInviteMutation.isPending}
                            >
                              <Trash2 className="mr-2 h-4 w-4" /> Remove
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  <form onSubmit={handleInviteSubmit} className="mt-4 space-y-3 rounded-lg border border-dashed border-border p-4">
                    <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
                      <UserPlus className="h-4 w-4" />
                      Add invite
                    </div>
                    <div className="grid gap-3 sm:grid-cols-[1fr,1fr,auto]">
                      <Input
                        placeholder="Member name"
                        value={inviteDraft.name}
                        onChange={(event) => setInviteDraft((prev) => ({ ...prev, name: event.target.value }))}
                      />
                      <Input
                        placeholder="Phone number"
                        value={inviteDraft.phone_number}
                        onChange={(event) => setInviteDraft((prev) => ({ ...prev, phone_number: event.target.value }))}
                      />
                      <Button
                        type="submit"
                        disabled={createInviteMutation.isPending}
                      >
                        <Plus className="mr-2 h-4 w-4" /> Send invite
                      </Button>
                    </div>
                  </form>
                </section>
              </div>
            </ScrollArea>
          ) : (
            <div className="p-6 text-sm text-muted-foreground">Select a group to view details.</div>
          )}
          <DrawerFooter className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            {selectedGroup && (
              <div className="flex flex-wrap gap-2">
                <Button variant="outline" onClick={() => openEditForm(selectedGroup)}>
                  <PencilLine className="mr-2 h-4 w-4" />
                  Edit group
                </Button>
                <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
                  <AlertDialogTrigger asChild>
                    <Button variant="destructive">Delete group</Button>
                  </AlertDialogTrigger>
                  <AlertDialogContent>
                    <AlertDialogHeader>
                      <AlertDialogTitle>Delete this group?</AlertDialogTitle>
                      <AlertDialogDescription>
                        Removing the group will hide it from discovery and clear pending invites. This action cannot be undone.
                      </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                      <AlertDialogCancel>Cancel</AlertDialogCancel>
                      <AlertDialogAction
                        onClick={() =>
                          selectedGroup && deleteGroupMutation.mutate(selectedGroup.id)
                        }
                        disabled={deleteGroupMutation.isPending}
                      >
                        Delete
                      </AlertDialogAction>
                    </AlertDialogFooter>
                  </AlertDialogContent>
                </AlertDialog>
              </div>
            )}
            <Button variant="outline" onClick={() => closeDrawer(false)}>
              Close
            </Button>
          </DrawerFooter>
        </DrawerContent>
      </Drawer>

      <Dialog open={formOpen} onOpenChange={setFormOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>{isEditing ? 'Update Susu group' : 'Create public Susu group'}</DialogTitle>
            <DialogDescription>
              {isEditing
                ? 'Adjust contribution settings, descriptions, or cycle targets for this group.'
                : 'Publish a new public group that members can discover and request to join.'}
            </DialogDescription>
          </DialogHeader>
          <Form {...groupForm}>
            <form onSubmit={groupForm.handleSubmit(handleFormSubmit)} className="space-y-6">
              <div className="grid gap-4 sm:grid-cols-2">
                <FormField
                  control={groupForm.control}
                  name="name"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Group name</FormLabel>
                      <FormControl>
                        <Input placeholder="Downtown Susu" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={groupForm.control}
                  name="location"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Location</FormLabel>
                      <FormControl>
                        <Input placeholder="Accra" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={groupForm.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Description</FormLabel>
                    <FormControl>
                      <Textarea rows={3} placeholder="Weekly contributions for market traders" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="grid gap-4 sm:grid-cols-2">
                <FormField
                  control={groupForm.control}
                  name="frequency"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Contribution cadence</FormLabel>
                      <FormControl>
                        <Input placeholder="Weekly" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={groupForm.control}
                  name="next_payout_date"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Next payout date</FormLabel>
                      <FormControl>
                        <Input type="datetime-local" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <FormField
                  control={groupForm.control}
                  name="contribution_amount"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Contribution amount (GHS)</FormLabel>
                      <FormControl>
                        <Input type="number" step="0.01" min="1" value={field.value ?? ''} onChange={field.onChange} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={groupForm.control}
                  name="target_member_count"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Target members</FormLabel>
                      <FormControl>
                        <Input type="number" min="1" value={field.value ?? ''} onChange={field.onChange} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <FormField
                  control={groupForm.control}
                  name="requires_approval"
                  render={({ field }) => (
                    <FormItem className="flex items-center justify-between rounded-lg border border-border p-3">
                      <div>
                        <FormLabel className="text-base">Require admin approval</FormLabel>
                        <FormDescription>Members must be approved before joining.</FormDescription>
                      </div>
                      <FormControl>
                        <Switch checked={field.value} onCheckedChange={field.onChange} />
                      </FormControl>
                    </FormItem>
                  )}
                />
                <FormField
                  control={groupForm.control}
                  name="is_public"
                  render={({ field }) => (
                    <FormItem className="flex items-center justify-between rounded-lg border border-border p-3">
                      <div>
                        <FormLabel className="text-base">Publicly discoverable</FormLabel>
                        <FormDescription>Keep enabled so it appears in the join catalogue.</FormDescription>
                      </div>
                      <FormControl>
                        <Switch checked={field.value} onCheckedChange={field.onChange} />
                      </FormControl>
                    </FormItem>
                  )}
                />
              </div>

              {!isEditing && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <FormLabel className="text-base">Pre-approved invites</FormLabel>
                    <Button type="button" variant="outline" size="sm" onClick={() => invitesArray.append({ name: '', phone_number: '' })}>
                      <Plus className="mr-2 h-4 w-4" /> Add invite
                    </Button>
                  </div>
                  {invitesArray.fields.length === 0 ? (
                    <p className="text-sm text-muted-foreground">Add optional invites to seed the group with trusted members.</p>
                  ) : (
                    <div className="space-y-3">
                      {invitesArray.fields.map((field, index) => (
                        <div key={field.id} className="grid gap-3 sm:grid-cols-[1fr,1fr,auto]">
                          <FormField
                            control={groupForm.control}
                            name={`invites.${index}.name`}
                            render={({ field: inviteField }) => (
                              <FormItem>
                                <FormLabel className="sr-only">Invite name</FormLabel>
                                <FormControl>
                                  <Input placeholder="Member name" {...inviteField} />
                                </FormControl>
                                <FormMessage />
                              </FormItem>
                            )}
                          />
                          <FormField
                            control={groupForm.control}
                            name={`invites.${index}.phone_number`}
                            render={({ field: inviteField }) => (
                              <FormItem>
                                <FormLabel className="sr-only">Invite phone</FormLabel>
                                <FormControl>
                                  <Input placeholder="Phone number" {...inviteField} />
                                </FormControl>
                                <FormMessage />
                              </FormItem>
                            )}
                          />
                          <Button
                            type="button"
                            variant="ghost"
                            size="icon"
                            onClick={() => invitesArray.remove(index)}
                            aria-label="Remove invite"
                          >
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              <DialogFooter>
                <Button type="button" variant="outline" onClick={() => setFormOpen(false)}>
                  Cancel
                </Button>
                <Button
                  type="submit"
                  disabled={createGroupMutation.isPending || updateGroupMutation.isPending}
                >
                  {isEditing ? 'Save changes' : 'Create group'}
                </Button>
              </DialogFooter>
            </form>
          </Form>
        </DialogContent>
      </Dialog>

    </div>
  );
}

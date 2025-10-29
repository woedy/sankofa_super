export interface DashboardMetrics {
  kpis: Record<
    string,
    {
      current: number;
      previous: number;
    }
  >;
  daily_volume: Array<{ date: string; volume: string }>;
  contribution_mix: Array<{ type: string; amount: string }>;
  member_growth: Array<{ month: string; new_members: number; total_members: number }>;
  upcoming_payouts: Array<{
    id: string;
    reference: string | null;
    scheduled_for: string;
    amount: string;
    group: string | null;
    user: string | null;
    description: string;
    status: string;
  }>;
  notifications: Array<{ id: string; title: string; level: "alert" | "warning" | "success" | "info"; message: string; created_at: string }>;
}

export interface AdminUserSummary {
  id: string;
  full_name: string;
  phone_number: string;
  email: string | null;
  kyc_status: string;
  is_active: boolean;
  is_staff: boolean;
  last_login: string | null;
  wallet_balance: string;
  wallet_updated_at: string | null;
  groups_count: number;
  savings_goal_count: number;
  pending_transactions: number;
}

export interface AdminUserDetail extends AdminUserSummary {
  wallet: {
    id: string;
    user: string | null;
    user_name: string | null;
    name: string;
    is_platform: boolean;
    balance: string;
    currency: string;
    updated_at: string;
  } | null;
  savings_goals: Array<{
    id: string;
    title: string;
    category: string;
    target_amount: string;
    current_amount: string;
    progress: number;
    deadline: string;
    created_at: string;
    updated_at: string;
    user: string;
    user_name: string;
  }>;
  recent_transactions: Array<AdminTransaction>;
  groups: Array<AdminGroup>;
}

export interface AdminGroupInvite {
  id: string;
  name: string;
  phone_number: string;
  status: string;
  kyc_completed: boolean;
  sent_at: string;
  responded_at: string | null;
  last_reminded_at: string | null;
}

export interface AdminGroupMember {
  id: string;
  name: string;
  phone_number: string;
  joined_at: string;
}

export interface AdminGroup {
  id: string;
  name: string;
  description: string;
  frequency: string;
  location: string;
  requires_approval: boolean;
  is_public: boolean;
  target_member_count: number;
  contribution_amount: string;
  cycle_number: number;
  total_cycles: number;
  next_payout_date: string;
  created_at: string;
  updated_at: string;
  owner_name: string | null;
  member_count: number;
  pending_invites: number;
  invites: AdminGroupInvite[];
  members: AdminGroupMember[];
}

export interface AdminTransaction {
  id: string;
  user: string;
  user_name: string;
  transaction_type: string;
  status: string;
  amount: string;
  description: string;
  occurred_at: string;
  channel: string;
  reference: string;
  fee: string | null;
  counterparty: string | null;
  balance_after: string | null;
  platform_balance_after: string | null;
  group: string | null;
  group_name: string | null;
  savings_goal: string | null;
  savings_goal_title: string | null;
}

export interface CashflowQueueItem {
  id: string;
  user: string;
  amount: string;
  status: string;
  channel: string;
  risk: string;
  reference: string;
  submitted_at: string;
  checklist: Record<string, string>;
}

export interface CashflowQueuesResponse {
  deposits: CashflowQueueItem[];
  withdrawals: CashflowQueueItem[];
}

export interface PaginatedResponse<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

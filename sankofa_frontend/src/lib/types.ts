/**
 * Core type definitions
 * Mirrors models from sankofa_app
 */

export interface User {
  id: string;
  phoneNumber: string;
  fullName: string;
  email?: string;
  kycStatus: 'pending' | 'verified' | 'rejected';
  walletBalance: number;
  walletUpdatedAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface SusuGroup {
  id: string;
  name: string;
  description?: string;
  cycleStatus: 'draft' | 'onboarding' | 'active' | 'completed' | 'paused';
  contributionAmount: number;
  contributionFrequency: 'daily' | 'weekly' | 'biweekly' | 'monthly';
  totalMembers: number;
  currentCycle?: number;
  nextPayoutDate?: string;
  nextPayoutRecipient?: string;
  totalPool: number;
  heroImage?: string;
  createdAt: string;
  updatedAt: string;
}

export interface SavingsGoal {
  id: string;
  name: string;
  category: string;
  targetAmount: number;
  savedAmount: number;
  targetDate?: string;
  status: 'active' | 'completed' | 'paused';
  createdAt: string;
  updatedAt: string;
}

export interface Transaction {
  id: string;
  type: 'deposit' | 'withdrawal' | 'contribution' | 'payout' | 'transfer';
  amount: number;
  fee?: number;
  status: 'pending' | 'completed' | 'failed' | 'cancelled';
  channel?: string;
  reference?: string;
  description?: string;
  counterparty?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Notification {
  id: string;
  title: string;
  body: string;
  category?: string;
  read: boolean;
  actionUrl?: string;
  createdAt: string;
}

export interface ApiError {
  message: string;
  statusCode?: number;
  details?: Record<string, unknown>;
}

export interface WalletOperationResult {
  transaction: Transaction;
  walletBalance: number;
  walletUpdatedAt: string;
  platformBalance?: number;
}

export interface RegistrationResult {
  phoneNumber: string;
  message?: string;
  user?: User;
}

export interface OtpVerificationResult {
  access: string;
  refresh: string;
  user: User;
}

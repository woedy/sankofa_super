/**
 * Savings Service
 * Handles savings goals operations
 */

import { apiClient } from '../lib/apiClient';
import type { SavingsGoal } from '../lib/types';

class SavingsService {
  private cachedGoals: SavingsGoal[] | null = null;

  /**
   * Get all savings goals for the current user
   */
  async getSavingsGoals(forceRefresh: boolean = false): Promise<SavingsGoal[]> {
    if (!forceRefresh && this.cachedGoals) {
      return this.cachedGoals;
    }

    try {
      const response = await apiClient.get<SavingsGoal[]>('/api/savings/goals/');
      if (Array.isArray(response)) {
        this.cacheGoals(response);
        return response;
      }
    } catch {
      // Fall back to cached data on error
    }

    if (!this.cachedGoals) {
      this.cachedGoals = [];
    }
    return this.cachedGoals;
  }

  /**
   * Get a single savings goal by ID
   */
  async getSavingsGoalById(id: string): Promise<SavingsGoal | null> {
    // Check cache first
    if (this.cachedGoals) {
      const cached = this.cachedGoals.find((g) => g.id === id);
      if (cached) {
        return cached;
      }
    }

    try {
      const response = await apiClient.get<SavingsGoal>(`/api/savings/goals/${id}/`);
      if (response) {
        this.upsertCachedGoal(response);
        return response;
      }
    } catch {
      // Return null on error
    }

    return null;
  }

  /**
   * Create a new savings goal
   */
  async createSavingsGoal(
    name: string,
    targetAmount: number,
    category: string,
    targetDate?: string
  ): Promise<SavingsGoal> {
    const payload: Record<string, unknown> = {
      name,
      target_amount: targetAmount,
      category,
    };
    if (targetDate) {
      payload.target_date = targetDate;
    }

    const response = await apiClient.post<SavingsGoal>('/api/savings/goals/', payload);
    if (response) {
      this.upsertCachedGoal(response);
      return response;
    }

    throw new Error('Unexpected response from server.');
  }

  /**
   * Clear cached goals
   */
  clearCache(): void {
    this.cachedGoals = null;
  }

  /**
   * Cache goals locally
   */
  private cacheGoals(goals: SavingsGoal[]): void {
    this.cachedGoals = goals;
  }

  /**
   * Update or insert a goal in the cache
   */
  private upsertCachedGoal(goal: SavingsGoal): void {
    if (!this.cachedGoals) {
      this.cachedGoals = [goal];
      return;
    }

    const index = this.cachedGoals.findIndex((g) => g.id === goal.id);
    if (index >= 0) {
      this.cachedGoals[index] = goal;
    } else {
      this.cachedGoals.push(goal);
    }
  }
}

export const savingsService = new SavingsService();

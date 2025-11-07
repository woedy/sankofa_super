/**
 * Group Service
 * Mirrors the mobile app's GroupService
 */

import { apiClient } from '../lib/apiClient';
import type { SusuGroup } from '../lib/types';

class GroupService {
  private cachedGroups: SusuGroup[] | null = null;

  /**
   * Get all groups for the current user
   */
  async getGroups(forceRefresh: boolean = false): Promise<SusuGroup[]> {
    if (!forceRefresh && this.cachedGroups) {
      return this.cachedGroups;
    }

    try {
      const response = await apiClient.get<SusuGroup[]>('/api/groups/');
      if (Array.isArray(response)) {
        this.cacheGroups(response);
        return response;
      }
    } catch {
      // Fall back to cached data on error
    }

    if (!this.cachedGroups) {
      this.cachedGroups = [];
    }
    return this.cachedGroups;
  }

  /**
   * Get a single group by ID
   */
  async getGroupById(id: string): Promise<SusuGroup | null> {
    // Check cache first
    if (this.cachedGroups) {
      const cached = this.cachedGroups.find((g) => g.id === id);
      if (cached) {
        return cached;
      }
    }

    try {
      const response = await apiClient.get<SusuGroup>(`/api/groups/${id}/`);
      if (response) {
        this.upsertCachedGroup(response);
        return response;
      }
    } catch {
      // Return null on error
    }

    return null;
  }

  /**
   * Join a public group
   */
  async joinPublicGroup(
    groupId: string,
    introduction?: string,
    autoSave: boolean = false,
    remindersEnabled: boolean = true
  ): Promise<SusuGroup> {
    const payload: Record<string, unknown> = {};
    if (introduction) {
      payload.introduction = introduction;
    }
    if (autoSave) {
      payload.auto_save = autoSave;
    }
    if (!remindersEnabled) {
      payload.reminders_enabled = remindersEnabled;
    }

    const response = await apiClient.post<SusuGroup>(
      `/api/groups/${groupId}/join/`,
      Object.keys(payload).length > 0 ? payload : undefined
    );

    if (response) {
      this.upsertCachedGroup(response);
      return response;
    }

    throw new Error('Unexpected response from server.');
  }

  /**
   * Create a new group
   */
  async createGroup(data: {
    name: string;
    description?: string;
    contributionAmount: number;
    frequency: string;
    startDate: string;
    invites: Array<{ name: string; phoneNumber: string }>;
    requiresApproval?: boolean;
    isPublic?: boolean;
  }): Promise<SusuGroup> {
    const payload: Record<string, unknown> = {
      name: data.name.trim(),
      contribution_amount: data.contributionAmount.toFixed(2),
      frequency: data.frequency,
      start_date: data.startDate,
      target_member_count: data.invites.length + 1,
      invites: data.invites.map(invite => ({
        name: invite.name.trim(),
        phone_number: invite.phoneNumber.trim(),
      })),
      requires_approval: data.requiresApproval ?? true,
      is_public: data.isPublic ?? false,
      payout_order: `Rotating (${data.frequency})`,
    };

    if (data.description && data.description.trim()) {
      payload.description = data.description.trim();
    }

    const response = await apiClient.post<SusuGroup>('/api/groups/', payload);

    if (response) {
      // Prepend to cache
      if (this.cachedGroups) {
        this.cachedGroups.unshift(response);
      } else {
        this.cachedGroups = [response];
      }
      return response;
    }

    throw new Error('Unexpected response from server.');
  }

  /**
   * Clear cached groups
   */
  clearCache(): void {
    this.cachedGroups = null;
  }

  /**
   * Cache groups locally
   */
  private cacheGroups(groups: SusuGroup[]): void {
    this.cachedGroups = groups;
  }

  /**
   * Update or insert a group in the cache
   */
  private upsertCachedGroup(group: SusuGroup): void {
    if (!this.cachedGroups) {
      this.cachedGroups = [group];
      return;
    }

    const index = this.cachedGroups.findIndex((g) => g.id === group.id);
    if (index >= 0) {
      this.cachedGroups[index] = group;
    } else {
      this.cachedGroups.push(group);
    }
  }
}

export const groupService = new GroupService();

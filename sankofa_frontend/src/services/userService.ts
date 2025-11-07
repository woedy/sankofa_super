/**
 * User Service
 * Mirrors the mobile app's UserService
 */

import { apiClient } from '../lib/apiClient';
import { authService } from './authService';
import type { User } from '../lib/types';

class UserService {
  /**
   * Get current user, optionally forcing a refresh from the server
   */
  async getCurrentUser(forceRefresh: boolean = false): Promise<User | null> {
    if (!forceRefresh) {
      const stored = await authService.getStoredUser();
      if (stored) {
        return stored;
      }
    }

    try {
      const response = await apiClient.get<User>('/api/auth/me/');
      if (response) {
        await authService.saveUser(response);
        return response;
      }
    } catch {
      // Return null on error
    }
    return null;
  }

  /**
   * Refresh current user from server
   */
  async refreshCurrentUser(): Promise<User | null> {
    return this.getCurrentUser(true);
  }

  /**
   * Save user to local storage
   */
  async saveUser(user: User): Promise<void> {
    return authService.saveUser(user);
  }

  /**
   * Update KYC status locally
   */
  async updateKycStatus(status: User['kycStatus']): Promise<void> {
    const user = await this.getCurrentUser();
    if (!user) {
      return;
    }
    const updated: User = {
      ...user,
      kycStatus: status,
      updatedAt: new Date().toISOString(),
    };
    await authService.saveUser(updated);
  }

  /**
   * Update wallet balance locally
   */
  async updateWalletBalance(
    newBalance: number,
    walletUpdatedAt?: string,
    userUpdatedAt?: string
  ): Promise<void> {
    const user = await this.getCurrentUser();
    if (!user) {
      return;
    }
    const now = new Date().toISOString();
    const updated: User = {
      ...user,
      walletBalance: newBalance,
      walletUpdatedAt: walletUpdatedAt || now,
      updatedAt: userUpdatedAt || now,
    };
    await authService.saveUser(updated);
  }

  /**
   * Clear session (logout)
   */
  async clearSession(): Promise<void> {
    return authService.clearSession();
  }
}

export const userService = new UserService();

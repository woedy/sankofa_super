/**
 * Notification Service
 * Handles user notifications
 */

import { apiClient } from '../lib/apiClient';
import type { Notification } from '../lib/types';

class NotificationService {
  private cachedNotifications: Notification[] | null = null;

  /**
   * Get all notifications for the current user
   */
  async getNotifications(forceRefresh: boolean = false): Promise<Notification[]> {
    if (!forceRefresh && this.cachedNotifications) {
      return this.cachedNotifications;
    }

    try {
      const response = await apiClient.get<Notification[]>('/api/notifications/');
      if (Array.isArray(response)) {
        this.cacheNotifications(response);
        return response;
      }
    } catch {
      // Fall back to cached data on error
    }

    if (!this.cachedNotifications) {
      this.cachedNotifications = [];
    }
    return this.cachedNotifications;
  }

  /**
   * Mark notification as read
   */
  async markAsRead(id: string): Promise<void> {
    try {
      await apiClient.post(`/api/notifications/${id}/mark-read/`);
      
      // Update cache
      if (this.cachedNotifications) {
        const notification = this.cachedNotifications.find((n) => n.id === id);
        if (notification) {
          notification.read = true;
        }
      }
    } catch {
      // Ignore errors
    }
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(): Promise<void> {
    try {
      await apiClient.post('/api/notifications/mark-all-read/');
      
      // Update cache
      if (this.cachedNotifications) {
        this.cachedNotifications.forEach((n) => {
          n.read = true;
        });
      }
    } catch {
      // Ignore errors
    }
  }

  /**
   * Get unread count
   */
  getUnreadCount(): number {
    if (!this.cachedNotifications) {
      return 0;
    }
    return this.cachedNotifications.filter((n) => !n.read).length;
  }

  /**
   * Clear cached notifications
   */
  clearCache(): void {
    this.cachedNotifications = null;
  }

  /**
   * Cache notifications locally
   */
  private cacheNotifications(notifications: Notification[]): void {
    this.cachedNotifications = notifications;
  }
}

export const notificationService = new NotificationService();

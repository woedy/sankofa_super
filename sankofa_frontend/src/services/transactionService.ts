/**
 * Transaction Service
 * Handles transaction history and operations
 */

import { apiClient } from '../lib/apiClient';
import type { Transaction } from '../lib/types';

class TransactionService {
  private cachedTransactions: Transaction[] | null = null;

  /**
   * Get transaction history
   */
  async getTransactions(forceRefresh: boolean = false): Promise<Transaction[]> {
    if (!forceRefresh && this.cachedTransactions) {
      return this.cachedTransactions;
    }

    try {
      const response = await apiClient.get<Transaction[]>('/api/transactions/');
      if (Array.isArray(response)) {
        this.cacheTransactions(response);
        return response;
      }
    } catch {
      // Fall back to cached data on error
    }

    if (!this.cachedTransactions) {
      this.cachedTransactions = [];
    }
    return this.cachedTransactions;
  }

  /**
   * Get a single transaction by ID
   */
  async getTransactionById(id: string): Promise<Transaction | null> {
    // Check cache first
    if (this.cachedTransactions) {
      const cached = this.cachedTransactions.find((t) => t.id === id);
      if (cached) {
        return cached;
      }
    }

    try {
      const response = await apiClient.get<Transaction>(`/api/transactions/${id}/`);
      if (response) {
        this.recordRemoteTransaction(response);
        return response;
      }
    } catch {
      // Return null on error
    }

    return null;
  }

  /**
   * Record a transaction in the cache
   */
  recordRemoteTransaction(transaction: Transaction): void {
    if (!this.cachedTransactions) {
      this.cachedTransactions = [transaction];
      return;
    }

    const index = this.cachedTransactions.findIndex((t) => t.id === transaction.id);
    if (index >= 0) {
      this.cachedTransactions[index] = transaction;
    } else {
      this.cachedTransactions.unshift(transaction); // Add to beginning
    }
  }

  /**
   * Clear cached transactions
   */
  clearCache(): void {
    this.cachedTransactions = null;
  }

  /**
   * Cache transactions locally
   */
  private cacheTransactions(transactions: Transaction[]): void {
    this.cachedTransactions = transactions;
  }
}

export const transactionService = new TransactionService();

/**
 * Wallet Service
 * Mirrors the mobile app's WalletService for deposits and withdrawals
 */

import { apiClient } from '../lib/apiClient';
import { transactionService } from './transactionService';
import type { WalletOperationResult } from '../lib/types';

class WalletService {
  /**
   * Deposit funds into wallet
   */
  async deposit(
    amount: number,
    channel?: string,
    reference?: string,
    fee?: number,
    description?: string,
    counterparty?: string
  ): Promise<WalletOperationResult> {
    const payload: Record<string, unknown> = {
      amount: amount.toFixed(2),
    };
    if (channel) payload.channel = channel;
    if (reference) payload.reference = reference;
    if (fee !== undefined) payload.fee = fee.toFixed(2);
    if (description) payload.description = description;
    if (counterparty) payload.counterparty = counterparty;

    const response = await apiClient.post<WalletOperationResult>('/api/transactions/deposit/', payload);
    if (!response) {
      throw new Error('Unexpected response when processing deposit');
    }

    transactionService.recordRemoteTransaction(response.transaction);
    return response;
  }

  /**
   * Withdraw funds from wallet
   */
  async withdraw(
    amount: number,
    status: string = 'pending',
    channel?: string,
    reference?: string,
    fee?: number,
    description?: string,
    counterparty?: string,
    destination?: string,
    note?: string
  ): Promise<WalletOperationResult> {
    const payload: Record<string, unknown> = {
      amount: amount.toFixed(2),
      status,
    };
    if (channel) payload.channel = channel;
    if (reference) payload.reference = reference;
    if (fee !== undefined) payload.fee = fee.toFixed(2);
    if (description) payload.description = description;
    if (counterparty) payload.counterparty = counterparty;
    if (destination) payload.destination = destination;
    if (note) payload.note = note;

    const response = await apiClient.post<WalletOperationResult>('/api/transactions/withdraw/', payload);
    if (!response) {
      throw new Error('Unexpected response when processing withdrawal');
    }

    transactionService.recordRemoteTransaction(response.transaction);
    return response;
  }
}

export const walletService = new WalletService();

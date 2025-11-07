/**
 * Authentication Service
 * Mirrors the mobile app's AuthService with localStorage for token/user persistence
 */

import AppConfig from '../lib/config';
import { ApiException } from '../lib/apiException';
import type { User, RegistrationResult, OtpVerificationResult } from '../lib/types';

const ACCESS_TOKEN_KEY = 'auth_access_token';
const REFRESH_TOKEN_KEY = 'auth_refresh_token';
const ACCESS_EXPIRY_KEY = 'auth_access_expiry';
const USER_KEY = 'current_user';

const DEFAULT_TIMEOUT = 20000;

class AuthService {
  /**
   * Register a new user
   */
  async registerUser(phoneNumber: string, fullName: string, email?: string): Promise<RegistrationResult> {
    const url = AppConfig.resolve('/api/auth/register/');
    const body: Record<string, string> = {
      phone_number: this.normalizePhone(phoneNumber),
      full_name: fullName,
    };
    if (email) {
      body.email = email;
    }

    const response = await this.postJson(url, body);

    if (response.status < 200 || response.status >= 300) {
      throw await this.buildException(response);
    }

    const data = await response.json();
    const userJson = data?.user;
    const message = data?.message;
    const normalizedPhone = userJson?.phone_number || this.normalizePhone(phoneNumber);
    const user = userJson ? this.parseUser(userJson) : undefined;

    return {
      phoneNumber: normalizedPhone,
      message,
      user,
    };
  }

  /**
   * Request OTP for login or other purposes
   */
  async requestOtp(phoneNumber: string, purpose: string = 'login'): Promise<void> {
    const url = AppConfig.resolve('/api/auth/otp/request/');
    const response = await this.postJson(url, {
      phone_number: this.normalizePhone(phoneNumber),
      purpose,
    });

    if (response.status < 200 || response.status >= 300) {
      throw await this.buildException(response);
    }
  }

  /**
   * Verify OTP and get tokens
   */
  async verifyOtp(phoneNumber: string, code: string, purpose: string = 'login'): Promise<User> {
    const url = AppConfig.resolve('/api/auth/otp/verify/');
    const response = await this.postJson(url, {
      phone_number: this.normalizePhone(phoneNumber),
      code,
      purpose,
    });

    if (response.status < 200 || response.status >= 300) {
      throw await this.buildException(response);
    }

    const payload = await response.json();
    const access = payload.access;
    const refresh = payload.refresh;
    const userJson = payload.user;

    if (!access || !refresh || !userJson) {
      throw new ApiException('Authentication response was missing required fields.');
    }

    const user = this.parseUser(userJson);
    await this.persistTokens(access, refresh);
    await this.saveUser(user);
    return user;
  }

  /**
   * Get access token, optionally allowing refresh
   */
  async getAccessToken(allowRefresh: boolean = true): Promise<string | null> {
    const token = localStorage.getItem(ACCESS_TOKEN_KEY);
    if (!token) {
      return null;
    }

    if (!allowRefresh) {
      return token;
    }

    const expiryStr = localStorage.getItem(ACCESS_EXPIRY_KEY);
    if (!expiryStr) {
      return token;
    }

    const expiry = new Date(parseInt(expiryStr, 10));
    const now = new Date();
    const bufferTime = 45 * 1000; // 45 seconds

    if (now.getTime() >= expiry.getTime() - bufferTime) {
      const refreshed = await this.refreshAccessToken();
      if (!refreshed) {
        return null;
      }
      return localStorage.getItem(ACCESS_TOKEN_KEY);
    }

    return token;
  }

  /**
   * Refresh access token using refresh token
   */
  async refreshAccessToken(): Promise<boolean> {
    const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
    if (!refreshToken) {
      return false;
    }

    const url = AppConfig.resolve('/api/auth/token/refresh/');
    let response: Response;

    try {
      response = await this.postJson(url, { refresh: refreshToken });
    } catch {
      return false;
    }

    if (response.status >= 200 && response.status < 300) {
      const payload = await response.json();
      const access = payload.access;
      if (!access) {
        return false;
      }
      await this.persistTokens(access, refreshToken);
      return true;
    }

    if (response.status === 401 || response.status === 403) {
      await this.clearSession();
    }
    return false;
  }

  /**
   * Check if user has an active session
   */
  async hasActiveSession(): Promise<boolean> {
    const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
    if (!refreshToken) {
      return false;
    }
    const user = await this.getStoredUser();
    return user !== null;
  }

  /**
   * Get stored user from localStorage
   */
  async getStoredUser(): Promise<User | null> {
    const jsonString = localStorage.getItem(USER_KEY);
    if (!jsonString) {
      return null;
    }
    try {
      return JSON.parse(jsonString) as User;
    } catch {
      return null;
    }
  }

  /**
   * Save user to localStorage
   */
  async saveUser(user: User): Promise<void> {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  }

  /**
   * Clear session (logout)
   */
  async clearSession(): Promise<void> {
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(ACCESS_EXPIRY_KEY);
    localStorage.removeItem(USER_KEY);
  }

  /**
   * Normalize phone number to +233 format
   */
  normalizePhone(input: string): string {
    const digits = input.replace(/\D/g, '');
    if (!digits) {
      return input.trim();
    }
    if (digits.startsWith('233') && digits.length === 12) {
      return `+${digits}`;
    }
    if (digits.startsWith('0') && digits.length === 10) {
      return `+233${digits.substring(1)}`;
    }
    if (digits.length === 9) {
      return `+233${digits}`;
    }
    if (input.trim().startsWith('+')) {
      return input.trim();
    }
    return `+${digits}`;
  }

  /**
   * Persist tokens to localStorage
   */
  private async persistTokens(accessToken: string, refreshToken: string): Promise<void> {
    localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
    localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
    const expiry = this.decodeExpiry(accessToken);
    if (expiry) {
      localStorage.setItem(ACCESS_EXPIRY_KEY, expiry.getTime().toString());
    }
  }

  /**
   * Decode JWT expiry
   */
  private decodeExpiry(token: string): Date | null {
    const parts = token.split('.');
    if (parts.length !== 3) {
      return null;
    }
    try {
      const payload = JSON.parse(atob(parts[1]));
      const exp = payload.exp;
      if (typeof exp === 'number') {
        return new Date(exp * 1000);
      }
      if (typeof exp === 'string') {
        const parsed = parseInt(exp, 10);
        if (!isNaN(parsed)) {
          return new Date(parsed * 1000);
        }
      }
    } catch {
      return null;
    }
    return null;
  }

  /**
   * Parse user from API response
   */
  private parseUser(json: Record<string, unknown>): User {
    return {
      id: String(json.id || ''),
      phoneNumber: String(json.phone_number || json.phoneNumber || ''),
      fullName: String(json.full_name || json.fullName || ''),
      email: json.email ? String(json.email) : undefined,
      kycStatus: (json.kyc_status || json.kycStatus || 'pending') as User['kycStatus'],
      walletBalance: Number(json.wallet_balance || json.walletBalance || 0),
      walletUpdatedAt: String(json.wallet_updated_at || json.walletUpdatedAt || new Date().toISOString()),
      createdAt: String(json.created_at || json.createdAt || new Date().toISOString()),
      updatedAt: String(json.updated_at || json.updatedAt || new Date().toISOString()),
    };
  }

  /**
   * POST JSON helper
   */
  private async postJson(url: string, body: Record<string, unknown>): Promise<Response> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
      clearTimeout(timeoutId);
      return response;
    } catch (error) {
      clearTimeout(timeoutId);
      if (error instanceof Error && error.name === 'AbortError') {
        throw new ApiException('The request timed out. Please check your connection and try again.');
      }
      throw new ApiException('Unable to reach the server. Please check your internet connection.');
    }
  }

  /**
   * Build exception from response
   */
  private async buildException(response: Response): Promise<ApiException> {
    let message = `Request failed with status ${response.status}.`;
    let details: Record<string, unknown> | undefined;

    try {
      const text = await response.text();
      if (text) {
        const decoded = JSON.parse(text);
        if (typeof decoded === 'object' && decoded !== null) {
          details = decoded as Record<string, unknown>;
          const detail = decoded.detail || decoded.message;
          if (typeof detail === 'string' && detail) {
            message = detail;
          } else if (Array.isArray(detail) && detail.length > 0 && typeof detail[0] === 'string') {
            message = detail[0];
          } else {
            for (const value of Object.values(decoded)) {
              if (typeof value === 'string' && value) {
                message = value;
                break;
              }
              if (Array.isArray(value) && value.length > 0 && typeof value[0] === 'string') {
                message = value[0];
                break;
              }
            }
          }
        }
      }
    } catch {
      // Ignore
    }

    return new ApiException(message, response.status, details);
  }
}

export const authService = new AuthService();

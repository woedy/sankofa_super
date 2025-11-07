/**
 * API Client
 * Mirrors the mobile app's ApiClient with automatic token refresh
 */

import AppConfig from './config';
import { ApiException } from './apiException';
import { authService } from '../services/authService';

const DEFAULT_TIMEOUT = 20000; // 20 seconds

class ApiClient {
  private async request<T>(
    method: 'GET' | 'POST',
    path: string,
    options?: {
      body?: unknown;
      queryParams?: Record<string, string | number | boolean>;
      retrying?: boolean;
    }
  ): Promise<T> {
    const url = AppConfig.resolve(path, options?.queryParams);
    const headers: Record<string, string> = {
      'Accept': 'application/json',
    };

    // Get access token without refresh on first attempt
    const accessToken = await authService.getAccessToken(false);
    if (accessToken) {
      headers['Authorization'] = `Bearer ${accessToken}`;
    }

    if (options?.body) {
      headers['Content-Type'] = 'application/json';
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT);

    try {
      const response = await fetch(url, {
        method,
        headers,
        body: options?.body ? JSON.stringify(options.body) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      // Handle 401 with token refresh
      if (response.status === 401) {
        if (!options?.retrying) {
          const refreshed = await authService.refreshAccessToken();
          if (refreshed) {
            return this.request<T>(method, path, { ...options, retrying: true });
          }
        }
        throw new ApiException('Your session has expired. Please sign in again.', 401);
      }

      // Handle non-2xx responses
      if (response.status < 200 || response.status >= 300) {
        throw await this.buildException(response);
      }

      // Handle empty response
      const text = await response.text();
      if (!text) {
        return null as T;
      }

      // Try to parse JSON
      try {
        return JSON.parse(text) as T;
      } catch {
        return text as T;
      }
    } catch (error) {
      clearTimeout(timeoutId);

      if (error instanceof ApiException) {
        throw error;
      }

      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          throw new ApiException('The request timed out. Please check your connection and try again.');
        }
        throw new ApiException('Unable to reach the server. Please check your internet connection.');
      }

      throw new ApiException('An unexpected error occurred.');
    }
  }

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
            // Try to extract first string value from response
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
      // Ignore parse errors
    }

    return new ApiException(message, response.status, details);
  }

  async get<T>(path: string, queryParams?: Record<string, string | number | boolean>): Promise<T> {
    return this.request<T>('GET', path, { queryParams });
  }

  async post<T>(path: string, body?: unknown): Promise<T> {
    return this.request<T>('POST', path, { body });
  }

  async postMultipart<T>(
    path: string,
    fields?: Record<string, string>,
    files?: Array<{ name: string; file: File }>
  ): Promise<T> {
    const url = AppConfig.resolve(path);
    const headers: Record<string, string> = {
      'Accept': 'application/json',
    };

    const accessToken = await authService.getAccessToken(false);
    if (accessToken) {
      headers['Authorization'] = `Bearer ${accessToken}`;
    }

    const formData = new FormData();
    if (fields) {
      Object.entries(fields).forEach(([key, value]) => {
        formData.append(key, value);
      });
    }
    if (files) {
      files.forEach(({ name, file }) => {
        formData.append(name, file);
      });
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: formData,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (response.status === 401) {
        const refreshed = await authService.refreshAccessToken();
        if (refreshed) {
          // Retry once after refresh
          return this.postMultipart<T>(path, fields, files);
        }
        throw new ApiException('Your session has expired. Please sign in again.', 401);
      }

      if (response.status < 200 || response.status >= 300) {
        throw await this.buildException(response);
      }

      const text = await response.text();
      if (!text) {
        return null as T;
      }

      try {
        return JSON.parse(text) as T;
      } catch {
        return text as T;
      }
    } catch (error) {
      clearTimeout(timeoutId);

      if (error instanceof ApiException) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new ApiException('The request timed out. Please check your connection and try again.');
      }

      throw new ApiException('Unable to reach the server. Please try again.');
    }
  }
}

export const apiClient = new ApiClient();

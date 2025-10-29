import { useCallback } from "react";

const DEFAULT_BASE_URL = "http://localhost:8000";

const normalizeBaseUrl = (raw: string): string => {
  if (!raw) {
    return DEFAULT_BASE_URL;
  }

  try {
    const url = new URL(raw);

    if (
      url.hostname === "backend" &&
      typeof window !== "undefined" &&
      ["localhost", "127.0.0.1", "0.0.0.0"].includes(window.location.hostname)
    ) {
      url.hostname = window.location.hostname;

      if (!url.port) {
        url.port = "8000";
      }

      if (window.location.protocol === "https:") {
        url.protocol = "https:";
      } else {
        url.protocol = "http:";
      }
    }

    return url.toString().replace(/\/$/, "");
  } catch {
    return raw;
  }
};

export const API_BASE_URL = normalizeBaseUrl(import.meta.env.VITE_API_BASE_URL ?? DEFAULT_BASE_URL);

export type HttpMethod = "GET" | "POST" | "PATCH" | "DELETE";

export type ApiRequestOptions = RequestInit & { skipAuth?: boolean };

export interface ApiError extends Error {
  status?: number;
  details?: unknown;
}

export const parseError = async (response: Response): Promise<ApiError> => {
  const error = new Error(`Request failed with status ${response.status}`) as ApiError;
  error.status = response.status;
  try {
    const payload = await response.json();
    error.details = payload;
    if (payload?.detail && typeof payload.detail === "string") {
      error.message = payload.detail;
    }
  } catch {
    // ignore
  }
  return error;
};

export const buildUrl = (path: string) => {
  if (path.startsWith("http")) {
    return path;
  }
  const normalized = path.startsWith("/") ? path : `/${path}`;
  return `${API_BASE_URL}${normalized}`;
};

export const withJson = (options: RequestInit = {}): RequestInit => ({
  ...options,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
    ...(options.headers ?? {}),
  },
});

export const safeJson = async <T>(response: Response): Promise<T> => {
  if (response.status === 204) {
    return undefined as T;
  }
  const text = await response.text();
  if (!text) {
    return undefined as T;
  }
  try {
    return JSON.parse(text) as T;
  } catch {
    return text as T;
  }
};

export const useApi = (fetcher: (input: RequestInfo, init?: RequestInit) => Promise<Response>) => {
  return useCallback(
    async <T>(path: string, options: RequestInit = {}) => {
      const response = await fetcher(buildUrl(path), options);
      if (!response.ok) {
        throw await parseError(response);
      }
      return safeJson<T>(response);
    },
    [fetcher],
  );
};

import React, { createContext, useCallback, useContext, useMemo, useState } from "react";

import { buildUrl, useApi, withJson } from "./api";

export interface AdminUser {
  id: string;
  full_name: string;
  phone_number: string;
  email: string | null;
  kyc_status: string;
  is_active: boolean;
  is_staff: boolean;
  last_login: string | null;
  wallet_balance: string;
  wallet_updated_at: string | null;
  groups_count: number;
  savings_goal_count: number;
  pending_transactions: number;
}

interface Tokens {
  access: string;
  refresh: string;
}

interface AuthContextValue {
  user: AdminUser | null;
  isAuthenticated: boolean;
  login: (identifier: string, password: string) => Promise<void>;
  logout: () => void;
  refresh: () => Promise<void>;
  fetchWithAuth: (input: RequestInfo, init?: RequestInit, retry?: boolean) => Promise<Response>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

const STORAGE_KEY = "sankofa_admin_auth";

type StoredAuth = { tokens: Tokens; user: AdminUser };

export class SessionExpiredError extends Error {
  constructor(message = "Session expired") {
    super(message);
    this.name = "SessionExpiredError";
  }
}

const readStoredAuth = (): StoredAuth | null => {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) {
    return null;
  }
  try {
    const parsed = JSON.parse(stored) as StoredAuth;
    if (!parsed.tokens?.access || !parsed.tokens?.refresh || !parsed.user) {
      throw new Error("Invalid stored auth");
    }
    return parsed;
  } catch {
    localStorage.removeItem(STORAGE_KEY);
    return null;
  }
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [rehydratedAuth] = useState<StoredAuth | null>(() => {
    try {
      return readStoredAuth();
    } catch {
      return null;
    }
  });

  const [user, setUser] = useState<AdminUser | null>(rehydratedAuth?.user ?? null);
  const [tokens, setTokens] = useState<Tokens | null>(rehydratedAuth?.tokens ?? null);

  const persist = useCallback((nextTokens: Tokens | null, nextUser: AdminUser | null) => {
    if (nextTokens && nextUser) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ tokens: nextTokens, user: nextUser } satisfies StoredAuth));
    } else {
      localStorage.removeItem(STORAGE_KEY);
    }
  }, []);

  const login = useCallback(async (identifier: string, password: string) => {
    const response = await fetch(buildUrl("/api/admin/auth/token/"), withJson({
      method: "POST",
      body: JSON.stringify({ identifier, password }),
    }));
    if (!response.ok) {
      const errorBody = await response.json().catch(() => ({}));
      const message = errorBody?.detail ?? "Invalid credentials.";
      throw new Error(message);
    }
    const payload = (await response.json()) as { access: string; refresh: string; user: AdminUser };
    setTokens({ access: payload.access, refresh: payload.refresh });
    setUser(payload.user);
    persist({ access: payload.access, refresh: payload.refresh }, payload.user);
  }, [persist]);

  const logout = useCallback(() => {
    setTokens(null);
    setUser(null);
    persist(null, null);
  }, [persist]);

  const refresh = useCallback(async () => {
    if (!tokens?.refresh) {
      throw new SessionExpiredError("Missing refresh token");
    }

    try {
      const response = await fetch(buildUrl("/api/auth/token/refresh/"), withJson({
        method: "POST",
        body: JSON.stringify({ refresh: tokens.refresh }),
      }));

      const body = await response
        .json()
        .catch(() => null as null | { access?: string; detail?: string });

      if (response.status === 401) {
        throw new SessionExpiredError("Your session has expired. Please sign in again.");
      }

      if (!response.ok || !body || typeof body.access !== "string") {
        const detail = body && "detail" in body ? body.detail : undefined;
        throw new Error(detail || "Unable to refresh session");
      }

      const nextTokens = { access: body.access, refresh: tokens.refresh };
      setTokens(nextTokens);
      if (user) {
        persist(nextTokens, user);
      }
    } catch (error) {
      if (error instanceof SessionExpiredError) {
        logout();
        throw error;
      }
      if (error instanceof TypeError) {
        throw new Error("Network error while refreshing session. Please retry.");
      }
      throw error instanceof Error ? error : new Error("Unable to refresh session");
    }
  }, [logout, persist, tokens, user]);

  const fetchWithAuth = useCallback(
    async (input: RequestInfo, init?: RequestInit, retry = true): Promise<Response> => {
      const headers = new Headers(init?.headers);
      headers.set("Accept", "application/json");
      if (init?.body && !(init.body instanceof FormData)) {
        headers.set("Content-Type", "application/json");
      }
      if (tokens?.access) {
        headers.set("Authorization", `Bearer ${tokens.access}`);
      }
      const response = await fetch(input, { ...init, headers });
      if (response.status === 401 && retry) {
        await refresh();
        return fetchWithAuth(input, init, false);
      }
      return response;
    },
    [refresh, tokens?.access],
  );

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated: Boolean(tokens?.access && user),
      login,
      logout,
      refresh,
      fetchWithAuth,
    }),
    [fetchWithAuth, login, logout, refresh, tokens?.access, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextValue => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return context;
};

export const useAuthorizedApi = () => {
  const { fetchWithAuth } = useAuth();
  return useApi(fetchWithAuth);
};

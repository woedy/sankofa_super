/**
 * Application configuration
 * Mirrors the mobile app's AppConfig pattern
 */

type Environment = 'local' | 'staging' | 'production';

class AppConfig {
  private static _env: Environment = (import.meta.env.VITE_SANKOFA_ENV as Environment) || 'local';

  static get environment(): Environment {
    return this._env;
  }

  static get apiBaseUrl(): string {
    const override = import.meta.env.VITE_API_BASE_URL;
    if (override) {
      return this.normalize(override);
    }
    return this.normalize(this.baseUrlForEnvironment());
  }

  private static baseUrlForEnvironment(): string {
    switch (this._env) {
      case 'production':
        return 'https://api.sankofa.africa';
      case 'staging':
        return 'https://staging.api.sankofa.local';
      default:
        return 'http://localhost:8000';
    }
  }

  static resolve(path: string, queryParams?: Record<string, string | number | boolean>): string {
    const base = this.apiBaseUrl;
    const normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    
    let url = `${base}/${normalizedPath}`;
    
    if (queryParams && Object.keys(queryParams).length > 0) {
      const params = new URLSearchParams();
      Object.entries(queryParams).forEach(([key, value]) => {
        params.append(key, String(value));
      });
      url += `?${params.toString()}`;
    }
    
    return url;
  }

  private static normalize(value: string): string {
    let normalized = value.trim();
    if (!normalized.startsWith('http')) {
      normalized = `https://${normalized}`;
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

export default AppConfig;

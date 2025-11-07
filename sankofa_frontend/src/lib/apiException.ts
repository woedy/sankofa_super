/**
 * API Exception class
 * Mirrors the mobile app's ApiException
 */

export class ApiException extends Error {
  statusCode?: number;
  details?: Record<string, unknown>;

  constructor(message: string, statusCode?: number, details?: Record<string, unknown>) {
    super(message);
    this.name = 'ApiException';
    this.statusCode = statusCode;
    this.details = details;
    Object.setPrototypeOf(this, ApiException.prototype);
  }
}

# Sankofa Frontend - Backend Integration

## Overview
The `sankofa_frontend` web application has been successfully connected to the Django backend, mirroring the flows and API integration patterns from `sankofa_app` (Flutter mobile app).

## Architecture

### API Client Infrastructure
- **`src/lib/config.ts`**: Environment-aware configuration (local/staging/production)
- **`src/lib/apiClient.ts`**: HTTP client with automatic token refresh and error handling
- **`src/lib/apiException.ts`**: Custom exception class for API errors
- **`src/lib/types.ts`**: TypeScript interfaces matching backend models

### Services Layer
All services mirror the mobile app's service architecture:

- **`src/services/authService.ts`**: Authentication (register, OTP, token management)
- **`src/services/userService.ts`**: User profile operations
- **`src/services/groupService.ts`**: Susu group operations with local caching
- **`src/services/savingsService.ts`**: Savings goals management
- **`src/services/transactionService.ts`**: Transaction history
- **`src/services/walletService.ts`**: Deposit/withdrawal operations
- **`src/services/notificationService.ts`**: User notifications

### State Management
- **`src/contexts/AuthContext.tsx`**: Global authentication state provider
- **`src/components/ProtectedRoute.tsx`**: Route guard for authenticated pages

## Connected Pages

### Authentication Flow
- **Login (`/auth/login`)**: 
  - Phone number entry → OTP request
  - OTP verification → Token storage
  - Automatic redirect based on KYC status
  
### Protected App Routes
All routes under `/app/*` require authentication:

1. **Home (`/app/home`)**:
   - Displays wallet balance from user context
   - Loads groups, savings goals, transactions, notifications from API
   - Real-time data with loading states

2. **Groups (`/app/groups`)**:
   - Lists all user's susu groups
   - Shows group details (members, contribution, payout schedule)
   - Empty state handling

3. **Transactions (`/app/transactions`)**:
   - Full transaction history with filtering
   - Table view with status indicators
   - Date formatting and channel display

4. **Profile (`/app/profile`)**:
   - User information from auth context
   - Wallet balance and account status
   - Logout functionality

## API Endpoints Used

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/otp/request/` - Request OTP
- `POST /api/auth/otp/verify/` - Verify OTP and get tokens
- `POST /api/auth/token/refresh/` - Refresh access token
- `GET /api/auth/me/` - Get current user

### Groups
- `GET /api/groups/` - List user's groups
- `GET /api/groups/:id/` - Get group details
- `POST /api/groups/:id/join/` - Join a group

### Savings
- `GET /api/savings/goals/` - List savings goals
- `GET /api/savings/goals/:id/` - Get goal details
- `POST /api/savings/goals/` - Create new goal

### Transactions
- `GET /api/transactions/` - List transactions
- `GET /api/transactions/:id/` - Get transaction details
- `POST /api/transactions/deposit/` - Deposit funds
- `POST /api/transactions/withdraw/` - Withdraw funds

### Notifications
- `GET /api/notifications/` - List notifications
- `POST /api/notifications/:id/mark-read/` - Mark as read
- `POST /api/notifications/mark-all-read/` - Mark all as read

## Token Management

### Storage
- Access token: `localStorage.auth_access_token`
- Refresh token: `localStorage.auth_refresh_token`
- Token expiry: `localStorage.auth_access_expiry`
- Current user: `localStorage.current_user`

### Automatic Refresh
- Access tokens are automatically refreshed 45 seconds before expiry
- Failed refresh triggers logout and redirect to login
- All API calls include automatic retry with fresh token on 401

## Environment Configuration

Create `.env` file (see `.env.example`):
```env
VITE_SANKOFA_ENV=local
VITE_API_BASE_URL=http://localhost:8000
```

### Environment Values
- `local`: http://localhost:8000
- `staging`: https://staging.api.sankofa.local
- `production`: https://api.sankofa.africa

## Data Flow Pattern

1. **Page Load** → Service call → API request
2. **API Response** → Service caches data → Component state updates
3. **Subsequent Loads** → Service returns cached data (unless force refresh)
4. **Token Expiry** → Auto-refresh → Retry original request
5. **Auth Failure** → Clear session → Redirect to login

## Error Handling

All API errors are caught and handled gracefully:
- Network errors: User-friendly messages
- 401 Unauthorized: Automatic token refresh or logout
- 4xx/5xx: Display error message from backend
- Timeout: 20-second timeout with retry logic

## Caching Strategy

Services implement in-memory caching:
- **Groups**: Cached until manual refresh
- **Savings Goals**: Cached until manual refresh
- **Transactions**: Cached until manual refresh
- **Notifications**: Cached until manual refresh

Cache is cleared on:
- Explicit service method call
- User logout
- Page refresh

## Testing Locally

1. Start backend:
   ```bash
   cd sankofa_backend
   python manage.py runserver
   ```

2. Start frontend:
   ```bash
   cd sankofa_frontend
   npm run dev
   ```

3. Access: http://localhost:5173

## New Features Implemented

### Group Creation
- **Create Group Page** (`/app/groups/create`):
  - Full group creation form with validation
  - Member invitation system
  - Contribution amount and frequency settings
  - Start date selection
  - Automatic group creator addition

### Savings Goals
- **Create Goal Modal**:
  - Inline goal creation from Savings page
  - Category selection
  - Target amount and date
  - Progress tracking

### Wallet Operations
- **Deposit/Withdrawal Modals**:
  - Accessible from Home page quick actions
  - Mobile money integration
  - Multiple payment channels (MoMo, Card, Bank)
  - Real-time wallet balance updates
  - Transaction history refresh

### Notifications
- **Mark as Read**:
  - Click to mark individual notifications
  - Bulk mark all as read
  - Today vs Earlier sections
  - Real-time unread count

## Next Steps

Pages still using mock data (optional future work):
- **Savings Detail** (`/app/savings/:id`) - View individual goal details
- **Group Detail** (`/app/groups/:id`) - View group members and activity
- **Support** (`/app/support`) - Help center and chat
- **KYC Flow** (`/auth/kyc`) - Identity verification process

## Notes

- All property names follow backend snake_case → camelCase conversion
- Date strings are parsed and formatted for display
- Loading states prevent flash of empty content
- Empty states provide clear user guidance
- UI matches mobile app design patterns
- Modal-based workflows for quick actions
- Automatic data refresh after mutations
- Optimistic UI updates where appropriate

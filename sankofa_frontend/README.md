# Sankofa Frontend

Responsive web application for the Sankofa susu platform, mirroring the mobile app experience.

## Tech Stack

- **React 18** with TypeScript
- **React Router** for navigation
- **TailwindCSS** for styling
- **Lucide React** for icons
- **TanStack Table** for data tables
- **Vite** for build tooling

## Getting Started

### Prerequisites
- Node.js 18+ 
- npm or yarn
- Backend running on `http://localhost:8000`

### Installation

```bash
# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Start development server
npm run dev
```

Access the app at `http://localhost:5173`

### Build for Production

```bash
npm run build
npm run preview
```

## Project Structure

```
src/
├── lib/              # Core utilities
│   ├── config.ts     # Environment configuration
│   ├── apiClient.ts  # HTTP client
│   ├── apiException.ts
│   └── types.ts      # TypeScript interfaces
├── services/         # API service layer
│   ├── authService.ts
│   ├── userService.ts
│   ├── groupService.ts
│   ├── savingsService.ts
│   ├── transactionService.ts
│   ├── walletService.ts
│   └── notificationService.ts
├── contexts/         # React contexts
│   └── AuthContext.tsx
├── components/       # Reusable components
│   ├── ProtectedRoute.tsx
│   ├── PrimaryButton.tsx
│   ├── ThemeToggle.tsx
│   └── AppNav.tsx
├── routes/           # Page components
│   ├── Landing.tsx
│   ├── auth/
│   │   ├── Login.tsx
│   │   └── KycFlow.tsx
│   ├── onboarding/
│   │   └── Onboarding.tsx
│   └── app/
│       ├── AppLayout.tsx
│       ├── Home.tsx
│       ├── Groups.tsx
│       ├── Transactions.tsx
│       ├── Profile.tsx
│       └── ...
├── providers/        # Theme provider
├── assets/          # Static assets
└── App.tsx          # Root component
```

## Features

### Authentication
- Phone number + OTP login
- Automatic token refresh
- Protected routes
- Session persistence

### Dashboard (Home)
- Wallet balance overview
- Active groups summary
- Savings goals progress
- Recent transactions
- Notifications feed

### Groups
- List all susu groups
- View group details
- Member roster
- Contribution schedule
- Payout tracking

### Transactions
- Full transaction history
- Filter by type (deposit, withdrawal, contribution)
- Status tracking
- Channel information

### Profile
- User information
- Account status
- Wallet balance
- Preferences
- Logout

## Environment Variables

```env
# Environment (local, staging, production)
VITE_SANKOFA_ENV=local

# Optional: Override API base URL
VITE_API_BASE_URL=http://localhost:8000
```

## API Integration

All API calls go through the centralized `apiClient` which handles:
- Automatic token injection
- Token refresh on 401
- Error handling
- Request timeouts (20s)

See `BACKEND_INTEGRATION.md` for detailed API documentation.

## Development

### Code Style
- TypeScript strict mode
- Functional components with hooks
- TailwindCSS utility classes
- Responsive design (mobile-first)

### State Management
- React Context for global state (auth)
- Local state for component-specific data
- Service layer for data fetching and caching

### Routing
- React Router v6
- Protected routes with `ProtectedRoute` component
- Automatic redirect to login for unauthenticated users

## Docker

Build and run with Docker:

```bash
docker build -t sankofa-frontend .
docker run -p 80:80 sankofa-frontend
```

The Dockerfile uses multi-stage build:
1. Build stage: Compile TypeScript and bundle assets
2. Production stage: Serve with nginx

## Contributing

1. Follow existing code patterns
2. Use TypeScript types strictly
3. Match mobile app flows and UX
4. Test with backend running locally
5. Ensure responsive design works on mobile

## License

Proprietary - Sankofa Platform

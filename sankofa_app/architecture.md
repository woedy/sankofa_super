# SankoFa Save - Product Architecture

## Overview
Reference guide for the Flutter-based Digital Susu savings app targeting Ghana and West Africa. Summarizes the product experience delivered with static mock data and highlights the end-to-end user journey.

> For the implementation backlog and acceptance criteria, see `AGENTS.md`.

## Design System
- **Colors**: Royal Blue (#1E3A8A), Turquoise (#14B8A6), Cyan (#0891B2), White backgrounds
- **Typography**: Inter font family via Google Fonts
- **Style**: Modern, minimal, elevated fintech aesthetic with generous spacing
- **Components**: Rounded corners (16-24px), soft shadows, smooth transitions, gradient cards

## Data Models (lib/models/)
✅ **UserModel** - id, name, phone, email, photo, kyc status, wallet balance, timestamps
✅ **TransactionModel** - id, userId, amount, type, status, description, date, timestamps
✅ **SusuGroupModel** - id, name, memberIds, memberNames, contribution, cycles, next payout, timestamps
✅ **SavingsGoalModel** - id, userId, title, target/current amounts, deadline, category, timestamps
✅ **SavingsContributionModel** - id, goalId, amount, channel, note, date, timestamps
✅ **NotificationModel** - id, userId, title, message, type, read status, date, timestamps

## Services (lib/services/)
Local storage services with SharedPreferences and realistic mock data:
✅ **UserService** - manages user profile, KYC status, wallet balance
✅ **TransactionService** - handles transaction history with 6+ sample transactions
✅ **GroupService** - manages 3 Susu groups with rotating payout cycles
✅ **SavingsService** - manages 3 personal savings goals with progress tracking plus contribution history and boost recording
✅ **NotificationService** - handles 4+ notifications with read/unread status

## Screens (lib/screens/)
✅ **SplashScreen** - animated logo entry with fade transition (3s delay)
✅ **OnboardingScreen** - 3 swipeable pages with icons and smooth indicators
✅ **LoginScreen** - Ghana phone number (+233) with OTP simulation
✅ **KYCScreen** - Ghana Card upload interface with progress indicator
✅ **MainScreen** - custom bottom navigation with 4 tabs (Home, Groups, Savings, Profile)
✅ **HomeScreen** - gradient wallet card, 4 quick action buttons, recent transactions list
✅ **GroupsScreen** - list of 3 Susu groups with progress bars and contribution details
✅ **GroupDetailScreen** - detailed group view with member list and contribute button
✅ **SavingsScreen** - 3 personal savings goals with progress bars and category icons
✅ **TransactionsScreen** - filterable transaction history (All, Deposit, Withdrawal, etc.)
✅ **NotificationsScreen** - dismissible notification cards with swipe-to-delete
✅ **ProfileScreen** - user profile with settings menu and logout functionality

## Features Implemented
✅ Fully navigable UI with no dead ends
✅ Realistic mock data across all screens
✅ Local storage persistence (SharedPreferences)
✅ Smooth animations and transitions
✅ Refresh indicators on list screens
✅ Filter functionality for transactions
✅ Dismissible notifications
✅ Contribution dialog in group details
✅ Ghana-specific UI elements (flag, currency GH₵)
✅ KYC verification badge
✅ Custom bottom navigation with active state
✅ Gradient cards for wallet and groups
✅ Progress indicators for savings goals and group cycles
✅ Transaction status badges
✅ Category-based icons and colors

## Color Palette
- **Primary Blue**: #1E3A8A (Royal Blue)
- **Secondary Turquoise**: #14B8A6 (Turquoise)
- **Tertiary Cyan**: #0891B2 (Cyan)
- **Error Red**: #DC2626
- **Success Green**: #059669
- **Background**: #FAFAFA
- **Surface**: #FFFFFF
- **Text**: #0F172A

## Sample Data Highlights
- **User**: Kwame Mensah, verified KYC, GH₵2,450 balance
- **Groups**: Unity Savers (5 members), Women Empowerment Circle (4 members), Traders Alliance (6 members)
- **Goals**: Education Fund (64% complete), Business Capital (45%), Emergency Fund (82%)
- **Transactions**: Mix of deposits, withdrawals, contributions, payouts, and savings

## Dependencies
- flutter (SDK)
- google_fonts: ^6.1.0
- shared_preferences: ^2.0.0
- intl: 0.20.2
- smooth_page_indicator: ^1.0.0

## Implementation Status
✅ All 12 screens implemented
✅ All 6 data models created
✅ All 5 services with mock data
✅ Theme customized for fintech aesthetic
✅ Navigation flow complete
✅ Supports full mock journey for usability demos

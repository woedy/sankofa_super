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
✅ **TransactionModel** - id, userId, amount, type, status, description, channel, fees, counterparty, reference, date, timestamps
✅ **SusuGroupModel** - id, name, memberIds, memberNames, invite list, target seats, contribution, cycles, next payout, timestamps
✅ **GroupInviteModel** - id, name, phone, status (pending/accepted/declined), kyc flag, sent/responded dates, reminder counts
✅ **GroupDraftModel** - id, name, purpose, contribution, cadence, start date, staged member names, timestamps
✅ **SavingsGoalModel** - id, userId, title, target/current amounts, deadline, category, timestamps
✅ **SavingsGoalDraftModel** - id, working title, category, target amount, monthly pledge, deadline, auto-debit flag, timestamps
✅ **SavingsContributionModel** - id, goalId, amount, channel, note, date, timestamps
✅ **SavingsContributionOutcome** - helper result for boosts containing the updated goal, contribution entry, and unlocked milestones
✅ **NotificationModel** - id, userId, title, message, type, read status, date, timestamps

## Services (lib/services/)
Local storage services with SharedPreferences and realistic mock data:
✅ **UserService** - manages user profile, KYC status, wallet balance
✅ **TransactionService** - handles transaction history with rich channel metadata, fee breakdowns, and 6+ sample transactions
✅ **GroupService** - manages 3 Susu groups with rotating payout cycles, staged invites with reminder tracking, and saves in-progress private circle drafts
✅ **SavingsService** - manages 3 personal savings goals with progress tracking, mirrors boosts into transactions, surfaces milestone achievements, and stores creation drafts for the goal wizard
✅ **NotificationService** - handles 4+ notifications with read/unread status, milestone badges, mark-all, and an unread count notifier

## Screens (lib/screens/)
✅ **SplashScreen** - animated logo entry with fade transition (3s delay)
✅ **OnboardingScreen** - 3 swipeable pages with icons and smooth indicators
✅ **LoginScreen** - Ghana phone number (+233) with OTP simulation
✅ **KYCScreen** - Ghana Card upload interface with progress indicator
✅ **MainScreen** - custom bottom navigation with 4 tabs (Home, Groups, Savings, Profile)
✅ **HomeScreen** - gradient wallet card, actionable quick actions (deposit launches flow), recent transactions list
✅ **DepositFlowScreen** - three-step wallet top-up (amount → channel → review) with transaction logging and wallet sync
✅ **WithdrawalFlowScreen** - four-step cash-out with compliance checklist, destination selection, and status-aware outcomes that mirror transactions and notifications
✅ **GroupsScreen** - list of Susu groups with search, filters, and quick access to the creation wizard
✅ **GroupCreationWizardScreen** - multi-step private group setup with draft persistence and member staging
✅ **GroupDetailScreen** - detailed group view with member list, invite progress insights, reminder actions, and contribute button
✅ **SavingsScreen** - 3 personal savings goals with progress bars and category icons
✅ **SavingsGoalWizardScreen** - four-step creation wizard with draft restore, timeline planning, auto-debit toggle, and review confirmation
✅ **TransactionsScreen** - multi-select chips for type/status, date range picker, and export snackbar stub
✅ **TransactionDetailModal** - draggable bottom sheet with gradient summary, channel metadata, and compliance timeline
✅ **NotificationsScreen** - segmented Today/Earlier inbox with read dots, swipe dismiss, and mark-all control
✅ **ProfileScreen** - user profile with settings menu and logout functionality

## Features Implemented
✅ Fully navigable UI with no dead ends
✅ Realistic mock data across all screens
✅ Local storage persistence (SharedPreferences)
✅ Smooth animations and transitions
✅ Refresh indicators on list screens
✅ Filter functionality for transactions
✅ Grouped notifications inbox with mark-all-as-read and badge sync
✅ Contribution dialog in group details
✅ Ghana-specific UI elements (flag, currency GH₵)
✅ KYC verification badge
✅ Custom bottom navigation with active state
✅ Gradient cards for wallet and groups
✅ Progress indicators for savings goals and group cycles
✅ Transaction status badges, slide-up detail modal, automatic wallet sync for savings boosts, and live deposit flow receipts
✅ Withdrawal flow prototype with compliance gating, manual review simulation, and wallet + notification syncing
✅ Savings goal creation wizard with multi-step guidance, draft persistence, and confirmation review
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
- **Groups**: Unity Savers (5 members), Women Empowerment Circle (4 members + 2 invites), Traders Alliance (6 members + 2 invites)
- **Goals**: Education Fund (64% complete), Business Capital (45%), Emergency Fund (82%)
- **Transactions**: Mix of deposits, withdrawals, contributions, payouts, and savings

## Dependencies
- flutter (SDK)
- google_fonts: ^6.1.0
- shared_preferences: ^2.0.0
- intl: 0.20.2
- smooth_page_indicator: ^1.0.0

## Implementation Status
✅ All 13 screens implemented
✅ All 9 data models created
✅ All 5 services with mock data
✅ Theme customized for fintech aesthetic
✅ Navigation flow complete
✅ Supports full mock journey for usability demos

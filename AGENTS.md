# SankoFa Product Improvement Blueprint

This document governs all work inside the `sankofa_super` repository. Follow these guardrails when updating the Flutter app (`sankofa_app`) and the React admin console (`sankofa_admin`).

## Cross-Product Guiding Principles
- **StaticDataOnly**: Ship polished, static experiences backed by the existing mock data services (Flutter) or seed JSON (React). Do not introduce live backends.
- **UserStoryDriven**: Every slice of work must be framed as a user story with explicit acceptance criteria and a manual QA checklist.
- **ConsistentFlows**: Align navigation, list/detail parity, and terminology between the mobile app and admin console. Admin experiences should expose the same entities and states surfaced in the app.
- **ReusableUI**: Prefer shared components and theme primitives (`lib/theme.dart`, shadcn/ui tokens) to keep light/dark parity and responsive layouts consistent.
- **ProductFocusedCopy**: Write UX copy that supports real operators and members, not investor demos.

### Priority Legend
- **[P0]** Immediate slice in progress or next in queue.
- **[P1]** Important follow-up once P0 slices stabilize.
- **[P2]** Nice-to-have or dependent on earlier work.

## Execution Strategy
- **[P0 Alignment Slice]** Catalogue feature parity requirements between app and admin. Mirror key data entities, states, and workflows.
- **[P0 Admin Dashboard Slice]** Enrich the admin KPIs, tables, and notifications using the detailed mock data defined in the app services.
- **[P1 Member Lifecycle Slice]** Build admin controls that reflect onboarding, KYC, savings, and dispute journeys as described in the app blueprint.
- **[P1 Insights & Reporting Slice]** Translate app analytics into admin dashboards, ensuring filters and charts respect light/dark themes.
- **[P2 Support & Settings Slice]** Expand support tools, configuration panels, and localization readiness once higher priorities are stable.

## Shared Task Backlog (One True Source)

### 1. Foundation & Design System
- [x] **[P0] 1.1 AuditThemeTokens**
  - [x] Catalogue colors, typography, elevations, and spacing in `lib/theme.dart` (app) and `tailwind.config.ts`/`theme.css` (admin).
  - [x] Document theme tokens in `AGENTS.md` for reference by UI tasks.
- [x] **[P0] 1.2 CreateComponentLibrary**
  - [x] Define reusable widgets/components under `lib/ui/` (app) and `components/` (admin).
  - [x] Replace at least five ad-hoc implementations across screens with shared components.
- [x] **[P0] 1.3 EstablishNavigationSchema**
  - [x] Map splash → onboarding → auth → main tabs navigation within `AGENTS.md`.
  - [x] Standardize transitions across screens using consistent routing patterns.
  - _Audit 2025-10-21_: Introduced `RouteTransitions` helper for shared fade/slide animations across splash, onboarding, login, and KYC flows.

#### Navigation Schema (`1.3 EstablishNavigationSchema`)
- **SplashScreen**
  - Entry: app launch, checks cached auth state via `UserService` mock.
  - Exit (authenticated): push replacement to `MainScreen` with preserved tab index.
  - Exit (unauthenticated): animate fade → `OnboardingScreen`.
- **OnboardingScreen**
  - Structure: paged view with "Next", "Skip" (top right), and completion CTA.
  - Exit (Skip/Complete): navigate to `LoginScreen` using slide-up transition, record completion in `OnboardingService` mock.
- **LoginScreen**
  - Flow: phone number input → OTP verification (stub), handles error toast.
  - Success: push replacement to `KYCScreen` when profile incomplete; otherwise go straight to `MainScreen`.
  - Failure: stay on screen, surface inline error.
- **KYCScreen**
  - Steps: upload → review → confirm, relies on `ThemeController` for theming.
  - Completion: push replacement to `MainScreen` and flag `UserService` profile as verified.
- **MainScreen**
  - Tabs: Home, Groups, Savings, Transactions, Profile.
  - Navigation: retains tab history stack, bottom bar tap triggers haptic (`HapticFeedback.lightImpact`).
  - Notifications: badges pull from `NotificationService` unread count.
  - Deep links: `Navigator.push` to detail screens (GroupDetail, SavingsGoalDetail, TransactionDetail) maintaining parent tab state.

#### Component Library Blueprint (App)
- **WalletSummaryCard** (`home_screen.dart`): Displays balance, KYC status pill, optional actions. Props: `balance`, `kycStatus`, `onPrimaryAction`. Responsive: switch to horizontal layout with right-aligned actions when width ≥600.
- **GradientIconBadge** (Groups/Savings hero icons): Props: `icon`, `gradientColors`, `diameter`. Responsive: scale diameter based on `MediaQuery.size.width` buckets (56→64→72).
- **InfoCard** + **InfoRow** (`transaction_detail_modal.dart`, `savings_goal_detail_screen.dart`): Props: `title`, `children`, `labelWidth`. Responsive: allow label width to shrink and fall back to column layout below 360px.
- **EntityListTile** (Groups/Savings/Transactions cards): Props: `leading`, `title`, `subtitle`, `meta`, `statusChip`, `onTap`. Responsive: use `Wrap` for meta/status chips and adjust padding from 20→16 on compact devices.
- **ProgressSummaryBar** (Savings progress, group cycles): Props: `progress`, `label`, `secondaryLabel`, `color`. Responsive: animate width, display labels stacked on narrow viewports.
- **NotificationCard** standardizing `_getNotificationColor` usage with props: `icon`, `title`, `message`, `timestamp`, `isRead`, `accent`. Responsive: ensure timestamp wraps under message for narrow widths.
- **ActionChipRow** (home quick actions, filters): Props: `items`, `onSelected`, `multiSelect`. Responsive: convert to horizontally scrollable `SingleChildScrollView` when wider than screen.
- **SectionHeader** (list headers): Props: `title`, `actionLabel`, `onAction`. Responsive: align action below title on compact screens.
- **ModalScaffold** helper for bottom sheets/dialogs to unify padding, handle safe areas, and provide max-width of 560 on tablets/desktop.

#### Component Library Blueprint (Admin)
- **KpiCard** (`components/dashboard/kpi-card.tsx`): Props: `title`, `value`, `trend`, `trendLabel`, `icon`. Support compact stacking under 768px.
- **DataTableShell** (`components/data-table/`): Encapsulate TanStack table setup with built-in search, filters, and density toggle.
- **EntityBadge**: Shared status chips (Active, Pending KYC, Overdue) mirroring app vocabulary.
- **ModalDrawer**: Dual-mode component providing slide-out details on desktop and full-screen dialogs on mobile.
- **AnalyticsChart**: Wrapper around Recharts with theme-aware color tokens.

### Theme Token Catalogue
- **App Colors (Light)** `lib/theme.dart:LightModeColors`
  - Primary `#1E3A8A`, OnPrimary `#FFFFFF`, PrimaryContainer `#DEE9FF`, OnPrimaryContainer `#001B3E`
  - Secondary `#14B8A6`, OnSecondary `#FFFFFF`
  - Tertiary `#0891B2`, OnTertiary `#FFFFFF`
  - Error `#DC2626`, OnError `#FFFFFF`, ErrorContainer `#FFDAD6`, OnErrorContainer `#410002`
  - Background `#F2F5FB`, Surface `#FAFAFA`, OnSurface `#0F172A`, SurfaceVariant `#E6ECF7`, Outline `#CBD5F5`
  - AppBarBackground `#FFFFFF`, InversePrimary `#93C5FD`, Shadow `#000000`
- **App Colors (Dark)** `lib/theme.dart:DarkModeColors`
  - Primary `#9DB2FF`, OnPrimary `#0B1D55`, PrimaryContainer `#12245C`, OnPrimaryContainer `#DBE2FF`
  - Secondary `#5EEAD4`, OnSecondary `#00382F`
  - Tertiary `#38BDF8`, OnTertiary `#002B42`
  - Error `#FFB4AB`, OnError `#690005`, ErrorContainer `#93000A`, OnErrorContainer `#FFDAD6`
  - Background `#0B1121`, Surface `#101426`, OnSurface `#E5EDFF`, SurfaceVariant `#1E283E`, Outline `#27324A`
  - AppBarBackground `#141B2F`, InversePrimary `#445DAF`, Shadow `#000000`
- **Admin Tokens** `src/styles/theme.css`
  - Neutral `#0F172A` ↔ `#E5EDFF`, Primary `#1E3A8A` ↔ `#9DB2FF`, Accent `#14B8A6`, Warning `#F97316`, Success `#22C55E`.
  - Respect CSS variables `--background`, `--foreground`, `--card`, `--popover`, `--border`, `--input`, `--ring` for dark/light support.

### 2. Core Member Journey (App)
- [x] **[P1] 2.1 SplashOnboardingRevamp**
  - [x] Update `SplashScreen` and `OnboardingScreen` copy for story-driven messaging.
  - [x] Ensure skip controls function and analytics completion event is stubbed.
  - _Audit 2025-10-21_: Splash now narrates the product promise, onboarding pages highlight Susu stories, and analytics/onboarding services capture skip/complete events.
- [x] **[P1] 2.2 PhoneAuthFlow**
  - [x] Add formatted inputs, error states, and OTP timer simulation to `LoginScreen`.
  - [x] Verify success routes to `KYCScreen` and failure path messaging is documented.
  - _Audit 2025-10-21_: `login_screen.dart` now formats Ghana numbers, surfaces inline validation, simulates OTP countdown/resend, and routes to `KYCScreen` vs `MainScreen` based on `UserService` state with analytics logs.
- [x] **[P1] 2.3 KYCTaskFlow**
  - [x] Implement guided upload → review → confirm steps in `KYCScreen`.
  - [x] Persist KYC state via `UserService` mock data.

### 3. Member Success (App)
- [x] **[P0] 3.1 BottomNavConsistency**
  - [x] Add haptic feedback, badges, and state preservation to `MainScreen` tabs.
  - [x] Ensure tab switches retain scroll position and unread badge reflects `NotificationService` data.
  - _Audit 2025-10-20_: Upgraded `main_screen.dart` with `IndexedStack`, haptic taps, and notification badge bootstrapped from `NotificationService`. Follow-up: consider live refresh when notifications change.
- [x] **[P0] 3.2 HomeOverviewCard**
  - [x] Refactor wallet card in `home_screen.dart` to consume `UserService` data.
  - [x] Verify quick actions navigate to their target screens.
  - _Audit 2025-10-21_: Wallet summary now showcases KYC status styling, MoMo & activity highlights, and uses `RouteTransitions` for quick-action flows.
- [x] **[P1] 3.3 ProcessFlowsIntegration**
  - [x] Surface `process_flows.dart` entries in a dedicated home section.
  - [x] Launch `ProcessFlowScreen` with step tracking when a flow is selected.
  - _Audit 2025-10-21_: `home_screen.dart` introduces a Process Demos rail using `EntityListTile`, meta chips, and routes into `ProcessFlowScreen` with static analytics-friendly copy.

### 4. Admin Enablement (New)
- [ ] **[P0] 4.1 DataParityAudit**
  - [ ] Document the canonical member, group, savings, transaction, notification, and dispute models from the app services.
  - [ ] Create a mapping table for how each field should appear within `sankofa_admin` tables, detail panes, and charts.
- [ ] **[P0] 4.2 AdminSeedEnrichment**
  - [ ] Port realistic mock records (≥10 users, ≥6 groups, ≥20 transactions, ≥5 disputes) to admin JSON/TS seeds while honoring status diversity.
  - [ ] Ensure totals and KPIs reconcile with the same datasets used in the app (wallet balances, contribution progress, payouts).
- [ ] **[P0] 4.3 DashboardRefresh**
  - [ ] Expand KPI cards, charts, and recent activity panels to visualize the enriched seed data.
  - [ ] Validate dark mode color contrast and responsive layouts at 375px, 768px, and 1280px widths.
- [ ] **[P1] 4.4 MemberOperationsSuite**
  - [ ] Implement searchable/filterable member management table mirroring KYC, savings goals, and wallet status from the app.
  - [ ] Provide detail drawer actions for approving KYC, triggering deposits/withdrawals, and viewing transaction history snapshots.
- [ ] **[P1] 4.5 GroupLifecycleTools**
  - [ ] Introduce group pipeline views (public/private, cycle status, invite health) referencing app invite tracking metadata.
  - [ ] Add modals for manual cycle adjustments, payout scheduling, and reminder triggers.
- [ ] **[P1] 4.6 CashflowOps**
  - [ ] Surface deposit/withdrawal queues with compliance checklists mirroring app flows.
  - [ ] Include rejection reasons, fee breakdowns, and export stubs for audit logs.
- [ ] **[P2] 4.7 Support & Dispute Desk**
  - [ ] Build dispute triage with severity filters, SLA timers, and escalation actions.
  - [ ] Add support knowledge base linkage, matching the app's FAQ taxonomy.
- [ ] **[P2] 4.8 ConfigurationCenter**
  - [ ] Expand settings for transaction fees, notification templates, and localization toggles.
  - [ ] Persist selections to mock storage and display success toasts in both themes.

### 5. Savings & Groups (App)
- [x] **[P1] 5.1 SavingsListRefine**
  - [x] Enhance `SavingsScreen` cards with category, progress, and target date metadata.
  - [x] Support sorting by progress and deadline with milestone microcopy.
- [x] **[P1] 5.2 SavingsDetailFlow**
  - [x] Build goal detail page with contribution log and "Boost Savings" form.
  - [x] Validate minimum amounts and update progress using mock data instantly.
- [x] **[P2] 5.3 GoalCreationWizard**
  - [x] Implement multi-step goal creation form with draft persistence.
  - [x] Provide review step before final confirmation.
  - _Audit 2025-10-22_: Savings wizard now walks through basics → target → plan → review, saves drafts to SharedPreferences, and creates live goals with celebratory snackbars across Home and Savings.
- [x] **[P1] 5.4 SavingsContributionSync**
  - [x] Mirror boost activity into `TransactionService` so wallet history reflects personal goal top-ups.
  - [x] Generate celebratory receipts/badges for major milestones (25%, 50%, 75%) and expose them to the Notifications inbox.

### 6. Transactions & Notifications (App)
- [x] **[P1] 6.1 TransactionsListFilters**
  - [x] Add pill filters, date range picker, and export stub to `TransactionsScreen`.
  - [x] Ensure filtering updates list instantly and displays guidance for empty results.
  - _Audit 2025-10-22_: Transactions history now supports multi-select type/status chips, a date range picker, export snackbar stub, and contextual empty states.
- [x] **[P1] 6.2 TransactionDetailModal**
  - [x] Build slide-up modal with source, fees, and status metadata.
  - [x] Enable access from both `TransactionsScreen` list and home recent transactions.
  - _Audit 2025-10-22_: Slide-up modal now uses `ModalScaffold` with a draggable sheet, timeline audit trail, and is launched from both the Transactions feed and Home recent list.
- [x] **[P1] 6.3 NotificationsInbox**
  - [x] Group notifications into Today/Earlier sections with read indicators.
  - [x] Provide bulk mark-all-as-read action and sync badge state.
  - _Audit 2025-10-22_: Inbox now segments Today vs Earlier with badge dots, includes mark-all control tied to `NotificationService` unread notifier, and keeps navigation badge counts in sync.

### 7. Profile & Settings (App)
- [x] **[P2] 7.1 ProfileHub**
  - [x] Reorganize `ProfileScreen` into Personal info, Security, and Preferences sections.
  - [x] Ensure theme toggle leverages `ThemeController` and edits show confirmation snackbars.
  - _Audit 2025-10-22_: Profile hub now features a gradient hero with quick actions, InfoCard sections for personal, security, and preference controls, snackbars on toggles (including theme), language selector, and an elevated logout call-to-action.
- [x] **[P2] 7.2 SupportCenter**
  - [x] Add static Help & FAQ list backed by JSON mock data.
  - [x] Implement detail view with localization-ready content.
  - _Audit 2025-10-22_: Support center now loads localized JSON articles, adds category chips/search, and routes to detailed guidance with follow-up contact messaging.

### QA Checkpoints
- **[P0 Alignment Slice]** Validate admin entities and KPIs against app mock data. Log discrepancies before updating UI.
- **[P0 Dashboard Slice]** Smoke-test home/dashboard screens in both products, confirming responsive layouts and theme parity.
- **[P1 Member Lifecycle Slice]** Walk through onboarding/KYC flows in-app and ensure admin tooling can observe and act on each state.
- **[P2 Support Slice]** Review profile/help localization prep once content updates land.

### 10. Wallet & Cashflow Journeys (App)
- [x] **[P1] 10.1 DepositFlowPrototype**
  - [x] Build an interactive deposit flow (amount entry → channel selection → confirmation) that updates wallet balance and logs a transaction locally.
  - [x] Include a review step outlining fees and reference IDs to mirror regulatory requirements.
  - _Audit 2025-10-22_: Home quick action launches a three-step DepositFlowScreen that validates amount, captures MoMo channel, persists wallet updates, mirrors the transaction (with channel, fee, reference metadata), and drops a receipt notification.
- [x] **[P1] 10.2 WithdrawalFlowPrototype**
  - [x] Implement a withdrawal request experience with compliance checklist, status feedback, and mock failure scenarios.
  - [x] Sync withdrawal outcomes to the Transactions list and trigger notification badges.
  - _Audit 2025-10-22_: Withdrawal flow now walks users through amount, compliance, destination, and review steps, logs status-aware transactions, updates wallet balances on success, and raises wallet notifications for success, pending, and failure demos.
- [x] **[P2] 10.3 CashflowReceipts**
  - [x] Provide shareable receipt modals/PDF stubs for deposits and withdrawals accessible from detail views.
  - [x] Allow users to export recent cashflow activity for offline records (CSV or PDF stub).
  - _Audit 2025-10-22_: Transaction detail modals now launch a dedicated receipt preview with copy/share stubs, deposit and withdrawal flows surface "View receipt" CTAs on completion, and the Transactions export sheet copies CSV summaries with PDF email placeholders.

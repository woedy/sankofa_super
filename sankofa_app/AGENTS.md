# SankoFa Save Improvement Blueprint

## Guiding Principles
- **StaticDataOnly**: Deliver rich product previews using in-app mock services (`lib/services/`) without introducing live backends.
- **UserStoryDriven**: Organize every enhancement around explicit user stories with clear acceptance criteria traceable back to this document.
- **ConsistentFlows**: Ensure list pages, detail views, and forms follow predictable navigation patterns defined here.
- **ReusableUI**: Favor shared components and styling derived from `lib/theme.dart` and `ThemeController` to minimize duplication.
- **ProductFocusedCopy**: Prioritize messaging and UX decisions that speak directly to end-users rather than investor demos.

### Priority Legend
- **[P0]** Immediate slice in progress or next in queue.
- **[P1]** Important follow-up once P0 slices stabilize.
- **[P2]** Nice-to-have or dependent on earlier work.

### Execution Strategy
- **[P0 Navigation Slice]** Document app flow, align routing in `MainScreen`, smoke-test tab handoff.
- **[P0 Dashboard Slice]** Polish home overview cards, verify quick actions, capture before/after.
- **[P1 Onboarding Slice]** Iterate splash/onboarding copy, run full entry flow.
- **[P1 Savings & Groups Slice]** Enhance list/detail parity, validate member and goal visuals.
- **[P2 Support Slice]** Tackle profile, help center, and localization prep when higher priorities complete.

## Task Backlog (One True Source)

### 1. Foundation & Design System
- [x] **[P0] 1.1 AuditThemeTokens**
  - [x] Catalogue colors, typography, elevations, and spacing in `lightTheme`/`darkTheme`.
  - [x] Document theme tokens in `AGENTS.md` for reference by UI tasks.
- [x] **[P0] 1.2 CreateComponentLibrary**
  - [x] Define reusable widgets (cards, headers, list tiles, progress bars) under `lib/ui/`.
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
- **Component Library Blueprint**
  - **WalletSummaryCard** (`home_screen.dart`): Displays balance, KYC status pill, optional actions. Props: `balance`, `kycStatus`, `onPrimaryAction`. Responsive: switch to horizontal layout with right-aligned actions when width ≥600.
  - **GradientIconBadge** (Groups/Savings hero icons): Props: `icon`, `gradientColors`, `diameter`. Responsive: scale diameter based on `MediaQuery.size.width` buckets (56→64→72).
  - **InfoCard** + **InfoRow** (`transaction_detail_screen.dart`, `savings_goal_detail_screen.dart`): Props: `title`, `children`, `labelWidth`. Responsive: allow label width to shrink and fall back to column layout below 360px.
  - **EntityListTile** (Groups/Savings/Transactions cards): Props: `leading`, `title`, `subtitle`, `meta`, `statusChip`, `onTap`. Responsive: use `Wrap` for meta/status chips and adjust padding from 20→16 on compact devices.
  - **ProgressSummaryBar** (Savings progress, group cycles): Props: `progress`, `label`, `secondaryLabel`, `color`. Responsive: animate width, display labels stacked on narrow viewports.
  - **NotificationCard** standardizing `_getNotificationColor` usage with props: `icon`, `title`, `message`, `timestamp`, `isRead`, `accent`. Responsive: ensure timestamp wraps under message for narrow widths.
  - **ActionChipRow** (home quick actions, filters): Props: `items`, `onSelected`, `multiSelect`. Responsive: convert to horizontally scrollable `SingleChildScrollView` when wider than screen.
  - **SectionHeader** (list headers): Props: `title`, `actionLabel`, `onAction`. Responsive: align action below title on compact screens.
  - **ModalScaffold** helper for bottom sheets/dialogs to unify padding, handle safe areas, and provide max-width of 560 on tablets/desktop.
- **Implementation Plan**
  - Create `lib/ui/components/` with files matching component names plus `ui.dart` barrel export.
  - Introduce `ResponsiveBreakpoints` helper (`small <360`, `medium 360–599`, `large ≥600`) to drive layout decisions.
  - Refactor `home_screen.dart`, `groups_screen.dart`, `savings_screen.dart`, `transactions_screen.dart`, `notifications_screen.dart`, and detail screens to consume the new widgets incrementally (target ≥5 replacements for acceptance).
  - Provide story-like demo in a `components_demo_screen.dart` (optional) for visual QA across breakpoints.
#### Theme Token Catalogue
- **Colors (Light)** `lib/theme.dart:LightModeColors`
  - Primary `#1E3A8A`, OnPrimary `#FFFFFF`, PrimaryContainer `#DEE9FF`, OnPrimaryContainer `#001B3E`
  - Secondary `#14B8A6`, OnSecondary `#FFFFFF`
  - Tertiary `#0891B2`, OnTertiary `#FFFFFF`
  - Error `#DC2626`, OnError `#FFFFFF`, ErrorContainer `#FFDAD6`, OnErrorContainer `#410002`
  - Background `#F2F5FB`, Surface `#FAFAFA`, OnSurface `#0F172A`, SurfaceVariant `#E6ECF7`, Outline `#CBD5F5`
  - AppBarBackground `#FFFFFF`, InversePrimary `#93C5FD`, Shadow `#000000`
- **Colors (Dark)** `lib/theme.dart:DarkModeColors`
  - Primary `#9DB2FF`, OnPrimary `#0B1D55`, PrimaryContainer `#12245C`, OnPrimaryContainer `#DBE2FF`
  - Secondary `#5EEAD4`, OnSecondary `#00382F`
  - Tertiary `#38BDF8`, OnTertiary `#002B42`
  - Error `#FFB4AB`, OnError `#690005`, ErrorContainer `#93000A`, OnErrorContainer `#FFDAD6`
  - Background `#0B1121`, Surface `#101426`, OnSurface `#E5EDFF`, SurfaceVariant `#1E283E`, Outline `#27324A`
  - AppBarBackground `#141B2F`, InversePrimary `#445DAF`, Shadow `#000000`
- **Typography** `lib/theme.dart:FontSizes`
  - Base family: `Inter` via `GoogleFonts.inter`
  - Sizes (pt): Display `57/45/36`, Headline `32/24/22`, Title `22/18/16`, Body `16/14/12`, Label `16/14/12`
  - Default weights: display/title/body mostly normal–medium, label/title medium, headline small bold
- **Elevation & Shape**
  - Card radius set to `20` across light/dark `cardTheme`
  - Card elevation `0` by default; rely on contextual `BoxShadow` for depth (e.g., `MainScreen` tabs)
  - SnackBars use primary palette with white typography for contrast
- **Spacing Patterns**
  - No centralized spacing constants yet; recurring paddings include `EdgeInsets.symmetric(horizontal: 20)`, `EdgeInsets.all(24)`
  - Common vertical gaps: `8`, `12`, `16`, `20`, `24`, `32` seen in `home_screen.dart` and peers
  - Recommend codifying these values when tackling `CreateComponentLibrary`

### 2. Core User Journey
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

### 3. Main Navigation & Dashboard
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

### 4. Susu Groups Experience
- [x] **[P1] 4.1 GroupsListEnhancement**
  - [x] Implement search-by-name and payout-cycle filters in `GroupsScreen`.
  - [x] Design empty states and contribution status chips.
  - _Audit 2025-10-21_: `groups_screen.dart` now features guided search, cycle filter chips, status pills, and an empty-state CTA linking to process demos for creating private circles.
- **Public group discovery**: `GroupsScreen` surfaces open/public groups with rich metadata and routes into `ProcessFlowScreen` using `ProcessFlows.joinGroup` for education.
- **Private group creation**: Quick actions and FAB offer a "Create Private Group" path powered by `ProcessFlows.createGroup`, framing the invite-only setup steps without live backend wiring.
- [x] **[P1] 4.2 GroupDetailBlueprint**
  - [x] Add timeline, member roster, and contribution history to `GroupDetailScreen`.
  - [x] Build contribute modal with amount validation and mock state updates.
- [x] **[P1] 4.3 ContributionReceiptUI**
  - [x] Create confirmation screen summarizing contribution details and next steps.
  - [x] Reference transaction IDs from `TransactionService` and include share option.
- [ ] **[P1] 4.4 PrivateGroupCreationWizard**
  - [ ] Replace the process-flow demo with a guided, multi-step creation form (blueprint → rules → invites) surfaced from the Groups FAB and Home quick action.
  - [ ] Persist draft groups to `GroupService`, including staged members, before final confirmation updates the main list.
- [ ] **[P2] 4.5 GroupInviteTracking**
  - [ ] Add invite-status chips and reminder actions that reflect each prospective member's KYC and acceptance progress.
  - [ ] Surface admin-focused insights (pending slots, cycle start blockers) so backend models capture the necessary state.

- [x] **[P1] 5.1 SavingsListRefine**
  - [x] Enhance `SavingsScreen` cards with category, progress, and target date metadata.
  - [x] Support sorting by progress and deadline with milestone microcopy.
- [x] **[P1] 5.2 SavingsDetailFlow**
  - [x] Build goal detail page with contribution log and "Boost Savings" form.
  - [x] Validate minimum amounts and update progress using mock data instantly.
- [ ] **[P2] 5.3 GoalCreationWizard**
  - [ ] Implement multi-step goal creation form with draft persistence.
  - [ ] Provide review step before final confirmation.
- [ ] **[P1] 5.4 SavingsContributionSync**
  - [ ] Mirror boost activity into `TransactionService` so wallet history reflects personal goal top-ups.
  - [ ] Generate celebratory receipts/badges for major milestones (25%, 50%, 75%) and expose them to the Notifications inbox.

### 6. Transactions & Notifications
- [ ] **[P1] 6.1 TransactionsListFilters**
  - [ ] Add pill filters, date range picker, and export stub to `TransactionsScreen`.
  - [ ] Ensure filtering updates list instantly and displays guidance for empty results.
- [ ] **[P1] 6.2 TransactionDetailModal**
  - [ ] Build slide-up modal with source, fees, and status metadata.
  - [ ] Enable access from both `TransactionsScreen` list and home recent transactions.
- [ ] **[P1] 6.3 NotificationsInbox**
  - [ ] Group notifications into Today/Earlier sections with read indicators.
  - [ ] Provide bulk mark-all-as-read action and sync badge state.

### 7. Profile & Settings
- [ ] **[P2] 7.1 ProfileHub**
  - [ ] Reorganize `ProfileScreen` into Personal info, Security, and Preferences sections.
  - [ ] Ensure theme toggle leverages `ThemeController` and edits show confirmation snackbars.
- [ ] **[P2] 7.2 SupportCenter**
  - [ ] Add static Help & FAQ list backed by JSON mock data.
  - [ ] Implement detail view with localization-ready content.

### 8. Data & Content Management
- [ ] **[P2] 8.1 MockDataExpansion**
  - [ ] Expand `lib/services/` datasets with realistic personas, groups, and narratives.
  - [ ] Ensure each screen consumes contextually relevant entries stored centrally.
- [ ] **[P2] 8.2 LocalizationPrep**
  - [ ] Move key UI strings into a localization map with English defaults.
  - [ ] Hook widgets into the localization structure for future translation.

### 9. Quality Assurance & Documentation
- [ ] **[P1] 9.1 FlowAcceptanceTests**
  - [ ] Script manual test cases for happy and edge paths per user story.
  - [ ] Store acceptance checklist within `AGENTS.md` for team reference.
- [ ] **[P1] 9.2 WidgetTestScaffolding**
  - [ ] Add foundational widget tests for navigation and state changes.
  - [ ] Cover theme toggle, group contribution, and savings boost interactions.
- [ ] **[P2] 9.3 HandoffAppendix**
  - [ ] Maintain changelog entries with date, contributor, and summary.
  - [ ] Ensure implementation notes remain up to date for coordinated delivery.
- [ ] **[P1] 9.4 DataModelParityAudit**
  - [ ] Keep `architecture.md` and `AGENTS.md` aligned with newly added models/services (e.g., savings contributions) each sprint.
  - [ ] Introduce a changelog snippet noting when mock schemas change so backend planning stays in sync.

### QA Checkpoints
- **[P0 Navigation Slice]** Confirm splash → auth → main tabs, ensure `MainScreen` preserves state, record issues.
- **[P0 Dashboard Slice]** Validate refreshed home, savings, transactions cards; capture screenshots for before/after log.
- **[P1 Onboarding Slice]** Walk through onboarding copy changes, verify skip, confirm analytics stub.
- **[P1 Savings & Groups Slice]** Play through group list/detail and savings goal flows, note data inconsistencies.
- **[P2 Support Slice]** Review profile/help localization prep once content updates land.

### 10. Wallet & Cashflow Journeys
- [ ] **[P1] 10.1 DepositFlowPrototype**
  - [ ] Build an interactive deposit flow (amount entry → channel selection → confirmation) that updates wallet balance and logs a transaction locally.
  - [ ] Include a review step outlining fees and reference IDs to mirror regulatory requirements.
- [ ] **[P1] 10.2 WithdrawalFlowPrototype**
  - [ ] Implement a withdrawal request experience with compliance checklist, status feedback, and mock failure scenarios.
  - [ ] Sync withdrawal outcomes to the Transactions list and trigger notification badges.
- [ ] **[P2] 10.3 CashflowReceipts**
  - [ ] Provide shareable receipt modals/PDF stubs for deposits and withdrawals accessible from detail views.
  - [ ] Allow users to export recent cashflow activity for offline records (CSV or PDF stub).

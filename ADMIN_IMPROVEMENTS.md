# Sankofa Admin Enhancement Roadmap

This roadmap tracks the prioritized improvements required to align the `sankofa_admin` console with the richer domain models implemented in the mobile app. All work items remain front-end only with static data.

## Legend
- **Status**: `[ ]` not started, `[x]` complete.
- **Priority**: `P0` (immediate), `P1` (next), `P2` (later).
- Each task is expressed as a user story with acceptance criteria and a test checklist.

## Tasklist

### [x] P0 — Data Parity Audit _(Completed 2025-01-23)_
**User Story**: As a platform operator, I need the admin console to reflect the same member, group, savings, transaction, and dispute data fields as the app so that I can trust the information when taking actions.

**Acceptance Criteria**
- Canonical data dictionaries are produced for each entity (`Member`, `SusuGroup`, `SavingsGoal`, `Transaction`, `Notification`, `Dispute`) using the app's mock services as the source of truth.
- A parity matrix maps every field to its intended presentation in admin tables, detail drawers, and charts, highlighting any gaps.
- Open questions or missing fields are documented with recommended UI placements.

**Test Checklist**
- ✅ Review the dictionary against `UserService`, `GroupService`, `SavingsService`, `TransactionService`, and `NotificationService` outputs (no dedicated `DisputeService` exists in the app; see gaps below).
- ✅ Confirm each field has a visual destination in the admin UI (table column, badge, tooltip, chart metric).
- ✅ Validate that light and dark mode color tokens exist for new status pills or charts referenced in the mapping.

#### Canonical Data Dictionaries (App → Admin)

##### Member (`UserModel` via `UserService`)
| Field | Type | Source (App) | Notes / Admin Usage |
| --- | --- | --- | --- |
| `id` | `String` | `lib/models/user_model.dart` | Hidden identifier used for row keys and cross-entity joins.
| `name` | `String` | `lib/models/user_model.dart` | Primary display in users table, detail header, and search autocomplete.
| `phone` | `String` | `lib/models/user_model.dart` | Users table column; mask middle digits in list, show full in drawer.
| `email` | `String` | `lib/models/user_model.dart` | Users detail drawer contact section.
| `photoUrl` | `String?` | `lib/models/user_model.dart` | Avatar in table/detail; fall back to initials if null.
| `kycStatus` | `String` | `lib/models/user_model.dart` | Status pill (color tokens: success, warning, destructive) and filter chip.
| `walletBalance` | `double` | `lib/models/user_model.dart` | Currency column + sparkline in detail view.
| `createdAt` | `DateTime` | `lib/models/user_model.dart` | "Joined" column + timeline.
| `updatedAt` | `DateTime` | `lib/models/user_model.dart` | Admin audit log timestamp; surface in detail meta.

##### Susu Group (`SusuGroupModel` via `GroupService`)
| Field | Type | Source (App) | Notes / Admin Usage |
| --- | --- | --- | --- |
| `id` | `String` | `lib/models/susu_group_model.dart` | Row key and deep-link slug.
| `name` | `String` | `lib/models/susu_group_model.dart` | Primary card title + table column.
| `memberIds` | `List<String>` | `lib/models/susu_group_model.dart` | Count drives member totals; cross-reference with Members tab.
| `memberNames` | `List<String>` | `lib/models/susu_group_model.dart` | Roster preview chips in cards/drawers.
| `invites` | `List<GroupInviteModel>` | `lib/models/susu_group_model.dart` & `group_invite_model.dart` | Invite funnel metrics, reminder queue, acceptance rates.
| `targetMemberCount` | `int` | `lib/models/susu_group_model.dart` | Capacity indicator + progress bar denominator.
| `contributionAmount` | `double` | `lib/models/susu_group_model.dart` | Displayed in currency column and calculator tooltip.
| `cycleNumber` | `int` | `lib/models/susu_group_model.dart` | Current cycle indicator in timeline badge.
| `totalCycles` | `int` | `lib/models/susu_group_model.dart` | Completion percentage for progress ring.
| `nextPayoutDate` | `DateTime` | `lib/models/susu_group_model.dart` | Countdown badge + scheduler view.
| `payoutOrder` | `String` | `lib/models/susu_group_model.dart` | Tooltip explaining rotation rule.
| `isPublic` | `bool` | `lib/models/susu_group_model.dart` | Filter toggle + badge.
| `description` | `String?` | `lib/models/susu_group_model.dart` | Overview paragraph in detail drawer.
| `frequency` | `String?` | `lib/models/susu_group_model.dart` | Secondary metadata line.
| `location` | `String?` | `lib/models/susu_group_model.dart` | Map/region tag.
| `requiresApproval` | `bool` | `lib/models/susu_group_model.dart` | Access control pill + filter.
| `createdAt` | `DateTime` | `lib/models/susu_group_model.dart` | Historical analytics cohorting.
| `updatedAt` | `DateTime` | `lib/models/susu_group_model.dart` | Audit trail.

Group Invite breakdown:
| Field | Type | Admin Placement |
| --- | --- | --- |
| `status` | `GroupInviteStatus` | Invite pipeline badges with color-coded status.
| `kycCompleted` | `bool` | Checklist indicator inside invite drawer.
| `sentAt` / `respondedAt` / `lastRemindedAt` | `DateTime` | Timeline + reminder scheduler.
| `reminderCount` | `int` | Counter badge for follow-up cadence.

##### Savings Goal (`SavingsGoalModel` via `SavingsService`)
| Field | Type | Source (App) | Notes / Admin Usage |
| --- | --- | --- | --- |
| `id` | `String` | `lib/models/savings_goal_model.dart` | Row key + drill-in route.
| `userId` | `String` | `lib/models/savings_goal_model.dart` | Join to member for ownership context.
| `title` | `String` | `lib/models/savings_goal_model.dart` | Table column + card headline.
| `targetAmount` | `double` | `lib/models/savings_goal_model.dart` | Goal detail metric + progress denominator.
| `currentAmount` | `double` | `lib/models/savings_goal_model.dart` | Progress numerator; drives milestone badges.
| `deadline` | `DateTime` | `lib/models/savings_goal_model.dart` | Timeline view & risk alerts.
| `category` | `String` | `lib/models/savings_goal_model.dart` | Filter chip + color token selection.
| `createdAt` / `updatedAt` | `DateTime` | `lib/models/savings_goal_model.dart` | Activity feed + audit log.

Savings Contribution (`SavingsContributionModel`) highlights:
| Field | Type | Admin Placement |
| --- | --- | --- |
| `amount` | `double` | Contribution history table in drawer.
| `channel` | `String` | Badge + filter (MoMo, wallet, bank).
| `note` | `String` | Tooltip/expansion for operator context.
| `date` | `DateTime` | Timeline ordering + exported CSV.

##### Transaction (`TransactionModel` via `TransactionService`)
| Field | Type | Source (App) | Notes / Admin Usage |
| --- | --- | --- | --- |
| `id` | `String` | `lib/models/transaction_model.dart` | Table ID + receipt reference.
| `userId` | `String` | `lib/models/transaction_model.dart` | Link to member detail & filters.
| `amount` | `double` | `lib/models/transaction_model.dart` | Currency column with success/failure styling.
| `type` | `String` | `lib/models/transaction_model.dart` | Filter pills (deposit, withdrawal, contribution, payout, savings).
| `status` | `String` | `lib/models/transaction_model.dart` | Status badge (success, pending, failed) with theme-aware tokens.
| `description` | `String` | `lib/models/transaction_model.dart` | Secondary text in table + detail header.
| `date` | `DateTime` | `lib/models/transaction_model.dart` | Primary sort key + timeline.
| `createdAt` / `updatedAt` | `DateTime` | `lib/models/transaction_model.dart` | Audit breadcrumbs; show in expandable metadata.
| `channel` | `String?` | `lib/models/transaction_model.dart` | Channel column + filter (MTN MoMo, wallet transfer, etc.).
| `fee` | `double?` | `lib/models/transaction_model.dart` | Fee breakdown section in detail drawer.
| `reference` | `String?` | `lib/models/transaction_model.dart` | Copyable reference code.
| `counterparty` | `String?` | `lib/models/transaction_model.dart` | Display under description + tooltips.

##### Notification (`NotificationModel` via `NotificationService`)
| Field | Type | Source (App) | Notes / Admin Usage |
| --- | --- | --- | --- |
| `id` | `String` | `lib/models/notification_model.dart` | Row key + read/unread toggle.
| `userId` | `String` | `lib/models/notification_model.dart` | Filter notifications per member.
| `title` | `String` | `lib/models/notification_model.dart` | Primary text in notification center.
| `message` | `String` | `lib/models/notification_model.dart` | Expanded preview.
| `type` | `String` | `lib/models/notification_model.dart` | Icon + color (wallet, payout, reminder, achievement).
| `isRead` | `bool` | `lib/models/notification_model.dart` | Badge indicator + filter.
| `date` | `DateTime` | `lib/models/notification_model.dart` | Relative timestamp.
| `createdAt` / `updatedAt` | `DateTime` | `lib/models/notification_model.dart` | Historical audit of communications.

##### Dispute (Gap)
- The mobile app currently ships no `DisputeModel` or `DisputeService`. Admin mock data (`sankofa_admin/src/lib/mockData.ts`) introduces fields: `id`, `title`, `user`, `group`, `status`, `date`, `priority`.
- Recommendation: model disputes after transaction issues and support tickets once app-side taxonomy exists. Proposed additions for parity:
  - `category` (e.g., payout delay, missing contribution)
  - `sourceTransactionId`
  - `slaDueAt`
  - `assignedTo`
- Until the app exposes disputes, treat admin disputes as operational-only records with notes stored locally.

#### Admin Field Mapping Matrix

| Entity Field | Admin Surface | Component / Route |
| --- | --- | --- |
| Member → `name`, `kycStatus`, `walletBalance` | Users table columns & KPI tiles | `sankofa_admin/src/pages/Users.tsx`
| Member → `phone`, `email`, `photoUrl`, `createdAt`, `updatedAt` | Member detail drawer overview | `Users` drawer panel (to build)
| Member → `walletBalance`, `SavingsGoal` joins | Dashboard KPI "Total Wallet Balances", savings summary chart | `components/dashboard/kpi-card.tsx` (planned), `pages/Dashboard.tsx`
| Susu Group → `name`, `contributionAmount`, `frequency`, `nextPayoutDate`, `totalCycles`, `cycleNumber` | Groups card grid & filters | `sankofa_admin/src/pages/Groups.tsx`
| Susu Group → `memberNames`, `targetMemberCount`, `invites` | Group detail modal roster & invite tracker | `Groups` detail dialog (enhancement)
| Group Invite → `status`, `lastRemindedAt`, `reminderCount` | Invite pipeline table + reminder toasts | `pages/Groups.tsx`
| Savings Goal → `title`, `category`, `targetAmount`, `currentAmount`, `deadline` | Savings goals table (planned) & analytics charts | `pages/Analytics.tsx`
| Savings Contribution → `amount`, `channel`, `date` | Member drawer contribution history & export | `Users` detail drawer (planned)
| Transaction → `type`, `status`, `amount`, `date`, `channel`, `fee`, `reference` | Transactions ledger + receipt dialog | `sankofa_admin/src/pages/Transactions.tsx`
| Transaction → `counterparty`, `description`, `updatedAt` | Transaction detail modal metadata | `Transactions` dialog (planned refresh)
| Notification → `title`, `message`, `type`, `isRead`, `date` | Header notification center & dashboard activity feed | `components/layout/Header.tsx`, `pages/Dashboard.tsx`
| Dispute (mock) → `status`, `priority`, `date`, `title` | Disputes table + filters | `sankofa_admin/src/pages/Disputes.tsx`

#### Outstanding Questions & Follow-ups
- **Disputes parity**: Awaiting mobile app taxonomy; align once dispute models exist or are added to the app backlog.
- **Savings goal roll-ups**: Decide whether dashboard aggregates should show member-owned goals vs. group-linked targets separately.
- **Notification targeting**: Confirm if admin should filter notifications by group as well as member when dataset expands.

### [x] P0 — Seed Data Enrichment _(Completed 2025-01-23)_
**User Story**: As a designer prototyping operator workflows, I need rich mock records in the admin console so that dashboard KPIs, tables, and detail views feel realistic.

**Acceptance Criteria**
- Admin seed files include at least 10 members, 6 susu groups, 20 transactions, 5 disputes, and a representative set of notifications spanning success, pending, and escalated states.
- Dataset totals reconcile with the values shown in KPI cards, charts, and summaries (e.g., wallet balances, contribution progress, payout schedules).
- Each entity includes the status diversity seen in the app (e.g., KYC pending, group invite sent, withdrawal failed).

**Completion Notes**
- Seeded 16 enriched member profiles, 6 susu groups with rotation snapshots, 21 transactions, 5 disputes, and 6 notifications that mirror the app’s terminology and states.
- Dashboard KPIs now calculate from the dataset: 16 users, 6 active/monitoring groups, GH₵ 4,180.50 in non-failed deposits, and GH₵ 29.35 in realized transaction fees.
- Transaction filters and badges recognise the new payout and savings flows so pending/failed states remain visible as data volume grows.

**Test Checklist**
- ✅ Load the admin dashboard and verify KPIs align with manual calculations from the seed JSON/TS data.
- ✅ Inspect each table to ensure pagination/search/filter states work with the larger dataset.
- ✅ Toggle dark mode to confirm badges, charts, and cards maintain accessible contrast.

### [x] P0 — Dashboard Refresh _(Completed 2025-01-23)_
**User Story**: As an operations lead, I want the admin dashboard to surface real-time-feeling insights that mirror the app's activity so that I can spot anomalies quickly.

**Acceptance Criteria**
- KPI cards reflect enriched metrics (active members, total savings, pending payouts, disputes) with week-over-week trend indicators.
- Charts (daily transactions, member growth, contribution mix) visualize the new seed data and adapt to viewport breakpoints (375px, 768px, 1280px).
- Recent activity/notifications panel showcases the latest system events with icons and time stamps consistent with app terminology.

**Completion Notes**
- KPI stack now highlights active members, total savings wallets, pending payouts, and open disputes with trend deltas sourced from a previous-week snapshot.
- Transaction line, member growth area, and contribution mix pie charts aggregate the shared mock datasets and render inside responsive `ResponsiveContainer` shells for handset, tablet, and desktop breakpoints.
- Notifications feed renders status-aware icons and tones while the new payout watchlist tracks pending disbursements alongside their references and scheduled timestamps.

**Test Checklist**
- ✅ Resize the dashboard to 375px, 768px, and 1280px (or use DevTools responsive mode) to confirm KPI wrapping, chart legends, and notification rows remain legible in both themes.
- ✅ Hover charts to validate tooltips respect theme colors and show accurate totals for each metric.
- ✅ Cross-check KPI totals against `mockData.ts` (active members, wallet balances, payout statuses, dispute statuses) to ensure calculations align with the enriched seeds.

### [x] P1 — Member Operations Suite _(Completed 2025-01-23)_
**User Story**: As a compliance analyst, I need to search, filter, and act on member records so that I can approve KYC, review wallets, and inspect savings goals efficiently.

**Acceptance Criteria**
- Member table supports search by name/phone and filters for KYC status, savings participation, and wallet risk levels.
- Detail drawer displays member profile, wallet balance, active savings goals, recent transactions, and KYC documents summary.
- Inline actions allow marking KYC approved/denied, triggering a manual deposit/withdrawal flow, and flagging accounts for review.

**Completion Notes**
- Introduced an operations workspace with KPI snapshots, global search, and dedicated KYC, savings, and risk filters backed by the enriched data set.
- Implemented a Vaul-powered member drawer that surfaces contact info, wallet performance, savings goal progress, recent transactions, and a full KYC document audit trail.
- Wired quick actions and drawer controls to update in-memory member state with toast confirmations for approvals, rejections, manual cashflows, and escalation flags.

**Test Checklist**
- ✅ Exercise each filter combination (KYC, savings participation, and risk) and confirm the table updates with zero-result guidance when applicable.
- ✅ Trigger the Approve, Reject, Manual Deposit, Manual Withdrawal, and Flag actions from both the table menu and drawer footer—verify toast messaging in light and dark themes and confirm status/risk updates inline.
- ✅ Open a member drawer on a handset-width viewport (~375 px) and a desktop width (≥1280 px) to ensure wallet, savings, transaction, and document sections remain readable and scrollable.

### [x] P1 — Group Lifecycle Tools _(Completed 2025-01-24)_
**User Story**: As a group success manager, I need visibility into group health and cycle progress so that I can intervene before payouts fail.

**Acceptance Criteria**
- Groups view includes tabs or filters for public/private status, cycle stage, and invite completion rate.
- Group detail modal lists member roster, contribution cadence, payout timeline, invite statuses, and outstanding reminders.
- Actions support rescheduling a payout, sending reminders, and adjusting contribution amounts (all mocked with optimistic UI feedback).

**Completion Notes**
- Lifecycle filters (visibility tabs, stage dropdown, invite health dropdown) sync to URL parameters and drive the dashboard KPI summary so operators can bookmark specific cohort views.
- Group detail workspace now surfaces roster rotation, contribution cadence, payout timeline, invite pipeline, and reminder queues powered by the enriched mock dataset.
- Operations control centre forms optimistically reschedule payouts, queue reminders, and adjust contribution amounts while broadcasting toast confirmations and refreshing inline metrics.

**Test Checklist**
- ✅ Confirm filters/tab switches persist selection via URL params or state.
- ✅ Validate progress bars, badges, and alerts render correctly in light/dark modes.
- ✅ Walk through each action path and confirm mock state updates reflected in the UI immediately.

### [x] P1 — Cashflow Operations Center _(Completed 2025-01-24)_
**User Story**: As a finance operator, I need to triage deposits and withdrawals with compliance context so that funds move safely.

**Acceptance Criteria**
- Dedicated queue surfaces pending deposits/withdrawals with status chips, amount, channel, and risk flags.
- Detail view highlights compliance checklist, fee breakdown, and activity timeline mirroring the mobile flow steps.
- Export buttons (CSV/PDF stubs) appear for audit logs, showing toast confirmations.

**Completion Notes**
- Introduced a dedicated Cashflow Operations page with deposit/withdrawal tabs, queue filters, and queue health KPI tiles sourced from the enriched dataset.
- Modeled deposit and withdrawal review records (`mockCashflowQueues`) with compliance checklists, fee structures, and analyst notes pulled into a responsive review drawer.
- Wired export stubs and drawer actions (release, hold, fail) to toast confirmations so operators receive feedback without backend calls, matching the static app experience.

**Test Checklist**
- ✅ Change queue filters (status, channel, risk) and validate results update instantly.
- ✅ Verify detail view supports theme switching without layout shifts.
- ✅ Exercise export buttons and ensure toasts confirm stub behavior without errors.

### [ ] P2 — Dispute & Support Desk
**User Story**: As a customer support lead, I want to triage disputes and deliver knowledge base content so that member issues resolve quickly.

**Acceptance Criteria**
- Dispute list supports severity and SLA filtering, showing countdown timers for breaches.
- Dispute detail modal captures conversation history, attachments placeholders, and escalation routing controls.
- Support panel links to the FAQ taxonomy used in the app with search and category chips.

**Test Checklist**
- Validate timers visually update or display static countdown snapshots per mock data.
- Switch themes to ensure alerts and SLA indicators remain legible.
- Confirm FAQ search filters results and empty states provide guidance.

### [ ] P2 — Configuration Center
**User Story**: As a system administrator, I need configuration panels for fees, notification templates, and localization so that I can tune the platform without code changes.

**Acceptance Criteria**
- Settings forms expose transaction fee sliders, notification template editors, and language toggles with preview states.
- Changes persist to mock storage (local state or JSON) and surface success toasts/snackbars.
- Validation prevents saving incomplete templates or conflicting fee settings.

**Test Checklist**
- Attempt invalid submissions and confirm inline errors appear with accessible colors.
- Toggle between light/dark modes to ensure forms and previews adapt correctly.
- Reload the page (or simulate) to verify persisted mock data repopulates fields.

# Implementation Roadmap

This checklist captures the prioritized backlog for bringing the Sankofa backend online and integrating it across clients. Each item is expressed as a user story with acceptance criteria so we can validate functionality as we deliver it.

---

## Phase 0 — Foundation & Infrastructure

- [x] **Story:** As a developer, I want a Django/DRF project scaffolded in `sankofa_backend/` so that API development can begin.
  - **Acceptance Criteria:**
    - `sankofa_backend/` contains a Django project named `core` with REST Framework installed and configured.
    - Environment-specific settings files exist for local and production configurations.
    - Base app structure includes placeholders for accounts, savings, groups, and transactions domains.
    - Initial health-check endpoint responds at `/api/health/`.

- [x] **Story:** As a developer, I need Docker Compose environments for local development and Coolify production so I can run the full stack consistently.
  - **Acceptance Criteria:**
    - `docker-compose.local.yml` orchestrates PostgreSQL, Redis, the Django ASGI app (serving HTTP + WebSockets), Celery worker/beat, and the two React client apps.
    - `docker-compose.coolify.yml` provides a production-ready subset tailored for Coolify deployment (ASGI app, workers, PostgreSQL, Redis, static asset serving instructions).
    - Shared `.env.example` files document required environment variables for each service.
    - Documentation includes commands to build and start each environment.
  - **Verification Steps:**
    - Local: `cp .env.local.example .env.local && docker compose -f docker-compose.local.yml up --build` (run the Flutter app separately with `flutter run` when needed)
    - Coolify: `cp .env.production.example .env.production && docker compose -f docker-compose.coolify.yml config`

- [x] **Story:** As a developer, I want CI scaffolding so tests run automatically, ensuring regressions are caught early.
  - **Acceptance Criteria:**
    - GitHub Actions workflow (or equivalent) installs dependencies, runs linting, and executes backend test suite.
    - Workflow integrates with Docker images where practical.
  - **Verification Steps:**
    - `pip install -r sankofa_backend/requirements-dev.txt`
    - `ruff check sankofa_backend`
    - `python sankofa_backend/manage.py migrate --noinput`
    - `python sankofa_backend/manage.py test`
    - Inspect GitHub Actions run for the `CI` workflow to confirm it finishes successfully on pushes and pull requests.

---

## Phase 1 — Domain Modeling & APIs (Mobile-first)

- [x] **Story:** As a Sankofa user on mobile, I need to authenticate securely so I can access my personal data.
  - **Acceptance Criteria:**
    - Custom user model persists Ghana phone numbers as the primary credential with KYC metadata.
    - OTP-driven signup, login, and password-reset endpoints mirror the mobile flow and return JWT access/refresh tokens.
    - Automated tests cover registration, OTP verification, token refresh, and password reset.
  - **Verification Steps:**
    - `DJANGO_DB_ENGINE=sqlite python sankofa_backend/manage.py test apps.accounts --verbosity 2`
    - `python sankofa_backend/manage.py migrate` against a PostgreSQL instance to apply the new auth tables.
    - Hit `POST /api/auth/register/`, `/api/auth/otp/request/`, and `/api/auth/otp/verify/` with the scenarios documented above.

- [x] **Story:** As a user, I need to view and manage my groups and savings plans on mobile so I can track progress.
  - **Acceptance Criteria:**
    - Models and serializers represent groups, members, contributions, and savings goals per the mobile UI.
    - Endpoints support list/detail, join/leave, and contribution actions used by the app.
    - API responses match the data shapes currently mocked in the Flutter app.
  - **Verification Steps:**
    - `DJANGO_DB_ENGINE=sqlite python sankofa_backend/manage.py migrate --noinput`
    - `DJANGO_DB_ENGINE=sqlite python sankofa_backend/manage.py test apps.groups apps.savings`
    - Exercise the API manually:
      - `GET /api/groups/` to fetch public and joined circles.
      - `POST /api/groups/{group_id}/join/` and `/leave/` to manage membership.
      - `GET /api/savings/goals/` and `POST /api/savings/goals/` to manage goals.
      - `GET /api/savings/goals/{goal_id}/contributions/` and `POST` to contribute and confirm milestone payloads.

- [x] **Story:** As a user, I want to see transaction history and analytics in the mobile app to understand my finances.
  - **Acceptance Criteria:**
    - Transactions model captures type, amount, status, timestamps, and related entities.
    - Aggregated summary endpoints deliver the metrics displayed in the dashboard.
    - Pagination and filtering align with mobile requirements.
  - **Verification Steps:**
    - `DJANGO_DB_ENGINE=sqlite python sankofa_backend/manage.py migrate --noinput`
    - `DJANGO_DB_ENGINE=sqlite python sankofa_backend/manage.py test apps.transactions --verbosity 2`
    - Hit `GET /api/transactions/` (optionally pass `types`, `statuses`, `start`, `end`, `search`) and confirm paginated results with camelCase payloads.
    - Hit `GET /api/transactions/summary/` and verify totals reflect inflow/outflow breakdowns and pending counts.

- [x] **Story:** As a mobile user, I expect real-time updates when group activity changes.
  - **Acceptance Criteria:**
    - Channels-based WebSocket endpoint broadcasts relevant events (new contributions, goal progress).
    - Mobile client subscription instructions documented and tested against the backend.
  - **Verification Steps:**
    - `DJANGO_DB_ENGINE=sqlite python sankofa_backend/manage.py test apps.groups.tests.test_group_activity_ws`
    - Start the backend (`docker compose -f docker-compose.local.yml up backend`) and obtain a JWT access token via `/api/auth/otp/verify/`.
    - Connect a WebSocket client to `ws://localhost:8000/ws/groups/<group_id>/?token=<ACCESS_TOKEN>`.
    - Trigger group events (join/leave via `/api/groups/{group_id}/join/` or `/leave/`, savings contributions via `/api/savings/goals/{goal_id}/contributions/`) and observe `group.membership.*` or `savings.contribution.recorded` payloads streamed over the socket.

---

## Phase 2 — Mobile Client Integration

- [x] **Story:** As the product team, we want the Flutter app wired to live APIs so we can validate the full experience.
  - **Acceptance Criteria:**
    - Update Flutter networking layer to hit the Django endpoints with environment-aware base URLs.
    - Ensure authentication flows store and refresh JWTs correctly.
    - All mocked data replaced with API-driven state.
    - Manual QA checklist documented (screenshots, key flows) and automated integration tests added where feasible.
  - **Current Status:**
    - ✅ Flutter login now requests and verifies OTPs against `/api/auth/otp/request/` and `/api/auth/otp/verify/`, persists JWTs, and refreshes access tokens via `/api/auth/token/refresh/`.
    - ✅ Groups, savings, and transactions screens now hydrate from the live Django APIs (with local drafts cached only for client-side workflows such as group creation and manual deposits).
    - ✅ Private group creation, invite reminders, acceptance tracking, and roster promotions now call live Django endpoints so admins and invitees stay in sync across devices.
  - **Verification Steps:**
    1. Ensure the Django backend is running locally (`python sankofa_backend/manage.py runserver`) or via Docker at `http://localhost:8000`.
       - Browser-based clients (Flutter web, React apps) now receive permissive CORS headers in debug mode. For non-local origins set `DJANGO_CORS_ALLOWED_ORIGINS="https://example.com,https://app.example.com"` before starting the server so those hosts are explicitly allowed.
       - When running the backend outside Docker or executing tests without Redis, set `DJANGO_CHANNEL_LAYER=memory` to switch Channels to the in-memory layer.
       - Each registration, login, or password-reset OTP now produces a text file under `sankofa_backend/sent_emails/`; inspect the newest file after triggering a request to confirm delivery content.
    2. Launch the Flutter app. The client now auto-selects a sensible local base URL (`http://10.0.2.2:8000` on Android emulators, `http://localhost:8000` on iOS simulators/macOS, `http://127.0.0.1:8000` on Windows/Linux, and `http://localhost:8000` on Flutter web). Override as needed for physical devices by supplying a reachable host with:
       ```bash
       flutter run \
         --dart-define=SANKOFA_ENV=local \
         --dart-define=API_BASE_URL=http://<your-local-ip>:8000
       ```
    3. From the login screen:
       - Existing testers can enter a registered phone number, request an OTP, and verify the SMS/console code to reach the dashboard (or KYC screen for pending profiles).
       - New testers can tap **Create an account**, complete the registration form, and verify the signup OTP. Successful verification should land on the KYC checklist first, then the main experience once completed.
    4. Close and relaunch the app. The splash screen should detect the persisted refresh token, silently refresh the access token, and route back to the authenticated experience without re-entering the OTP.
    5. From the Groups tab, verify the list matches `/api/groups/` data and that joining a public circle updates membership counts after refreshing.
       - The tab should surface results (or an empty state) immediately after loading instead of spinning indefinitely. Newly created private circles should appear after a refresh without requiring an app restart.
    6. From the Savings tab, confirm goals mirror `/api/savings/goals/`, then boost a goal and observe the balance update after a successful API response (milestone notifications should appear when thresholds are crossed).
       - The wallet badge on the dashboard should drop by the contribution amount immediately after the API call, and the new savings transaction should appear in history with type `savings`.
       - Attempt a contribution that exceeds the available wallet balance to confirm the API surfaces a validation error instead of accepting the boost.
       - Collect part of the saved balance via the new **Collect savings** card; the app should confirm the transfer, the goal balance should drop by the collected amount, and a `payout` transaction linked to the savings goal should appear in history while the wallet balance increases accordingly.
    7. From the Transactions tab, confirm history matches `/api/transactions/` (server data appears first, followed by any locally simulated deposits/withdrawals).
    8. Launch the private group creation wizard, add at least two invitees, and confirm submission creates the circle on the backend (check `/admin/groups/group/`).
       - Use **Add from contacts** to pull in at least one real phone number (grant contacts permission when prompted) and ensure the formatted number shows in the roster summary.
       - Add another member manually and confirm duplicate phone numbers are blocked with a helpful message.
       - Use the new up/down controls beside each invite to reorder the payout sequence before submitting; the review step and resulting Django record should reflect the revised order with the creator stored as the group owner.
       - In Django admin, verify private circles list the creator in the **Owner** column while public circles show the platform-managed owner entry.
       - From the group detail screen, send a reminder to an invitee and confirm the timestamp increments in the Django admin.
       - Tap **Mark as joined** on an invite to promote them into the roster and verify a corresponding membership appears server-side.
    9. Open the Wallet tab and walk through a full deposit:
       - Submit an amount (e.g., GH₵150) and confirm the request succeeds, the receipt shows the API-generated reference, and the balance refreshes immediately.
       - Refresh the Transactions screen; the deposit should now appear at the top of the history with type `deposit` and the recorded channel.
       - In Django admin, inspect **Transactions → Wallets** to confirm the member wallet increased and the platform wallet mirrors the new float.
    10. From the same wallet screen, submit a withdrawal and test the various outcomes:
        - A compliant cash-out (≤ GH₵1,500) should return status `success`, lower the member wallet balance, and decrease the platform float.
        - Trigger a pending scenario (amount > GH₵1,500 or a destination that requires review) and verify the balance still reflects the hold while the transaction status is `pending` in both the app and admin.
        - Attempt an overdrawn amount to confirm the API returns a validation error surfaced in the app toast/snackbar.
    11. In Django admin under **Accounts → Users**, open the recently onboarded user and verify:
        - Ghana Card uploads now expose “View front/back” links and the submitted timestamp.
        - The read-only wallet balance and updated timestamp align with the latest mobile deposit/withdrawal.
    12. Complete the KYC flow:
       - After signup or from the Profile banner, proceed to the Ghana Card capture steps.
       - Capture both sides using the guided camera flow (or upload existing photos). Retake if the preview looks cropped or blurry.
       - Submit the documents and confirm a success toast appears before landing on the dashboard.
       - On the backend (`sankofa_backend/media/identification_cards/`), verify that two optimised JPEGs are saved inside a per-user folder and that `User.kyc_status` updates to `submitted` with a `kyc_submitted_at` timestamp.
       - The admin at `/admin/accounts/user/<id>/` should now display read-only links to both images for manual review.
    13. After pulling these changes, run `flutter pub get` within `sankofa_app/` so the updated dependency tree (including `fluttercontactpicker` for the invite workflow and `image_picker` for KYC) is ready before compiling the mobile or web client.

---

## Phase 3 — Admin Console Integration

- [x] **Story:** As an admin, I need secure access to manage users, groups, and savings configurations.
  - **Acceptance Criteria:**
    - Admin React app authenticates against backend admin endpoints (role-based access).
    - CRUD endpoints for administrative tasks implemented with proper permission classes.
    - Audit logging captures admin actions.
  - **Verification Steps:**
    - `python sankofa_backend/manage.py migrate`
    - `python sankofa_backend/manage.py test apps.admin_api`
    - From `sankofa_admin`, run `npm install` (first time) then `npm run dev` and confirm:
      - Login at `/login` using a staff account created in Django admin.
      - Navigate to **Users** and approve/suspend a member; verify updates reflect immediately and audit log entries appear via `/api/admin/audit-logs/`.
      - Open **Groups** to inspect membership and invites sourced from the live API.
      - Review **Cashflow** queues populated with pending deposits/withdrawals.
      - Restart the Django dev server (or trigger an auto-reload) and verify the admin session stays authenticated without forcing a logout.

- [x] **Story:** As an operations analyst, I need dashboards and reports within the admin app.
  - **Acceptance Criteria:**
    - Backend exposes analytics endpoints feeding the admin dashboard widgets.
    - Filters and exports match the UI’s capabilities.
  - **Verification Steps:**
    - With the admin console running, confirm the **Dashboard** and **Analytics** views render live metrics from `/api/admin/dashboard/`.
    - Adjust data filters (transaction type/status) on **Transactions** and ensure the results change accordingly.

- [x] **Story:** As a platform operations lead, I need to publish and manage public Susu groups from the admin console.
  - **Acceptance Criteria:**
    - Admin API supports full CRUD on groups plus invite creation, approval, decline, and member removal with audit logging.
    - Group detail drawer in `sankofa_admin` surfaces members, pending invites, and an invite form that mirrors the `sankofa_app` join workflow.
    - New groups default to public/approval-required with platform ownership and optional seeded invites.
  - **Verification Steps:**
    - Backend: `DJANGO_DB_ENGINE=sqlite python sankofa_backend/manage.py test apps.admin_api --verbosity 2`.
    - Frontend: from `sankofa_admin`, run `npm install` (first time) then `npm run dev` and validate the flow:
      1. Sign in as a staff user and open **Groups**.
      2. Click **Create public group**, complete the form (including at least one invite), and submit; confirm the group appears in the table with the expected contribution settings.
      3. Open the group drawer, approve a pending invite, decline another, and remove the approved member—membership and invite counts should update immediately and refresh after a browser reload.
      4. Delete the group and verify it no longer appears in the list while the API returns `404` for the previous detail URL.
      5. From the mobile app (or REST client), join the new public group as a regular user and confirm the response is `202 Accepted` with a pending invite rather than an immediate membership; approve it in the admin console to finalize the join.

---

## Phase 4 — Web App Integration

- [ ] **Story:** As a user on the web experience, I want feature parity with mobile using the same backend APIs.
  - **Acceptance Criteria:**
    - React web app consumes the mobile API endpoints.
    - Authentication, groups, savings, and transactions flows verified across browsers.
    - Shared utility package (if needed) aligns data typing between web and mobile clients.

---

## Phase 5 — Operations & Observability

- [ ] **Story:** As a DevOps engineer, I need monitoring and logging in place to operate the platform confidently.
  - **Acceptance Criteria:**
    - Structured logging configured across services.
    - Health checks and metrics endpoints ready for Coolify integration.
    - Alerting hooks documented (e.g., for Celery task failures).

- [ ] **Story:** As a support engineer, I want robust data backup and migration workflows.
  - **Acceptance Criteria:**
    - Regular database backup process defined and automated.
    - Migration strategy documented, including how to apply schema changes in each environment.

---

## Tracking Progress

Update this document as tasks move from backlog to in-progress to done. Add new stories or refine acceptance criteria as we learn from the clients.


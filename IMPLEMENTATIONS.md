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

- [ ] **Story:** As the product team, we want the Flutter app wired to live APIs so we can validate the full experience.
  - **Acceptance Criteria:**
    - Update Flutter networking layer to hit the Django endpoints with environment-aware base URLs.
    - Ensure authentication flows store and refresh JWTs correctly.
    - All mocked data replaced with API-driven state.
    - Manual QA checklist documented (screenshots, key flows) and automated integration tests added where feasible.
  - **Current Status:**
    - ✅ Flutter login now requests and verifies OTPs against `/api/auth/otp/request/` and `/api/auth/otp/verify/`, persists JWTs, and refreshes access tokens via `/api/auth/token/refresh/`.
    - ✅ Groups, savings, and transactions screens now hydrate from the live Django APIs (with local drafts cached only for client-side workflows such as group creation and manual deposits).
    - ⚠️ Group invite management and savings goal automation still rely on local mocks until the corresponding backend endpoints exist.
  - **Verification Steps:**
    1. Ensure the Django backend is running locally (`python sankofa_backend/manage.py runserver`) or via Docker at `http://localhost:8000`.
       - Browser-based clients (Flutter web, React apps) now receive permissive CORS headers in debug mode. For non-local origins set `DJANGO_CORS_ALLOWED_ORIGINS="https://example.com,https://app.example.com"` before starting the server so those hosts are explicitly allowed.
       - OTP and verification emails are stored as text files under `sankofa_backend/sent_emails/`; inspect the newest file after triggering a request to confirm delivery content.
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
    6. From the Savings tab, confirm goals mirror `/api/savings/goals/`, then boost a goal and observe the balance update after a successful API response (milestone notifications should appear when thresholds are crossed).
    7. From the Transactions tab, confirm history matches `/api/transactions/` (server data appears first, followed by any locally simulated deposits/withdrawals).

---

## Phase 3 — Admin Console Integration

- [ ] **Story:** As an admin, I need secure access to manage users, groups, and savings configurations.
  - **Acceptance Criteria:**
    - Admin React app authenticates against backend admin endpoints (role-based access).
    - CRUD endpoints for administrative tasks implemented with proper permission classes.
    - Audit logging captures admin actions.

- [ ] **Story:** As an operations analyst, I need dashboards and reports within the admin app.
  - **Acceptance Criteria:**
    - Backend exposes analytics endpoints feeding the admin dashboard widgets.
    - Filters and exports match the UI’s capabilities.

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


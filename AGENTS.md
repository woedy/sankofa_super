# Sankofa Super Collaboration Guide

## Project scope
- This monorepo hosts three client applications (`sankofa_app` for Flutter, `sankofa_admin` for the admin React console, and `sankofa_frontend` for the responsive web app that mirrors the mobile experience) alongside the forthcoming Django backend located in `sankofa_backend/`.
- The backend service will be a Django project named `core`, exposed via Django REST Framework and augmented with Celery, Redis, PostgreSQL, and Django Channels when real-time communication is needed.
- Client implementations already display realistic data. Treat their existing types, routes, and UX flows as the contract for backend APIs, models, and serializers.

## Delivery priorities
1. Implement backend APIs that satisfy the mobile experience first, using the Flutter client as the primary acceptance source.
2. Integrate the backend with the mobile client, then the admin console, and finally the web experience (which should leverage the same endpoints as the mobile app).
3. After completing each task, run the relevant automated tests and manual checks, then document the verification steps so they can be reproduced locally.

## Engineering guidelines
- Prefer convention-over-configuration: follow Django and DRF defaults unless a business requirement dictates otherwise.
- Keep shared configuration (environment variables, Docker Compose files, README snippets) synchronized across apps to avoid divergence between local and production setups.
- Background work should be implemented with Celery tasks; schedule periodic jobs with Celery Beat only when a recurring trigger exists.
- For WebSocket requirements, rely on Django Channels and Redis as the channel layer.
- All new code must include appropriate tests (unit, integration, or end-to-end) that can be executed via Docker.
- Document any new commands or operational steps in `IMPLEMENTATIONS.md` as part of the acceptance criteria updates.

## Tooling & automation
- Maintain two Docker Compose configurations in the repo root:
  - `docker-compose.local.yml` for a complete local stack (backend, Celery worker/beat, Redis, PostgreSQL, Channels worker, and both React apps plus the Flutter development server if required).
  - `docker-compose.coolify.yml` optimized for Coolify deployments with the minimal set of services needed for production.
- Environment variables should be managed via `.env` files referenced by Compose services; keep sample values under version control (e.g., `.env.example`).

## Git & review process
- Keep commits scoped to a single logical change whenever possible.
- Update `IMPLEMENTATIONS.md` when tasks start or complete so the checklist always reflects reality.
- Include clear testing notes in commit messages or PR descriptions so reviewers know how functionality was validated.

## Communication
- Each change should state how the user can verify the behavior, referencing Docker commands or in-app flows.
- Surface blockers or architectural questions in the PR description before implementing workarounds.


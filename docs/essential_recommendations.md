# Essential Recommendations Added

This document captures the core recommendations applied to improve reliability, security, and operational consistency.

## Implemented now

1. **Authentication gate for backend APIs (optional token mode)**
   - Node and Python enforce bearer-token auth when `API_AUTH_TOKEN` is configured.

2. **Production fail-fast auth policy**
   - Node fails startup in production if `API_AUTH_TOKEN` is missing.
   - Python fails startup when `APP_ENV=production` and `API_AUTH_TOKEN` is missing.

3. **Standardized error contract**
   - Both backends return structured errors with `code`, `message`, `details`, and `requestId`.

4. **Request tracing**
   - Both backends generate and return `X-Request-Id` on each response.

5. **Pagination limits on list endpoints**
   - `/allocations` and Python `/decision-logs` support a bounded `limit` query.

6. **Time format/ordering validation hardening**
   - Node and Python validation enforce `HH:MM AM/PM` format and end-after-start checks.

7. **Backend integration tests (Node + Python)**
   - Node integration tests cover auth behavior, paged allocations response, and standardized bad-request envelope.
   - Python integration tests now cover request-id header propagation, pagination response envelope, and auth rejection behavior.

8. **Frontend API client alignment**
   - Flutter `ApiService` supports auth token via `--dart-define=API_AUTH_TOKEN` and handles both legacy and paged allocation payloads.

9. **Flutter role guards**
   - Added `RoleGuard` widget and applied role-based route protection for dashboards and lecturer utilities.

10. **CI quality gates**
   - Added GitHub Actions workflow to run Node tests/checks and Python helper/integration tests + compile checks.

11. **Python multi-write consistency**
   - Python conflict resolution now uses a Firestore write batch so timetable updates, notifications, and decision logs commit together.

## Next recommendations (roadmap)

- Add Flutter test/analysis lane to CI when SDK/runtime is available on CI runners.
- Add dedicated AI suggestion endpoints for explainability and idempotent conflict commits.
- Add SLO dashboards and alerting for health/error-rate monitoring in production.

# Implementation Backlog: 100 Additions

This backlog captures 100 concrete additions spanning Flutter frontend, Node backend, Firebase data/security, QA, and DevOps.

## 1) Routing, Navigation, and App Shell (1–15)
- [ ] 1. Add typed route-argument model classes per dynamic route.
- [ ] 2. Add route guards for role-specific routes (admin/lecturer/student).
- [ ] 3. Add centralized Unauthorized screen for blocked routes.
- [ ] 4. Add deep-link support for major screens.
- [ ] 5. Add fallback-to-login flow after repeated role-fetch failures.
- [ ] 6. Add centralized screen-view analytics observer.
- [ ] 7. Add global navigation observer for diagnostics.
- [ ] 8. Add named route constants for all dashboard sub-pages.
- [ ] 9. Add consistent route transition policy.
- [ ] 10. Add post-login return-to-intended-route support.
- [ ] 11. Add app-shell bootstrap loading state.
- [ ] 12. Add session-expired modal + forced re-auth redirect.
- [ ] 13. Add route-level feature flags.
- [ ] 14. Add route deprecation/alias map for safe migrations.
- [ ] 15. Add breadcrumb navigation in complex admin workflows.

## 2) Authentication & Authorization (16–30)
- [ ] 16. Enforce email verification before dashboard access.
- [ ] 17. Add resend-verification-email flow.
- [ ] 18. Add MFA option for admin users.
- [ ] 19. Add password strength meter and policy hints.
- [ ] 20. Add lockout/backoff after repeated failed login attempts.
- [ ] 21. Add active device/session management UI.
- [ ] 22. Add logout-from-all-devices action.
- [ ] 23. Validate Firebase custom claims for role checks.
- [ ] 24. Add auth persistence/cold-start resilience tests.
- [ ] 25. Add account deletion with re-auth requirements.
- [ ] 26. Add optional SSO (Google/Microsoft) for users.
- [ ] 27. Add invite-only onboarding for admins.
- [ ] 28. Add pending-approval role for lecturers.
- [ ] 29. Add role-mismatch recovery UX.
- [ ] 30. Add profile-completeness gate post-auth.

## 3) API/Networking/Resilience (31–45)
- [ ] 31. Add retry with exponential backoff in API client.
- [ ] 32. Add request/response interceptors (token + trace id).
- [ ] 33. Standardize API error model (code/message/details).
- [ ] 34. Add offline write queue support.
- [ ] 35. Add cache-first fallback for selected reads.
- [ ] 36. Add client circuit-breaker for repeated backend failures.
- [ ] 37. Add API version headers and compatibility handling.
- [ ] 38. Add environment profiles (dev/stage/prod).
- [ ] 39. Add TLS pinning for production mobile builds.
- [ ] 40. Add upload/download progress handling.
- [ ] 41. Add timeout-specific user messaging.
- [ ] 42. Add startup backend `/health` diagnostics check.
- [ ] 43. Add cancellation token handling for in-flight requests.
- [ ] 44. Add structured network logging toggle.
- [ ] 45. Add endpoint contract tests with mocked server.

## 4) Backend (Node) Capability Additions (46–60)
- [ ] 46. Add request schema validation middleware for all endpoints.
- [ ] 47. Add auth middleware (Firebase/JWT token verification).
- [ ] 48. Add RBAC middleware and policy checks.
- [ ] 49. Add pagination/filter/sort to `/allocations`.
- [ ] 50. Add `/allocations/:id` detail endpoint.
- [ ] 51. Add PATCH endpoint for allocation updates.
- [ ] 52. Add idempotency keys for conflict resolution requests.
- [ ] 53. Add correlation IDs to all server requests/logs.
- [ ] 54. Switch to structured JSON logging.
- [ ] 55. Add metrics endpoint (e.g., Prometheus format).
- [ ] 56. Add OpenAPI/Swagger docs.
- [ ] 57. Add route-level smoke/integration tests.
- [ ] 58. Use Firestore transactions where consistency is needed.
- [ ] 59. Add dead-letter collection/workflow for failed operations.
- [ ] 60. Add enriched audit trail fields to mutating actions.

## 5) Data Modeling & Firestore (61–70)
- [ ] 61. Add collection/schema docs and naming conventions.
- [ ] 62. Add Firestore security rules test suite.
- [ ] 63. Add all required composite indexes.
- [ ] 64. Add schema/data migration scripts.
- [ ] 65. Add soft-delete and retention policy fields.
- [ ] 66. Standardize `createdAt/updatedAt/updatedBy` metadata.
- [ ] 67. Normalize room references to avoid name duplication.
- [ ] 68. Add denormalized read models for dashboards.
- [ ] 69. Add consistency checker for allocations vs timetables.
- [ ] 70. Add conflict reason-code enum and mappings.

## 6) State Management & Architecture (71–80)
- [ ] 71. Add repository layer between UI and data sources.
- [ ] 72. Add dependency injection container.
- [ ] 73. Add view-state classes for each feature screen.
- [ ] 74. Add immutable DTO/entity classes.
- [ ] 75. Add unified error-state model.
- [ ] 76. Add reusable loading skeleton widgets.
- [ ] 77. Add cross-feature event bus/pub-sub.
- [ ] 78. Enforce feature-module boundaries.
- [ ] 79. Add state restoration for tabs/filters.
- [ ] 80. Add architecture decision records (ADRs).

## 7) UI/UX and Accessibility (81–90)
- [ ] 81. Add polished dark mode and runtime theme switch.
- [ ] 82. Add large-text accessibility validation and fixes.
- [ ] 83. Add semantic labels for major UI controls.
- [ ] 84. Add keyboard navigation support (web/desktop).
- [ ] 85. Add empty states with clear CTA actions.
- [ ] 86. Add shimmer placeholders for loading content.
- [ ] 87. Add pull-to-refresh for primary list pages.
- [ ] 88. Add reusable error/retry component.
- [ ] 89. Add localization (at least 2 locales).
- [ ] 90. Add timezone-aware formatting standards.

## 8) Testing & Quality Gates (91–97)
- [ ] 91. Add widget tests for role-based route redirects.
- [ ] 92. Add integration tests for login->dashboard journeys.
- [ ] 93. Add golden tests for key visual components.
- [ ] 94. Add API client unit tests (mock Dio).
- [ ] 95. Add backend tests for `/resolve-conflict` variants.
- [ ] 96. Add lint/format/type-check CI gate.
- [ ] 97. Add test coverage thresholds in CI.

## 9) DevOps, Security, and Observability (98–100)
- [ ] 98. Add secret scanning and dependency vulnerability scanning.
- [ ] 99. Add crash/error reporting (Flutter + Node).
- [ ] 100. Add staged release pipeline with rollback support.

---

## Suggested Execution
- **Phase 1 (Foundation):** 1–15, 31–35, 46–49, 61–63, 96
- **Phase 2 (Security & Reliability):** 16–23, 36–45, 47–48, 98–99
- **Phase 3 (Feature Depth):** 50–60, 64–80
- **Phase 4 (UX & Quality):** 81–97, 100

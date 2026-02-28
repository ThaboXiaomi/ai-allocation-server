# Portal Feature Matrix (Implementation-Ready)

This document operationalizes the portal recommendations into actionable build targets.

## Admin Portal

### P0
- Live Conflict Queue (priority, age, affected cohorts)
- SLA cards (avg resolve time, open conflicts, recurrence)
- Manual/Auto resolution policy toggles
- Bulk notifications to affected classes

### P1
- Rule engine for allocation constraints (distance, capacity, faculty priority)
- Audit timeline (who approved, what changed, when)
- Export reports (CSV/PDF)

### P2
- Role-scoped admin permissions (viewer, scheduler, super-admin)
- Capacity forecasting and room pressure heatmaps

## Lecturer Portal

### P0
- “Next class” card with countdown and quick actions
- One-tap class actions (start class, mark attendance, announce change)
- Conflict alternatives view with explainable ranking

### P1
- Delivery confirmation for class announcements
- Route helper to new venue
- Continuity options (hybrid fallback / async instructions)

### P2
- Post-class insight cards (attendance trend, room fit)

## Student Portal

### P0
- Personal daily/weekly schedule timeline
- Urgent change labels (Moved now / moved soon)
- One-tap “navigate to room” + ETA hint

### P1
- Notification inbox grouped by urgency/course
- Offline cache for upcoming classes

### P2
- Attendance/progress snapshot and recommendation nudges

## Cross-Portal

### P0
- Standardized error display using backend `error.code` + requestId
- Route-level role protection with portal fallback actions
- Performance budget: initial portal load under target thresholds

### P1
- Unified motion system (durations/easing tokens)
- Accessibility pass (semantics, text scaling, contrast)

### P2
- Experiment framework for UX optimization

## Delivery Plan
- Sprint 1: Admin P0 + Cross-Portal P0
- Sprint 2: Lecturer P0 + Student P0
- Sprint 3: Admin/Lecturer/Student P1
- Sprint 4: P2 items and hardening

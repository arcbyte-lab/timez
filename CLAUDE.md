# Timez — CLAUDE.md

Timez is an Android day planner that renders a day as a two-ring analog clock
face (arcs instead of list rows) so time is perceived as a shape, not a
schedule. Solo developer, 4-week sprint plan, targeting Google Play.

**Read the docs before making any non-trivial change.** They are the actual
spec; this file is just a map to them.

## Doc index (`docs/`)

| Doc | Contents | Read it when touching... |
|---|---|---|
| `01-project-brief.md` | What Timez is, audience, scope, constraints | Anything — start here if new to the project |
| `02-decision-log.md` | ADR-001 to ADR-022, append-only | Before any architectural decision — check if it's already been made (and why) |
| `03-domain-model.md` | Entities, enums, time representation, segmentation/lane algorithms, sync state machine, Drift schema | `timez_core` entities, `timez_data` schema, anything involving time/dates |
| `04-radial-geometry.md` | Pixel-level dial geometry, gestures, haptics, hit testing, LOD tiers, accessibility | The radial dial UI, `CustomPainter` code, gesture handlers |
| `05-sprint-plan.md` | Week-by-week plan, exit criteria, cut list, risk register | Prioritization questions, "should this be in scope now" |

`docs/init.md` holds one fact: `applicationId="com.arcbyte.timez"` (from ADR-017).

**Decision log discipline:** `02-decision-log.md` is append-only. Never edit
or delete an accepted ADR. If a decision needs to change, add a new entry that
supersedes the old one and update the old entry's status — don't rewrite history.

## Architecture (ADR-007, domain model §1)

Three packages, strict one-way dependency:

```
timez_core (pure Dart, no Flutter)  →  timez_data (Drift)  →  app (Flutter/Riverpod)
```

- **`timez_core`** — entities, value objects, time math, segmentation, lane
  assignment, hit-testing math, validation, color derivation. Zero Flutter
  imports — not `dart:ui`, not `Offset`, not `Color`. Angles are `double`
  degrees; colors are `int` ARGB. This boundary is load-bearing: it's what
  keeps the hardest logic unit-testable in milliseconds and rework-safe when
  the radial UI inevitably needs redoing.
- **`timez_data`** — Drift tables/DAOs/mappers/sync bookkeeping. Currently
  empty (not yet started).
- **`app`** — widgets, painters, gestures, Riverpod providers, go_router.
  Currently empty (not yet started).

**Build order is deliberate (ADR-008): engine → linear UI → radial UI.**
Don't build dial/painting code before the engine test surface (domain model
§10) is green. Early dial bugs should be rendering/gesture bugs, never data bugs.

## Where the project actually is right now

- `timez_core`: scaffolded. Entities (`Block`, `Tag`, `BlockTag`) and enums
  (`BlockKind`, `SyncState`) exist under `lib/`. Test files exist for time,
  segmentation, angles, lanes, color, validation, copy, and hit-test — check
  whether they're passing before assuming the corresponding `lib/` logic
  exists; several of those algorithms (day windows, segmentation, lane
  assignment, hit testing, validation, color derivation, copy-to-weekdays)
  are specified in doc 3/4 but may not be implemented yet.
- `timez_data`: empty, not started.
- `app`: empty, not started.

This matches sprint 1 (foundations + engine) per doc 5 — nothing should
render yet, and that's expected.

## Non-negotiable constraints to keep in mind

- **One content primitive**: `Block` (event or task, a property not a
  subtype). Tags carry all the domain vocabulary — don't invent new typed
  subsystems for habits/pomodoro/exams/etc. (ADR-003).
- **Time is always UTC instant + IANA timezone id**, never a bare local
  `DateTime`. Don't hardcode 24-hour days — a local day can be 23 or 25 hours
  under DST (ADR-011, doc 3 §3).
- **Local-first**: every feature must work fully offline (ADR-005).
- **Two input paths, capability parity**: whatever the dial can do, the
  bottom-sheet form must also do, and vice versa (ADR-004).
- **Overlaps are legal in data**, capped visually at 2 lanes + overflow badge
  (ADR-013) — don't add validation that rejects overlapping blocks.
- **No recurrence rules** — bulk copy-to-weekdays only (ADR-016).
- **Sync touches only Timez-created blocks**, written to a dedicated
  secondary "Timez" Google Calendar, never the user's primary calendar
  (ADR-006, ADR-012). Sync work belongs in sprint 4, not earlier.
- **No reminders/notifications in v1** (ADR-018) — don't add notification
  permissions or scheduling code.
- **Linear view is permanent**, not a fallback — it's the accessibility
  surface (ADR-009). Keep it functionally current alongside the dial.

## Stack

Flutter 3.44.9, Dart 3.12.2, Riverpod 3.x (codegen), go_router, freezed,
Drift (not sqflite/Isar), `timezone` package for IANA data, `uuid` (v7,
time-ordered ids). No Dio/Retrofit — the only network work in v1 is the
Google Calendar SDK in sprint 4.

## Definition of done (doc 5 §10)

Engine changes need unit tests; UI changes need widget or golden tests. Zero
analyzer warnings. Must work offline. Reachable from both linear view and
dial where applicable. No hardcoded user-facing strings outside a constants
file. Verify manually on a physical device (Impeller is the default Android
renderer — emulator raster timings mislead).

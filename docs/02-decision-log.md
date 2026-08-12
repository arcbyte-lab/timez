# Timez — Decision Log

**Document 2 of 5** · Status: Draft for review · Last updated: 2026-08-11

---

## How to use this log

This file is append-only. Decisions are never edited or deleted once accepted — if
one turns out to be wrong, a new entry is added that supersedes it, and the old
entry stays in place with its status changed. The reasoning is the valuable part.
Six months from now, "why is noon a ring boundary?" is a question with a real
answer, and losing that answer means relitigating it from scratch.

Each entry records what was decided, what it costs, and what was rejected.

**Statuses:** `Accepted` · `Proposed` (leaning, not committed) · `Pending`
(known decision, not yet made) · `Superseded by ADR-xxx`

---

## ADR-001 — Radial dial as the primary day view

**Status:** Accepted

**Context.** Linear calendars communicate *when* well and *how much* poorly. A list
gives no sense of proportion, and empty time renders as nothing at all. The target
audience's core problem is not forgetting appointments — it is not knowing where
their time goes.

**Decision.** The primary day surface is an analog clock face with blocks drawn as
arcs. Occupied time is ink; free time is whitespace.

**Consequences.** Every layout problem becomes a geometry problem. Text on curves is
hard, small blocks are hard to label, and there is no scrolling escape hatch when a
day is crowded — the dial is fixed-size and the content must fit inside it. Accepting
this is the entire premise of the project.

**Rejected.** A conventional list with a decorative circular summary. Cheaper and
safer, but it is a calendar app with a garnish, not a different way of seeing a day.

---

## ADR-002 — 12-hour face with concentric AM/PM rings

**Status:** Accepted

**Context.** A 12-hour dial must place 24 hours of content somewhere. Three options
existed: a single 24-hour ring, a 12-hour face with a toggle that flips between AM
and PM, or two concentric rings showing both halves at once.

**Decision.** Two concentric rings. AM inner, PM outer. Noon is the boundary between
rings; midnight terminates the outer ring.

**Consequences.**

- The whole day is visible with no interaction, which preserves the at-a-glance
  property that justifies ADR-001
- Available radial thickness per ring is roughly halved, which is the direct cause
  of the touch-target difficulty recorded in ADR-004
- A block spanning noon is a single record rendered as two arc segments on different
  rings, forcing an explicit block-to-segment mapping in the engine
- The face reads as a clock, which matches the audience's existing mental model of
  an analog dial, unlike a 24-hour ring where 3pm sits where 6 o'clock belongs

**Rejected.** *Single 24-hour ring* — maximum thickness and no noon seam, but breaks
clock intuition and halves angular resolution to 15°/hour. *Flip toggle* — full
thickness and a clean face, but hides half the day behind an interaction and splits
noon-crossing blocks across two screens, which is worse than splitting them across
two rings.

---

## ADR-003 — One block primitive, with tags instead of typed subsystems

**Status:** Accepted

**Context.** The audience's needs suggest many features: class timetables, study
sessions, habit tracking, exam countdowns, pomodoro timers, mood logging. Each could
be a first-class type with its own model, screen, and sync behavior.

**Decision.** There is exactly one content type — the block, a span of time with a
title and zero or more tags. All the above are tags applied to blocks in v1.

**Consequences.** The data model, the sync layer, the painter, and the edit sheet
each handle one shape instead of six. New "features" ship as new tags at near-zero
cost. In exchange, a tag carries no behavior — a pomodoro tag will not run a timer,
and a habit tag will not compute a streak. If a tag proves it needs real behavior,
it gets promoted in a later version, having earned it through actual use.

**Rejected.** Typed subsystems per use case. This is the standard way these apps
sprawl past their schedule, and four weeks does not accommodate six subsystems.

---

## ADR-004 — Dual input paths with capability parity

**Status:** Accepted

**Context.** Direct manipulation is what makes the dial feel alive, but arcs are
imprecise. A 15-minute block spans 7.5° of arc — a very small drag handle. Precision
input on a radial surface is genuinely difficult, and screen readers cannot use it
at all.

**Decision.** Every edit is reachable two ways: by dragging arcs on the dial with
snapping and haptics, and by tapping a block to open a bottom-sheet form. Neither
path is a reduced subset of the other.

**Consequences.** Two interaction surfaces to build, test, and keep in sync. The
payoff is that the dial is free to be imprecise-but-pleasant, because the sheet is
always there for exactness. It also means the app degrades gracefully rather than
becoming unusable if the gesture work lands rough.

**Rejected.** *Dial-only* — purer, but unusable with a screen reader and hostile for
fine adjustment. *Sheet-only, dial as display* — safe, but abandons the interaction
that distinguishes the product.

---

## ADR-005 — Local-first; the device database is the source of truth

**Status:** Accepted

**Context.** The app must be fully usable offline, and the audience frequently is —
on transit, in buildings with poor signal, or avoiding mobile data costs.

**Decision.** All reads and writes go to the local database. Every feature works
with the network off, indefinitely. Sync is a layer above, never a precondition.

**Consequences.** No loading spinners on the critical path and no empty states caused
by connectivity. In exchange, conflict resolution becomes the app's problem rather
than the server's, and the schema must carry sync metadata from the beginning
(ADR-011).

**Rejected.** Treating Google Calendar as the source of truth with a local cache.
Simpler conflict story, but makes the app useless offline and couples first launch
to an account.

---

## ADR-006 — Google Calendar sync limited to Timez-created blocks

**Status:** Accepted

**Context.** Two-way sync with a user's full calendar means Timez can modify or
delete events it did not create. For a v1 from a solo developer, the blast radius of
a sync bug there is somebody's job interview disappearing.

**Decision.** Timez writes only blocks it created and never modifies or deletes
events originating elsewhere. Sync work is scheduled entirely in sprint 4.

**Consequences.** Sync bugs are contained to Timez's own data. The trade-off is that
the dial may show an empty morning while the user's Google Calendar has a 9am
lecture, which is a real product question flagged in the brief and not yet settled.
Deferring to sprint 4 also keeps sprints 1–3 free of network, auth, and OAuth work.

**Rejected.** Full two-way sync with the primary calendar. More useful, considerably
more dangerous, and not affordable in four weeks.

---

## ADR-007 — Pure Dart engine with no Flutter dependency

**Status:** Accepted

**Context.** The riskiest part of the project is the radial interaction, which is
also the part most likely to need rewriting after first contact with real use.

**Decision.** Time arithmetic, overlap resolution, block-to-segment mapping, and
time-to-polar-coordinate conversion live in a package with no Flutter imports.
Widgets, painters, and gesture handling sit strictly above it.

**Consequences.** The correctness-critical logic is unit-testable in milliseconds
with no widget harness. When the radial UI gets reworked, the rework cannot break
time math, because time math is not in the layer being reworked. Cost is the
discipline of maintaining the boundary — the temptation to reach for `Offset` or
`Size` inside the engine will be constant, and both have trivial pure-Dart
equivalents.

**Rejected.** Geometry inside `CustomPainter`. Faster to start, and it welds the
hardest logic to the least stable layer.

---

## ADR-008 — Build order: engine, then linear UI, then radial UI

**Status:** Accepted

**Context.** The radial view is the product's reason to exist, which creates pressure
to build it first.

**Decision.** Build the engine first, prove it against a boring linear UI, and build
the dial last.

**Consequences.** The dial is built on an engine already known to be correct, so
early dial bugs are unambiguously rendering or gesture bugs rather than data bugs.
The linear UI is not throwaway — it ships as the accessible equivalent (ADR-009).
The cost is psychological: two of four weeks pass before the app looks like Timez at
all, which is uncomfortable but correct.

**Rejected.** Dial-first prototyping. Motivating, but debugging a novel interaction
on top of unverified data is a bad place to spend a solo developer's scarcest week.

---

## ADR-009 — The linear view ships permanently as the accessible equivalent

**Status:** Accepted

**Context.** A radial UI is close to unusable with TalkBack. Arcs have no natural
reading order, and position carries meaning that does not survive being read aloud.
Retrofitting accessibility onto a shipped radial app is expensive and usually
results in something worse than a purpose-built alternative.

**Decision.** The linear day view is a permanent, first-class part of the product —
not a debug tool, not a fallback for failure. It is the accessible surface and the
precision-editing surface, reachable by anyone at any time.

**Consequences.** Accessibility is close to free, because the alternate view exists
for independent reasons and is built first anyway. Both views must stay functionally
current as features are added.

**Rejected.** Semantics annotations on the dial alone. Technically possible, and it
produces a screen reader experience nobody would choose.

---

## ADR-010 — Android only for v1

**Status:** Accepted

**Context.** Flutter makes iOS nominally free. It is not: a second store account,
review process, device testing, and platform-specific calendar and permission
behavior.

**Decision.** Android only. No iOS, web, tablet, or wearable targets in v1.

**Consequences.** One store, one release pipeline, one set of permission semantics,
one device class to test gestures on. Platform-specific code should still be kept
behind interfaces so a later port is a port rather than a rewrite.

---

## ADR-011 — Sync-shaped schema and UTC-plus-timezone times from day one

**Status:** Accepted

**Context.** Sync ships in sprint 4, but its requirements are structural. A local-only
schema that later needs sync requires a migration, and some information cannot be
recovered retroactively at all — a deletion made before tombstones existed leaves no
trace to propagate.

**Decision.** From the first schema version, every block carries a locally generated
UUID, a nullable remote identifier, a last-modified timestamp, a sync state, and a
soft-delete tombstone. Times are stored as a UTC instant plus an IANA timezone
identifier, never as a bare local date-time.

**Consequences.** Sprints 1–3 carry fields that do nothing yet, which will look like
over-engineering right up until sprint 4, when it is the difference between adding a
feature and performing a migration. The timezone choice also removes an entire class
of daylight-saving bugs that are miserable to reproduce.

**Rejected.** Adding sync fields when sync is built. Cheap now, expensive later, and
silently lossy for deletions in between.

---

## ADR-012 — Timez writes to a dedicated secondary Google Calendar

**Status:** Accepted

**Context.** ADR-006 requires Timez to touch only its own events. Enforcing that by
tagging events inside the user's primary calendar depends on Timez's own bookkeeping
staying correct forever.

**Decision (proposed).** On first sync, Timez creates a secondary calendar named
"Timez" in the user's Google account and writes exclusively there.

**Consequences.** Ownership becomes structural rather than convention-based —
anything in that calendar is Timez's, anything outside it is not. The user gets a
visibility toggle in Google Calendar for free, and disconnecting is a clean deletion
of one calendar. Tags, which have no native Calendar equivalent, ride in private
extended properties with the local database remaining authoritative.

**Rejected.** Writing tagged events into the user's primary calendar. Ownership then
rests on Timez's own bookkeeping staying correct indefinitely, and a single
bookkeeping bug puts other people's events in range.

---

## ADR-013 — Overlaps permitted in data, capped at two lanes in the dial

**Status:** Accepted

**Context.** Two blocks can legitimately occupy the same time. The dial has roughly
50dp of radial thickness per ring, and each concurrent block rendered side by side
divides that further.

**Decision.** The data model permits arbitrary overlap and never rejects a save. The
dial renders up to two radial sub-lanes. A third concurrent block collapses the
cluster into a count badge that opens the linear view for that span.

**Consequences.** The app never argues with a user who genuinely has two things at
3pm, and the ring stays legible because lane depth is bounded. The cost is a
divergence between what the data holds and what the dial shows, which the badge must
make obvious rather than hiding.

**Rejected.** *Forbid overlap* — tidy model, and it makes the app wrong about
reality. *Unbounded lanes* — faithful, and it renders 12dp slivers nobody can tap.

---

## ADR-014 — Drift for local persistence

**Status:** Accepted

**Context.** The day view queries blocks by date range constantly, and ADR-011 commits
to a schema that will be migrated when sync lands in sprint 4.

**Decision.** Drift, over SQLite.

**Consequences.** Real SQL for range queries, compile-time-checked schema, and a
migration system that is mature enough to trust with a shipped app's data. Cost is
build_runner in the loop and a steeper start than a document store.

**Rejected.** *Isar* — pleasant API, but its maintenance situation has been unsettled
enough that staking a shipping app on it is an avoidable risk. *Raw sqflite* — no
dependency risk, and it means hand-writing everything Drift generates.

---

## ADR-015 — Riverpod 3.x with codegen, go_router, freezed

**Status:** Accepted

**Context.** State management and navigation need settling before feature work
begins, and consistency with existing Flutter practice is worth more than novelty.

**Decision.** Riverpod 3.x with code generation for state, go_router for navigation,
freezed for immutable models and sealed types.

**Consequences.** Familiar tooling, compile-time-safe providers, and sealed failure
types that make error handling explicit. Codegen is now load-bearing across three
packages, so build_runner watch is part of the normal workflow.

**Note.** No Dio and no Retrofit in v1. With no backend of your own, the only network
work in the entire project is the Google Calendar SDK in sprint 4.

---

## ADR-016 — No recurrence rules; bulk copy to weekdays instead

**Status:** Accepted

**Context.** A student timetable repeats weekly, so some form of repetition is
necessary. Full RRULE support brings exception handling, edit-this-versus-all-future
prompts, and awkward interactions with Google Calendar sync — plausibly a full week
of the four available.

**Decision.** No recurrence rules in v1. Instead, a bulk action materializes
independent copies of a block onto selected weekdays over a chosen horizon.

**Consequences.** Every block stays a plain, standalone row — no expansion logic, no
exception records, no special cases in sync. Editing one copy does not affect the
others, which is the honest trade: changing a class time means editing several
blocks, or deleting the set and re-copying. Real recurrence becomes a v2 feature
informed by whether users actually hit this wall.

**Rejected.** *Full RRULE* — correct and unaffordable. *No repetition at all* —
re-entering five classes every morning is not a product anyone keeps using.

---

## ADR-017 — App identity and signing

**Status:** Accepted

**Context.** The `applicationId` is permanent from the first upload to Play Console.
It cannot be changed later without publishing a different app and abandoning every
install, rating, and review. The signing key is equally unrecoverable: losing it
historically meant losing the ability to update the app at all.

**Decision.**

- **`applicationId`:** reverse-DNS, lowercase, of the form `com.<domain>.timez`. If
  no domain is owned, use `io.github.<username>.timez` — a namespace you demonstrably
  control, with no renewal risk. It must be settled in week 1, before the first
  closed-testing upload.
- **Store listing name:** "Timez" if available, with a longer fallback such as
  "Timez — Radial Day Planner". The listing name is separate from the
  `applicationId` and *can* be changed later, so availability is a naming problem
  rather than a permanent one.
- **Signing:** enrol in Play App Signing. Google holds the app signing key; you hold
  an upload key. Distribute as an Android App Bundle.
- **Keystore hygiene:** the upload keystore and its passwords are backed up in two
  separate locations before the first upload, and neither the keystore nor
  `key.properties` is ever committed to version control.

**Consequences.** Play App Signing makes a lost upload key recoverable — Google can
reset it — which removes the single most catastrophic failure mode available to a
solo developer. The trade is that Google holds the signing key, which is the
standard arrangement for new apps and not meaningfully optional.

**Blank to fill in week 1.** The `<domain>` or `<username>` segment. Everything else
here is settled.

---

## ADR-018 — Reminders and notifications deferred to v2

**Status:** Accepted · Supersedes pending decision P-08

**Context.** A planner that never notifies is arguably incomplete. But notifications
on modern Android are a body of work in themselves: runtime permission for
notifications, exact-alarm permission and its policy justification at review time,
scheduling that survives reboot and process death, and per-OEM background
restrictions that vary widely across the Android devices this audience actually owns.

**Decision.** No reminders, alarms, or notifications in v1. Deferred to v2.

**Consequences.** Sprint scope shrinks by a genuinely unpredictable amount, and the
app requests no notification or alarm permissions at all — which also simplifies the
Play Console data-safety declaration. Timez v1 is a planning and reflection tool you
open deliberately, not something that interrupts you. The risk is that some users
consider a planner without reminders unfinished; closed testing is the right place to
find out how many.

---

## ADR-019 — v1 displays only Timez-created blocks

**Status:** Accepted · Supersedes pending decision P-10

**Context.** ADR-006 limits what Timez *writes*. This decision settles what it
*reads*. The dial could display the user's existing Google Calendar events as
read-only context, or show nothing but its own blocks.

**Decision.** The dial and the linear view display Timez blocks only. Existing
calendar events are neither read nor rendered in v1.

**Consequences.** The read path stays trivial — one local database, no merge logic,
no reconciling foreign events with the lane algorithm, no read scope on the OAuth
consent screen beyond what writing requires. The honest cost is that a user with a
full Google Calendar sees an empty-looking morning in Timez while a lecture sits in
their calendar, which makes Timez a deliberate second surface rather than a
replacement calendar. For v1 that is an acceptable identity: Timez is where you plan
your day, not where your institution's events live.

**Revisit in v2**, where read-only display of foreign events becomes the natural
next feature and the merge logic can be built against a proven lane algorithm.

---

## ADR-020 — 15-minute default snap with a hold-to-refine mode

**Status:** Accepted · Supersedes pending decision P-05

**Context.** Snap granularity trades precision against ease. Fine snapping makes every
ordinary drag fiddly; coarse snapping makes exact times unreachable on the dial.

**Decision.** Default 15 minutes (7.5° per step), configurable to 5, 10, 15, or 30.
Holding a drag stationary for 400ms drops to 5-minute resolution with a distinct
haptic; releasing returns to the default. Snapping applies to the value being edited —
during a move the start snaps and duration is preserved exactly.

**Consequences.** The common case stays fast and the precise case stays reachable
without a settings trip. Preserving duration during moves avoids a specific and
infuriating class of bug where a 50-minute block silently becomes 45.

---

## ADR-021 — Modal selection with radially staggered off-arc handles

**Status:** Accepted · Supersedes pending decision P-06

**Context.** A 15-minute block spans 7.5°, roughly 16dp of arc. Two independent resize
handles cannot fit inside 16dp, and this was identified from the outset as the hardest
interaction problem in the project.

**Decision.** Selection is modal and exclusive: exactly one block is selected, and
while it is, its handles are the only interactive elements on the dial. Handles are
two 48dp pucks centered on the segment's angular ends, staggered radially — start puck
8dp inside the band's mid-radius, end puck 8dp outside. The hub becomes a live
start/end/duration readout during the drag.

**Consequences.** Full-size touch targets become possible regardless of block
duration, because the pucks may overlap neighbouring blocks with no risk of hitting
them. The radial stagger is what keeps both handles targetable on a 5-minute block.
The cost is a required selection step before resizing — one extra tap, in exchange for
resize working at all below 30 minutes.

**Rejected.** *Handles inside the arc* — impossible below roughly 45 minutes.
*Resize only via the bottom sheet* — workable, and it concedes the interaction that
justifies ADR-001.

---

## ADR-022 — Four level-of-detail tiers keyed to rendered diameter

**Status:** Accepted · Supersedes pending decision P-07

**Context.** Seven mini faces across a 360dp phone leaves 45dp each, where two
concentric rings are not legible at any stroke width.

**Decision.** Rendering degrades by rendered diameter, not by which screen is showing
it: **Full** (≥240dp, everything, interactive), **Compact** (96–239dp, two rings, no
labels, overlaps merged), **Mini** (48–95dp, single merged ring), **Micro** (<48dp, a
ring gauge showing proportion of the day planned). Week view uses a 2×4 grid landing
in Compact; month view uses a 7×5 grid landing in Micro.

**Consequences.** Tiers are a property of the painter, so tablet and landscape layouts
pick up richer rendering with no layout-specific code. The visible cost is that week
view abandons the familiar Mon–Sun row — seven columns would force Micro, where there
are no arcs at all. Legibility was judged worth more than the calendar-row convention.

---

## Pending decisions

Known, not yet made, each with an owning document.

| # | Decision | Needed by | Document |
|---|---|---|---|
| ~~P-01~~ | ~~Overlap policy~~ | — | Resolved by ADR-013 |
| ~~P-02~~ | ~~Local database~~ | — | Resolved by ADR-014 |
| ~~P-03~~ | ~~State management and navigation~~ | — | Resolved by ADR-015 |
| ~~P-04~~ | ~~Recurrence strategy~~ | — | Resolved by ADR-016 |
| ~~P-05~~ | ~~Snap granularity~~ | — | Resolved by ADR-020 |
| ~~P-06~~ | ~~Drag handle pattern~~ | — | Resolved by ADR-021 |
| ~~P-07~~ | ~~Mini-face level-of-detail tiers~~ | — | Resolved by ADR-022 |
| ~~P-08~~ | ~~Reminders and notifications~~ | — | Resolved by ADR-018 |
| ~~P-09~~ | ~~App identity and signing~~ | — | Resolved by ADR-017 |
| ~~P-10~~ | ~~Display of non-Timez calendar events~~ | — | Resolved by ADR-019 |

All ten pending decisions are now resolved. One item from ADR-017 still needs a human
answer in week 1: the domain segment of the `applicationId`, which is permanent from
the first upload and therefore blocks the first closed-testing release.

---

*Next: Document 3 — Domain Model Specification.*

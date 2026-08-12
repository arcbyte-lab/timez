# Timez — Domain Model Specification

**Document 3 of 5** · Status: Draft for review · Last updated: 2026-08-11

Implements decisions ADR-002, ADR-003, ADR-005, ADR-006, ADR-007, ADR-011,
ADR-013, ADR-014, ADR-016.

---

## 1. Purpose and layering

This document defines the data the app stores and the pure computations performed
over it. It is the contract the engine is built to satisfy.

Three layers, with dependencies pointing strictly downward:

| Layer | Contains | May import |
|---|---|---|
| **Engine** (`timez_core`) | Entities, value objects, time math, segmentation, lane assignment, validation | Dart SDK only |
| **Data** (`timez_data`) | Drift tables, DAOs, mappers, sync bookkeeping | Engine, Drift |
| **UI** (`app`) | Widgets, painters, gestures, providers, routing | Everything above |

The engine imports no Flutter. Not `dart:ui`, not `Offset`, not `Color`, not `Size`.
Angles are `double` degrees, colors are `int` ARGB, points are a local `PolarPoint`
value type. This boundary is the whole value of ADR-007 and it is worth defending
pedantically — the moment `dart:ui` appears in the engine, the geometry stops being
testable without a widget harness.

---

## 2. Entities

### 2.1 Block

The single content primitive (ADR-003). A span of time with a title and tags.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | UUID v7, generated locally at creation. Time-ordered, so it also sorts by creation. Never changes, never reused. |
| `title` | `String` | 1–120 chars after trim. Required. |
| `notes` | `String?` | Max 2000 chars. |
| `startUtc` | `DateTime` | UTC instant. Always `isUtc == true`. |
| `endUtc` | `DateTime` | UTC instant. Strictly greater than `startUtc`. |
| `timeZoneId` | `String` | IANA identifier, e.g. `Asia/Jakarta`. The zone the block was authored in. |
| `kind` | `BlockKind` | `event` or `task`. A property, not a subtype. |
| `completedAt` | `DateTime?` | UTC. Non-null means done. Meaningful for `task`; ignored for `event`. |
| `copyGroupId` | `String?` | See §7. Set on blocks produced by one bulk-copy action. |
| `createdAt` | `DateTime` | UTC. |
| `updatedAt` | `DateTime` | UTC. Bumped on every mutation. Drives conflict resolution. |
| `deletedAt` | `DateTime?` | UTC. Non-null is a tombstone (§6.2). |
| `remoteId` | `String?` | Google Calendar event id. Null until first successful push. |
| `remoteEtag` | `String?` | Last etag seen from Google. Used for change detection. |
| `syncState` | `SyncState` | See §6.1. |

Tag membership is a separate relation (§2.3), not a field.

### 2.2 Tag

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | UUID v7. |
| `name` | `String` | 1–24 chars after trim. Unique case-insensitively among non-deleted tags. |
| `colorArgb` | `int` | 32-bit ARGB. Engine treats color as an opaque integer. |
| `sortOrder` | `int` | Dense, zero-based. Determines the primary tag (§5). |
| `createdAt` / `updatedAt` / `deletedAt` | `DateTime` / `DateTime` / `DateTime?` | As above. |

Tags are local-only in v1. They have no Google Calendar equivalent and are carried
in private extended properties on push (ADR-012), never read back as authoritative.

**Seeded tags.** A first-run set, fully editable and deletable: `class`, `study`,
`work`, `focus`, `exam`, `gym`, `personal`. These exist so a new user sees color on
the dial within a minute of installing, without a setup flow.

### 2.3 BlockTag

Join relation. Composite primary key `(blockId, tagId)`.

| Field | Type |
|---|---|
| `blockId` | `String` |
| `tagId` | `String` |
| `attachedAt` | `DateTime` |

A block may carry 0–5 tags. The cap is a rendering constraint, not a philosophical
one — beyond five, the edit sheet's chip row wraps badly and the color derivation in
§5 becomes arbitrary.

### 2.4 Enumerations

```
BlockKind  ::= event | task

SyncState  ::= localOnly       — never pushed; no remoteId
             | pendingCreate   — awaiting first push
             | pendingUpdate   — local edit newer than last push
             | pendingDelete   — tombstoned locally, deletion not yet pushed
             | synced          — local and remote agree as of last sync
             | conflicted      — divergent edits, awaiting resolution (§6.3)
```

Both are sealed/enum types via freezed (ADR-015) so exhaustive `switch` is checked
at compile time.

---

## 3. Time representation

**Stored as a UTC instant plus an IANA timezone identifier. Never a bare local
`DateTime`.** (ADR-011)

The pair is required because neither half is sufficient. A UTC instant alone cannot
answer "which local day does this belong to." A local wall-clock time alone becomes
ambiguous or invalid across a DST transition and cannot be compared across zones.

**Consequences to implement deliberately:**

- **A local day is not 24 hours everywhere.** In a DST-observing zone, a day may be
  23 or 25 hours long. Indonesia does not observe DST, so `Asia/Jakarta` is a fixed
  UTC+7 and the common case is clean — but the engine must not encode 24 as a
  constant, because a user who travels will otherwise see a corrupted dial.
- **The day window is computed, not assumed.** `dayWindow(localDate, zone)` returns
  the UTC instants of local midnight and the next local midnight, derived from the
  timezone database rather than by adding 24 hours.
- **The dial always renders wall-clock local time** for the viewing timezone. A block
  authored in another zone renders where it falls locally, not where it was created.
- **Package:** `timezone` for the IANA database. The engine takes a zone identifier
  string and resolves it internally; callers never pass raw offsets.

**Minimum duration:** 5 minutes. **Maximum duration:** 24 hours. Both are engine
invariants, not UI hints.

---

## 4. Geometry and segmentation

The mapping from time to the two-ring dial (ADR-002). Angles here are the pure math;
document 4 covers radii, hit slop, and interaction.

### 4.1 Angular mapping

- The face spans 12 hours over 360°, so **30° per hour, 0.5° per minute**
- 0° is at the 12 o'clock position, angles increase **clockwise**
- **AM ring (inner)** covers local 00:00–12:00. **PM ring (outer)** covers 12:00–24:00
- Both rings start at 0°, which is why the seam is visually coherent: midnight and
  noon sit at the same angular position on their respective rings

For a local time `t`, let `m` be minutes since the start of its half-day
(0 ≤ m < 720). Then `angle = m × 0.5`, and the ring is `am` if the local hour is
under 12, otherwise `pm`.

### 4.2 ArcSegment

The renderable unit. A block produces one or more of these per day.

| Field | Type | Notes |
|---|---|---|
| `blockId` | `String` | The logical block this belongs to. |
| `ring` | `Ring` | `am` or `pm`. |
| `startAngle` | `double` | Degrees, 0–360, clockwise from top. |
| `sweepAngle` | `double` | Degrees, positive, ≤ 360. |
| `lane` | `int` | 0 or 1 (§4.4). |
| `continuesFromPrevious` | `bool` | True if the block began before this segment. |
| `continuesToNext` | `bool` | True if the block extends past this segment. |

The continuation flags exist so the painter can render a flat cap where a block was
cut and a rounded cap where it genuinely begins or ends. Without them, every
noon-crossing block looks like two unrelated blocks.

### 4.3 Segmentation algorithm

`segmentsForDay(blocks, localDate, zone) → List<ArcSegment>`

1. Compute the day window `[dayStart, dayEnd)` in UTC via §3.
2. Discard blocks where `deletedAt != null`, or that do not intersect the window.
3. Clip each block's interval to the window, recording whether the start or end was
   truncated — these become the continuation flags.
4. Compute local noon for the date. Split any clipped interval that crosses it into
   an AM part and a PM part. Each part inherits the flags, and the interior edges
   created by the split are marked as continuations.
5. Convert each part to `startAngle` and `sweepAngle` via §4.1.
6. Assign lanes per ring (§4.4).

A block therefore yields at most two segments on a given day. A block spanning
midnight yields segments on two different days, each flagged as continuing.

**Edge cases that must have tests:** a block exactly ending at noon (one segment,
sweep ends at 360°, no split); a block starting exactly at noon (one PM segment); a
24-hour block (a full AM ring and a full PM ring); a 5-minute block (2.5° sweep); a
block wholly outside the window (no segments); a zero-length block (rejected by
validation, never reaches segmentation).

### 4.4 Lane assignment

Per ADR-013: overlaps are permitted in data, capped at two lanes visually.

Run independently for each ring:

1. Sort segments by `startAngle` ascending, then by longer `sweepAngle` first, then
   by `blockId` for stability. Sort must be total and deterministic — an unstable
   order makes lanes flicker between rebuilds.
2. Sweep in order, maintaining the set of segments still open at each start.
3. Assign the lowest free lane, 0 or 1.
4. If both lanes are occupied, the segment joins an **overflow cluster** rather than
   getting a lane.
5. Emit clusters as a separate list: angular extent plus a hidden count. The dial
   renders a badge; tapping it opens the linear view scoped to that span.

Two segments touching end-to-start do not overlap. Comparisons are half-open:
`[start, end)`.

---

## 5. Color derivation

The engine computes color; it does not know what a `Color` is.

- The **primary tag** is the attached tag with the lowest `sortOrder`
- `colorArgb` of the primary tag is the block's color
- Untagged blocks return a neutral sentinel that the UI maps to a theme default
- Completed tasks return the same value; the UI expresses completion through opacity
  and a strikethrough label, not a different hue

Keeping this in the engine means "why is this block blue?" is answerable by a unit
test rather than by reading painter code.

---

## 6. Sync metadata

Nothing here is exercised before sprint 4, but all of it exists from schema version 1
(ADR-011). The cost of carrying unused fields for three weeks is nil; the cost of
adding tombstones after deletions have already happened is unrecoverable data.

### 6.1 State transitions

```
created locally ................. localOnly
sync enabled, not yet pushed .... pendingCreate
push succeeds ................... synced        (remoteId, remoteEtag set)
local edit while synced ......... pendingUpdate
local delete .................... pendingDelete (deletedAt set, row retained)
delete pushed successfully ...... row purgeable (§6.2)
remote etag differs on pull ..... conflicted
```

### 6.2 Tombstones

Deletion is always soft: `deletedAt` is set and the row remains. A hard delete is
permitted only when the row is `localOnly` (never pushed, so nothing to propagate)
or when a `pendingDelete` has been confirmed remotely **and** has been in that state
for at least 30 days. Every query in the app filters `deletedAt IS NULL` by default;
this is enforced in the DAO layer so no feature can forget it.

### 6.3 Conflict resolution

Last-writer-wins by `updatedAt`, with one exception: if both sides changed since the
last sync and the differences are not identical, the block is marked `conflicted` and
the **local version is kept and continues to be shown**. The remote version is
retained alongside it for a resolution UI.

That resolution UI is explicitly out of scope for v1. Sprint 4 ships detection and
local-preference only — a conflicted block behaves normally, keeps local edits, and
stops syncing until a later version can ask the user. Silently discarding a user's
local edit is a worse outcome than a stalled sync.

---

## 7. Bulk copy to weekdays

Per ADR-016, there is no recurrence engine. Instead:

`copyToWeekdays(block, weekdays, horizon) → List<Block>`

Produces fully independent blocks — new UUIDs, same local wall-clock times, on each
selected weekday within the horizon (capped at 26 weeks). Each copy is an ordinary
row with no link to the original's lifecycle.

The one thread connecting them is `copyGroupId`, a shared identifier that carries no
semantics. It exists so the UI can offer "delete all 40 of these" without implying
that editing one edits the rest. It also gives a future v2 a way to detect
copy-groups and offer migration to real recurrence.

Times are copied as **local wall clock**, not as a fixed UTC offset. A 09:00 class
stays at 09:00 across a DST boundary, which is what a human means by "same time next
week."

---

## 8. Validation

The engine exposes `validate(Block) → List<ValidationIssue>` and never throws for
user input. Issues are sealed types (ADR-015) so the edit sheet can map each to a
field-level message.

| Rule | Issue |
|---|---|
| Title empty after trim | `titleRequired` |
| Title over 120 chars | `titleTooLong` |
| `end <= start` | `endBeforeStart` |
| Duration under 5 minutes | `durationTooShort` |
| Duration over 24 hours | `durationTooLong` |
| More than 5 tags | `tooManyTags` |
| Unknown `timeZoneId` | `invalidTimeZone` |

Overlap is deliberately absent — it is legal (ADR-013).

---

## 9. Persistence shape

Drift (ADR-014). Schema version 1 contains everything above.

**Tables:** `blocks`, `tags`, `block_tags`.

**Indexes:**

- `blocks(start_utc, end_utc)` — the day-range query runs on every view change
- `blocks(deleted_at)` — every default query filters on it
- `blocks(sync_state)` — sprint 4's outbox scan
- `blocks(copy_group_id)`
- `block_tags(tag_id)` — reverse lookup for filtering by tag

**Range query semantics.** A day query selects blocks where
`start_utc < dayEnd AND end_utc > dayStart` — intersection, not containment.
Containment would silently drop every block crossing midnight, and those are exactly
the ones most likely to be wrong in a demo.

**Migrations.** Drift's schema-version tests are set up in sprint 1, before there is
anything to migrate, because setting them up afterward means writing them against
data you already shipped.

---

## 10. Engine test surface

The engine's correctness is defined by these tests passing. They are pure Dart, run
in milliseconds, and gate the sprint 1 exit criteria.

**Time and day windows** — day window in a fixed-offset zone; day window across a DST
transition in a DST-observing zone; a 25-hour day; local-date derivation for a block
near midnight.

**Segmentation** — every edge case listed in §4.3; a block spanning midnight producing
correct segments on both adjacent days; continuation flags on all four boundaries.

**Angles** — 00:00 → 0° AM; 06:00 → 180° AM; 11:59 → 359.5° AM; 12:00 → 0° PM;
18:00 → 180° PM; 23:59 → 359.5° PM.

**Lanes** — two overlapping blocks get lanes 0 and 1; three produce one cluster;
touching blocks share lane 0; assignment is identical across repeated runs with
shuffled input.

**Color** — lowest `sortOrder` wins; untagged returns the sentinel; sort order changes
propagate.

**Validation** — one test per rule in §8, positive and negative.

**Copy** — weekday selection is correct across a month boundary; local wall-clock time
is preserved across a DST boundary; the horizon cap holds; all copies share a
`copyGroupId` and have distinct ids.

---

## 11. Deferred

Recorded so their absence is a decision rather than an oversight.

- Conflict **resolution** UI — detection only in v1 (§6.3)
- Reading or displaying non-Timez calendar events — deferred to v2 by ADR-019
- Attachments, locations, invitees, availability
- Multiple calendars or profiles per user
- Full-text search over blocks and notes
- Reminders and notifications — deferred to v2 by ADR-018

---

*Next: Document 4 — Radial Geometry and Interaction Specification.*

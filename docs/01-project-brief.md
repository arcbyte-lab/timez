# Timez — Project Brief

**Document 1 of 5** · Status: Draft for review · Last updated: 2026-08-10

---

## 1. What Timez is

Timez is an Android day planner that renders a single day as an analog clock face
instead of a vertical list. Time is drawn as arcs on a dial, so a day is perceived
as a shape — how full it is, where the gaps are, how the afternoon compares to the
morning — rather than as rows to be scrolled.

The concept draws on two references:

- **Chronodex** — a hand-drawn analog planner where each hour is a wedge radiating
  from a center. Task-centric, tactile, deliberately non-digital in feel.
- **CircleTime** (iOS) — a circular calendar with day, week, and month views and
  ambient context layers such as daylight and moon phase.

Timez takes the radial time model from both, but targets Android, keeps the scope
narrower for v1, and treats direct manipulation of the dial as a first-class
input method rather than a display-only visualization.

## 2. The problem

Linear calendars are good at answering *"what is at 3pm?"* and bad at answering
*"how full is my day?"* A list has no natural sense of proportion — a 15-minute
block and a 3-hour block look similar until you read the labels, and empty time
is invisible because nothing renders there.

A dial inverts this. Occupied time is ink, free time is whitespace, and both are
visible at a glance without reading a single word. Users of circular calendars
consistently report the same effect: seeing the circle fill up makes over-commitment
obvious in a way a list never does, which nudges toward more realistic planning.

## 3. Who it is for

Senior high school students, university students, and early-career professionals —
roughly ages 16–25.

What this audience shares:

- Days built from a repeating skeleton (classes, shifts, standing meetings) with
  self-directed work fitted into the gaps
- Chronic uncertainty about where their time actually goes
- High tolerance for novel interfaces; low tolerance for setup friction
- Android-first in many markets, and price-sensitive

What follows from this: onboarding must be near-zero, the app has to be useful on
day one with no accounts and no imports, and it must work with no connection.

## 4. Core model

Timez has exactly one content primitive.

**Block** — a span of time with a start, an end, a title, and zero or more tags.
It may be an event (externally imposed, fixed) or a task (self-directed, movable),
but this is a property of the block rather than a separate type.

**Tag** — a user-applied label attached to a block. Tags carry the domain vocabulary
that would otherwise become separate features: `class`, `study`, `focus`, `exam`,
`gym`, `work`, `pomodoro`, `mood`. Tags drive color and filtering.

This is a deliberate compression. Habits, focus sessions, timetables, exam
countdowns, and mood tracking are all *tags on blocks* in v1, not subsystems with
their own data models, screens, and sync rules. If a tag later proves to need real
behavior of its own, it gets promoted in a future version — but earning that
promotion through use is much cheaper than building five subsystems speculatively.

## 5. Views

**Day view (primary).** One 12-hour clock face. Two concentric rings: AM inner,
PM outer. Noon is the boundary between rings; midnight terminates the outer ring.
Blocks render as arc segments. A block spanning noon is one record drawn as two
segments.

**Period view.** A grid of miniature clock faces, one per day, for a chosen week or
month. Purpose is pattern recognition across days, not editing. Legibility at small
sizes is a known constraint and is specified in document 4.

**Linear view.** A conventional vertical day list over the same data. This is not a
fallback or a lesser mode — it is the accessible equivalent for screen reader users,
the precision-editing surface, and the first UI built in the sprint plan.

## 6. Interaction principles

**Two paths to every edit.** Blocks can be created and resized by dragging arcs on
the dial, with snapping and haptic feedback. Every one of those operations is also
reachable by tapping a block to open a bottom-sheet form. The dial is the expressive
path; the sheet is the precise one. Neither is a subset of the other in capability.

**Local-first, always.** The device database is the source of truth. Every feature
works with the network off. Sync is an enhancement layered on top, never a
precondition.

**No surprises in the user's calendar.** Timez reads and writes only the blocks
it created. Existing Google Calendar events are never modified or deleted.

## 7. Scope for v1

In scope:

- Create, edit, move, resize, delete blocks
- Tags with color, applied to blocks
- Day view on a two-ring 12-hour dial with direct manipulation
- Linear day view
- Week and month grids of mini faces
- Local persistence with full offline operation
- Google account sign-in and one-way-then-two-way sync of Timez-created blocks
- Android only

Explicitly out of scope for v1:

- iOS, web, tablet-optimized layouts, wearables
- Home screen widgets
- Weather, daylight, moon phase, health, or activity layers
- Sharing, social features, collaboration
- Monetization of any kind
- Themes and visual customization beyond tag colors
- Analytics dashboards or time-tracking reports
- Reminders, alarms, and notifications of any kind
- Importing or displaying calendar events not created by Timez

The out-of-scope list is as load-bearing as the in-scope one. Four weeks is not
long, and the radial interaction alone carries enough risk to absorb any slack.

## 8. What success looks like for v1

This release is not chasing users. It is proving three things:

1. The two-ring dial is legible on a phone and readable at a glance
2. Direct arc manipulation is precise enough to be preferred over the form for
   ordinary edits, not merely possible
3. The app reaches production on Google Play

If the second one fails, that is a genuine finding and not a failure of the project.
The linear view and the bottom sheet mean Timez remains a working planner either way,
and the dial can be reworked without touching the engine beneath it.

## 9. Constraints

| | |
|---|---|
| Platform | Android only |
| Flutter | 3.44.9 |
| Dart | 3.12.2 |
| Team | Solo |
| Schedule | 4 sprints, 1 week each |
| Distribution | Google Play, production release intended |
| Account type | Personal Play Console (not organization) |

The personal Play Console account carries a closed-testing requirement that runs on
calendar time and cannot be compressed by working faster. It is treated as a
first-class milestone in document 5, not as a release-week task.

## 10. Build order

Engine first, then linear UI, then radial UI.

The engine is pure Dart with no Flutter imports — time arithmetic, overlap
resolution, and the mapping between time and polar coordinates, all unit-testable
without a widget test. The linear UI proves the engine against a boring, low-risk
surface. The radial UI is built last, on top of an engine already known to be
correct, so that when the interaction needs reworking — and the first version of a
novel interaction always does — the rework is confined to the paint and gesture
layer.

## 11. Open questions

Carried forward into later documents; none block this brief.

- **Recurrence.** A student timetable repeats weekly. Full recurrence rules are
  expensive and interact badly with sync. Options: omit from v1, support a simple
  weekly repeat only, or defer entirely to a v2.
- **Overlapping blocks.** Whether to forbid, lane-split, or stack. Affects the
  engine's layout algorithm, so it must be settled in document 3.
- **App identity.** The `applicationId` is permanent from first upload. Play Store
  name availability should be checked before it is chosen.

## 12. Assumptions to confirm

Stated here explicitly so they can be corrected rather than silently inherited:

- Timez is a new, standalone codebase, unrelated to any other Flutter project
- No existing designs, brand, or color direction exist yet
- Indonesian and English are both likely user languages, but v1 ships English-only
- No backend of your own — the device plus Google Calendar is the whole system

---

*Next: Document 2 — Decision Log.*

# Timez — Radial Geometry & Interaction Specification

**Document 4 of 5** · Status: Draft for review · Last updated: 2026-08-11

Implements ADR-001, ADR-002, ADR-004, ADR-009, ADR-013.
Resolves pending decisions P-05, P-06, P-07.

---

## 1. Scope

Document 3 defined the pure mapping from time to angles, rings, and lanes. That math
knows nothing about pixels. This document covers everything below it: radii, touch
targets, gestures, haptics, level-of-detail, and the accessibility surface.

The division matters for testing. Angles and lanes are unit-tested in the engine.
Hit testing is also pure math and lives in the engine. Only painting and gesture
recognition require a widget harness.

**Reference device:** 360 × 800 dp, the common low-to-mid Android phone. Everything
below is specified as a fraction of the dial radius `R`, with dp values shown for the
reference device so the numbers can be sanity-checked against a real thumb.

---

## 2. Radial budget

The dial is a centered square, sized `min(width, height) − 32dp` of margin. On the
reference device that is 328dp, so **R = 164dp**.

Working outward from the center:

| Zone | Inner | Outer | Thickness | At R=164 |
|---|---|---|---|---|
| Hub | 0 | 0.28 R | 0.28 R | 46dp radius |
| gap | 0.28 R | 0.31 R | 0.03 R | 5dp |
| **AM ring** | 0.31 R | 0.58 R | 0.27 R | **44dp** |
| gap | 0.58 R | 0.60 R | 0.02 R | 3dp |
| **PM ring** | 0.60 R | 0.87 R | 0.27 R | **44dp** |
| gap | 0.87 R | 0.90 R | 0.03 R | 5dp |
| Tick & numeral track | 0.90 R | 1.00 R | 0.10 R | 16dp |

**44dp of ring thickness is the central constraint of this entire design.** It sits
just under the 48dp recommended minimum touch target, which is acceptable for tapping
a block — arc length contributes on the other axis — but it is not enough for
resizing, which is why §5 moves handles off the arc entirely.

**Lane subdivision.** When ADR-013's second lane is occupied, the 44dp band splits
into two 21dp lanes with a 2dp separator. 21dp is well below any comfortable target,
so lane hit testing extends into the adjacent gaps and resolves by nearest lane
center. If the pointer lands within 8dp of the lane boundary, a two-item disambiguation
sheet opens rather than the app guessing. Guessing wrong here means silently editing
the wrong block, which is far worse than one extra tap.

---

## 3. Angles and arc rendering

Recapping from document 3: 0° at the 12 o'clock position, increasing clockwise,
30° per hour, 0.5° per minute. AM covers 00:00–12:00 on the inner ring, PM covers
12:00–24:00 on the outer.

**Caps.** A segment end with `continuesFromPrevious` or `continuesToNext` set renders
flat; a true start or end renders with a rounded cap of radius `bandThickness / 2`.
This is what visually distinguishes one block crossing noon from two separate blocks
that happen to abut it.

**Minimum rendered sweep.** A 5-minute block is 2.5° — roughly 6dp of arc at the PM
ring's mid-radius, which is invisible. Blocks under 12 minutes render at a fixed 6°
sweep, inflated **forward from the true start**, so the start position stays honest
and only the end is exaggerated. The inflated end draws a tapered cap rather than a
round one, marking it as "shorter than it looks." Inflation is a rendering concern
only: hit testing, lane assignment, and all data operate on true times.

**Elapsed time.** Time already past on the current day renders at 40% opacity. The
current moment is marked by a hand extending across both rings from hub to tick
track, with a filled dot on the ring where "now" actually falls.

---

## 4. Snapping — resolves P-05

**Default: 15 minutes (7.5° per step).** Configurable in settings to 5, 10, 15, or
30 minutes.

**Fine mode.** Holding a drag stationary for 400ms drops to 5-minute resolution,
announced by a distinct haptic and a subtle expansion of the dragged edge. Releasing
and re-grabbing returns to the default. This gives precision without a settings trip
and without making every ordinary drag fiddly.

Snapping applies to the value being changed, not to the pointer. During a move, the
block's start snaps and the duration is preserved exactly — a 50-minute block stays
50 minutes even though 50 is not a multiple of 15. Snapping duration during a move is
a common and infuriating bug.

---

## 5. Drag handles — resolves P-06

**The problem.** A 15-minute block spans 7.5°. At the PM ring's mid-radius of about
120dp, that is roughly 16dp of arc. There is no way to place two independent resize
handles inside 16dp.

**The resolution: handles are not on the arc, and only exist while selected.**

Tapping a block selects it. Selection is modal and exclusive — exactly one block is
selected, and while it is, its handles are the only interactive elements on the dial.
This removes all ambiguity, because a 48dp handle puck may freely overlap neighbouring
blocks without any risk of hitting them.

**Handle geometry.** Two 48dp circular pucks, centered on the segment's two angular
ends. They are **staggered radially** so they can never collide: the start puck sits
at the band's mid-radius minus 8dp, the end puck at mid-radius plus 8dp. Even on a
5-minute block where both ends are nearly the same angle, the pucks remain separately
targetable.

**During a drag** the hub switches to a live readout — start time, end time, duration
— so the value being edited is never hidden under the thumb. This is the reason the
hub is 46dp of protected space in §2 rather than decoration.

**Ring transfer.** Dragging tracks *time*, not angle. The pointer position resolves to
a (ring, angle) pair, which resolves to a time. Dragging a block past the end of the
AM ring continues it onto the PM ring from 0°, and radial movement across the 3dp gap
transfers rings directly. Both paths must produce the same result, and a medium haptic
marks the transition.

**Constraints during drag.** Duration clamps at the 5-minute and 24-hour engine
invariants; hitting either fires a heavy haptic and the edge stops moving. Dragging an
end past the opposite end does not invert the block — it clamps at the minimum.

---

## 6. Gesture map

| Gesture | Target | Result |
|---|---|---|
| Tap | Block | Select. Shows handles and hub readout. |
| Tap | Selected block | Open the bottom-sheet editor (ADR-004). |
| Tap | Empty ring | Deselect if something is selected; otherwise nothing. |
| Long press | Empty ring | Create a 30-minute block at the snapped time, selected, sheet open on the title field. |
| Long press + drag | Empty ring | Drag out a span; release creates a block of that duration. |
| Drag | Block body | Move, preserving duration. |
| Drag | Handle puck | Resize that edge. |
| Tap | Hub | Toggle between radial and linear view. |
| Tap | Overflow badge | Open the linear view scoped to that angular span. |

Deliberately unused: double-tap (unreliable next to drag), pinch (no zoom concept),
and any two-finger gesture (one-handed phone use is the norm for this audience).

---

## 7. Haptics

| Event | Feedback |
|---|---|
| Block selected | `selectionClick` |
| Each snap increment crossed | `selectionClick`, throttled to one per 40ms |
| Entering fine mode | `lightImpact` |
| Ring transfer during drag | `mediumImpact` |
| Duration clamp hit | `heavyImpact` |
| Block created or deleted | `mediumImpact` |

Throttling matters: a fast drag across six hours crosses 24 snap points, and firing
unthrottled turns pleasant texture into a buzz. All haptics respect the system-level
touch feedback setting.

---

## 8. Hit testing

Pure math, and therefore engine code with unit tests rather than widget tests.

1. Convert the pointer to an offset from the dial center; compute radius `r` and
   angle `θ` normalized to 0–360 clockwise from top.
2. Map `r` to a band — hub, AM, PM, or outside — with 10dp of slop extending into the
   adjacent gaps. Slop is asymmetric at the AM/PM boundary, splitting the 3dp gap
   evenly so the two rings cannot both claim a point.
3. If a lane subdivision is active in that band, pick the nearer lane center, applying
   the §2 disambiguation rule.
4. Convert `θ` to minutes (`θ / 0.5`), add the ring's half-day offset, and resolve
   against the day's segments.
5. When a block is selected, test handle pucks **before** anything else, using
   straightforward circular distance rather than polar bands.

---

## 9. Level of detail — resolves P-07

Rendering degrades by rendered diameter, not by which screen is showing it. Four
tiers:

| Tier | Diameter | Rendering |
|---|---|---|
| **Full** | ≥ 240dp | Two rings, hour numerals, ticks, block labels, lanes, handles, now-hand. Interactive. |
| **Compact** | 96–239dp | Two rings, ticks at 12/3/6/9 only, no numerals, no labels, no lanes (overlaps merged into one arc), flat caps. Tap opens the day. |
| **Mini** | 48–95dp | A single ring. AM and PM merged by union of occupancy; color taken from the longest block in each span. One notch at top. |
| **Micro** | < 48dp | No arcs. A ring gauge showing the proportion of the 06:00–24:00 window that is planned, in the color of the day's most-used tag. |

**Where each tier is used.**

- **Day view** — Full.
- **Week view** — a 2 × 4 grid, giving roughly 160dp per face on the reference device,
  landing in Compact. The eighth cell holds a week summary. This trades the familiar
  Mon–Sun row for legibility, which is the right trade: seven faces across a 360dp
  phone gives 45dp each, where two rings are simply not readable.
- **Month view** — a 7 × 5 grid at roughly 44dp per face, landing in Micro. A month
  of clock faces cannot show detail; what it can show is which days were heavy and
  which were empty, and the gauge does that honestly.

The tier boundaries are properties of the painter, so a tablet or landscape layout
picks up richer rendering automatically without any layout-specific code.

---

## 10. Accessibility

The linear view is the equivalent surface per ADR-009, and it is the answer for
screen reader users. The dial is nevertheless annotated rather than opaque:

- Each block exposes a semantics node labelled with title, start and end in local
  12-hour format, and tags — traversed in start-time order, not paint order
- Custom semantics actions for "increase by 15 minutes" and "decrease by 15 minutes"
  so a block can be adjusted without gestures
- The hub announces the date and a planned-versus-free summary
- The now-hand and elapsed dimming are decorative and excluded from semantics

**Contrast.** Tag colors are user-chosen and can therefore be unreadable. Any tag
whose color falls below a 3:1 contrast ratio against the dial background is drawn
with a 1dp outline in the theme's foreground color. This is computed in the engine
alongside color derivation, so it is unit-testable.

**Motion.** With reduced-motion enabled, transitions become instant and the now-hand
stops sweeping, updating once a minute instead.

**Text scaling.** Hub text scales with system settings. Hour numerals are capped at
1.3× because the tick track has a fixed 16dp budget; beyond that cap the numerals
drop to 12/3/6/9 only.

---

## 11. Painting architecture

Three layers, each in its own `RepaintBoundary`:

1. **Chrome** — rings, ticks, numerals. Repaints only when size or theme changes.
2. **Blocks** — arc segments. Repaints when the day's data changes.
3. **Interaction** — selection ring, handle pucks, drag ghost, now-hand. Repaints
   every frame during a drag.

Only layer 3 is live during a gesture, which keeps drag frames cheap. Segment `Path`
objects are built when data changes and cached, never rebuilt inside `paint`. No
`saveLayer` on the drag path.

**Target:** sustained 60fps drag on a mid-range device, frames under 16ms. Impeller is
the default Android renderer in this Flutter version, so verify on a physical device
rather than an emulator, where raster timings mislead.

---

## 12. Test surface

**Engine (pure Dart):** hit test at ring boundaries and in the gaps; lane
disambiguation at the 8dp threshold; angle-to-time round-tripping at every hour;
minimum-sweep inflation not affecting hit results; contrast rule.

**Golden tests:** each of the four LOD tiers; a noon-crossing block; a midnight-crossing
block; a two-lane overlap; a three-block overflow cluster; empty day; a fully booked
day; light and dark themes.

**Widget tests:** create by long-press-drag; move preserving duration; resize clamping
at both invariants; ring transfer by both angular and radial paths; selection
exclusivity; handle pucks taking priority over underlying blocks.

---

## 13. Open items

- **Visual design language** — type, color palette, elevation, and the AM/PM
  differentiation treatment. Deliberately unspecified here; this document defines
  structure, not style.
- **Empty-day affordance.** A dial with nothing on it is a blank circle, which is a
  poor first-run impression. Needs an answer during sprint 3.
- **Landscape.** Undefined. A wider dial with side-mounted controls is the obvious
  approach, but it is not v1 scope.

---

*Next: Document 5 — Sprint Plan.*

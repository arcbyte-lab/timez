# Timez — Sprint Plan

**Document 5 of 5** · Status: Draft for review · Last updated: 2026-08-11

Four sprints of one week, solo, targeting a Google Play production release.

---

## 1. The thing to understand first

**Four sprints of code do not produce a launched app in four weeks.**

Two external processes gate the release, and neither responds to working harder:

1. **Play Console closed testing.** A personal developer account must run a closed
   test with at least 12 testers opted in continuously for at least 14 days before it
   can apply for production access. Testers dropping out can reset the count.
2. **Google OAuth verification** for the Calendar scope, required for any public
   release that uses it.

The 14-day clock is the binding constraint. It starts when a build reaches a closed
track with testers opted in — not when the app is finished. **The single most
valuable scheduling move available is uploading something usable at the end of week 2
rather than at the end of week 4.** That one change moves the launch date forward by
roughly two weeks, and it is why sprint 2 is scoped around producing a shippable
linear app rather than around building the dial.

**Realistic timeline:** code-complete at the end of week 4; public production release
one to two weeks after that, depending on review and verification.

---

## 2. Calendar

Relative weeks, with an example anchor assuming week 1 begins Monday 17 August 2026.
Adjust the dates; keep the ordering.

| | Week | Dates | Focus | External milestone |
|---|---|---|---|---|
| **S1** | 1 | 17–23 Aug | Foundations + engine | Play Console account opened, identity verification submitted |
| **S2** | 2 | 24–30 Aug | Linear app, end to end | **Closed test live, 12 testers opted in — 14-day clock starts** |
| **S3** | 3 | 31 Aug–6 Sep | Radial day view | OAuth verification submitted |
| **S4** | 4 | 7–13 Sep | Sync, polish, store listing | 14-day requirement satisfied ~13 Sep |
| — | 5 | 14–20 Sep | Buffer, fixes from testers | Apply for production access |
| — | 6 | 21–27 Sep | — | Review, production release |

Weeks 5 and 6 are not sprints. They are the waiting period the external processes
impose, and they are the right place for tester feedback fixes.

---

## 3. Sprint 1 — Foundations and engine

**Goal.** A tested, framework-independent engine and a Play Console account whose
identity verification is already in flight.

### Administrative — do these on day 1

These are first because they involve other people's queues. Play Console identity
verification for a personal account can take several days, and it blocks everything
downstream.

- Decide the `applicationId` domain segment (the one open item in ADR-017)
- Check "Timez" availability on the Play Store; choose a listing name
- Create the Play Console account, pay the $25 fee, submit identity verification
- Create the Google Cloud project; enable the Calendar API
- Generate the upload keystore; back it up in two separate places; add `key.properties`
  and `*.jks` to `.gitignore` before the first commit
- Start recruiting 12 testers — this is a real task, not a formality (see §8)

### Engineering

- Repository, three-package structure per document 3 §1 (`timez_core`, `timez_data`,
  `app`), analyzer configured strict, CI running tests on push
- Engine: entities, value objects, `BlockKind`, `SyncState`, validation
- Engine: day windows via the `timezone` package, including the non-24-hour case
- Engine: segmentation, angular mapping, lane assignment, color derivation
- Engine: hit-test math (used in sprint 3, tested now)
- Data: Drift schema version 1 with the full ADR-011 field set, indexes, DAOs with
  the `deleted_at IS NULL` filter enforced at the DAO layer
- Drift migration tests scaffolded — before there is anything to migrate

### Exit criteria

- The entire document 3 §10 test surface passes
- The document 4 §12 engine tests pass
- Zero analyzer warnings; CI green
- `flutter run` produces a launchable app, even if it shows nothing yet
- Play Console identity verification submitted

**Nothing renders this week.** That is expected and correct per ADR-008, and it is the
week most likely to feel like no progress is being made.

---

## 4. Sprint 2 — Linear app, end to end

**Goal.** A complete, genuinely usable planner with no dial. This is the build that
goes to closed testing.

- Linear day view: vertical list, date navigation, today
- Block creation, editing, deletion via the bottom sheet (ADR-004's precise path)
- Tag management: create, rename, recolor, reorder, delete; the seven seeded tags
- Tag filtering
- Task completion toggle
- Copy-to-weekdays bulk action (ADR-016), including the "delete this group" path
- Riverpod providers, go_router routes, sealed failure handling end to end
- Empty states, error states, first-run experience
- App icon, splash, minimal branding — enough not to embarrass a tester

### The critical milestone

By Friday of week 2: an App Bundle signed with the upload key, uploaded to a closed
track, with **12 testers opted in and confirmed**. Verify each tester actually opted
in via the link. A tester who received the link and never opened it does not count,
and discovering that in week 5 costs two weeks.

### Exit criteria

- Every v1 feature except the dial and sync works
- The closed track is live with 12 confirmed opt-ins
- The 14-day clock has started

If sprint 2 slips, everything after it slips by the same amount plus the clock delay.
Protect this week over any other.

---

## 5. Sprint 3 — The radial view

**Goal.** Document 4, built.

- Three-layer painting architecture, chrome and blocks
- Full-tier dial: rings, ticks, numerals, arcs, caps, minimum-sweep inflation,
  elapsed dimming, now-hand
- Hit testing wired to the engine
- Selection, handle pucks, hub readout
- Drag to move, drag to resize, ring transfer, clamping
- Long-press create, long-press-drag create
- Snapping with hold-to-refine (ADR-020)
- Haptics per document 4 §7
- Compact, Mini, Micro tiers; week 2×4 grid; month 7×5 grid
- Overflow clusters and the disambiguation sheet
- Semantics annotations, contrast outlines, reduced-motion handling
- Golden tests for all four tiers; widget tests for gestures

**Submit OAuth verification this week**, not in sprint 4. It needs a privacy policy at
a public URL, a homepage, scope justification, and possibly a demo video. Preparing
those takes a day; the review takes longer than one week, so submitting in sprint 4
means launching without sync.

### Exit criteria

- The dial is usable for ordinary editing without reaching for the sheet
- 60fps sustained during drag on a physical mid-range device
- Golden and widget tests green
- A second closed-testing build shipped to the same testers

**Highest-risk week.** The gesture work is the least predictable in the project. If it
runs long, cut from §7's list rather than eating into sprint 4.

---

## 6. Sprint 4 — Sync and release preparation

**Goal.** Google Calendar sync, and everything Play requires to publish.

### Sync

- Google Sign-In, Calendar API scope
- Create and discover the dedicated "Timez" secondary calendar (ADR-012)
- Outbox: push creates, updates, deletes by `syncState`
- Pull: reconcile by etag; detect conflicts; keep local, mark `conflicted`, stop
  syncing that block (document 3 §6.3)
- Tags into private extended properties
- Full offline behavior: queue while offline, drain when connectivity returns
- Sign-out that leaves local data intact

### Release preparation

- Store listing: title, short and full description, screenshots, feature graphic
- Data safety declaration — accurate about Google account data
- Privacy policy at a stable public URL
- Content rating questionnaire
- Target API level check
- `minSdk` decision and testing on the oldest supported device

### Exit criteria

- Sync round-trips correctly across two devices
- Airplane-mode edits reconcile on reconnect
- Store listing complete
- Final closed-testing build shipped

---

## 7. The cut list

Ordered. When a sprint runs long, cut from the top before extending a week.

1. Month view (Micro tier)
2. Hold-to-refine fine snapping — ship fixed 15-minute snap
3. Copy-to-weekdays — moves to v1.1
4. Week view (Compact tier)
5. Tag filtering
6. Conflict detection — ship last-writer-wins only

Nothing above the line labelled "never cut": the linear view (ADR-009 accessibility),
tombstones (ADR-011, unrecoverable if omitted), and the closed-testing upload.

**If sprint 3 fails outright** — the gesture work proves unworkable in the time — the
fallback is to ship v1 with a read-only dial plus the linear editor. Document 1 §8
anticipated this. The app still works, still looks like Timez, and the interaction
ships in v1.1 with real feedback behind it.

---

## 8. Recruiting 12 testers

Underestimated by almost everyone, and it can silently invalidate the 14-day window.

- Recruit **15–18** people, not 12. Some will not opt in, and a drop below the
  threshold can reset progress.
- Testers need a Google account and must join through the opt-in link. Confirm each
  one individually rather than assuming.
- Use a Google Group as the tester list — adding and removing members later is far
  easier than editing an email list in the Console.
- Your audience is your tester pool: classmates, colleagues, a study group. They also
  give better feedback than family.
- Give them something specific to try. "Plan tomorrow, then tell me whether the circle
  made your day look fuller or emptier than you expected" produces more than "let me
  know what you think."

---

## 9. Risk register

| Risk | Impact | Mitigation |
|---|---|---|
| Closed-testing clock starts late | Launch slips 1–2 weeks per week of delay | Sprint 2 exit criteria; nothing is allowed to displace it |
| Fewer than 12 testers stay opted in | Clock resets | Recruit 15–18; check the count weekly |
| OAuth verification not granted in time | Ship without sync, or delay | Submit in sprint 3; fallback is v1.0 without sync, v1.1 with |
| Gesture work overruns | Sprint 4 compressed | Cut list §7; read-only dial fallback |
| Play identity verification delayed | Everything downstream blocked | Submit day 1 of sprint 1 |
| Upload keystore lost | Recoverable, not fatal | Play App Signing (ADR-017) plus two backups |
| Solo illness or a bad week | No slack anywhere | Weeks 5–6 absorb it; the cut list is the release valve |

---

## 10. Definition of done

For any task to be complete:

- Engine changes have unit tests; UI changes have widget or golden tests
- Zero analyzer warnings
- Works offline
- Reachable from both the linear view and the dial, where applicable
- No hardcoded strings that a user will read outside a single constants file
- Manually verified on a physical device, not only an emulator

---

## 11. After v1

Not committed, recorded so the deferrals in the decision log have a destination.

- Reminders and notifications (ADR-018)
- Read-only display of foreign calendar events (ADR-019)
- Real recurrence, migrating existing copy groups (ADR-016)
- Conflict resolution UI (document 3 §6.3)
- Home screen widget showing today's dial
- iOS

---

*End of the document set. Documents 1–5 are the project's onboarding baseline.*

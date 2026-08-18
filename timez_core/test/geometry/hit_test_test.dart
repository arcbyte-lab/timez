// Spec: docs/04-radial-geometry.md §2, §4 (minimum sweep), §8, §12
// "Engine (pure Dart)" test surface. Contrast is covered separately in
// color/color_derivation_test.dart, per doc4 §10.
//
// Target API (not yet implemented — timez_core TDD workflow). These are pure
// polar-math functions: the engine never sees an Offset, only radius/angle
// doubles the UI layer has already derived from a pointer position.
//
//   Band bandForRadius(double radiusDp, double dialRadiusDp)
//     Band ::= hub | am | pm | tickTrack | outside
//     Boundaries are fractions of dialRadiusDp per doc4 §2. AM/PM share a
//     narrow gap that must be split evenly so neither ring claims the whole
//     gap (doc4 §8 step 2) — the other gaps are left unresolved here since
//     the doc only specifies disambiguation for the AM/PM seam.
//
//   LaneHit resolveLane({required double offsetIntoBand, required double bandThickness})
//     LaneHit ::= lane0 | lane1 | ambiguous
//     Only meaningful when a band's 2-lane subdivision is active. Within 8dp
//     of the lane boundary (band midline) resolves to `ambiguous` rather
//     than guessing (doc4 §2).
//
//   TimeOfDay angleToTime(double angle, Ring ring)
//     Inverse of `timeToAngle` (time/angular_mapping_test.dart).
//
//   ArcSegment? segmentAtAngle(List<ArcSegment> segments, Ring ring, double angle)
//     Resolves against segments' true (non-inflated) angles — minimum-sweep
//     inflation is a painter-only concern (doc4 §4) and must never leak into
//     hit testing.
//
// Reference device: R = 164dp (doc4 §2), used throughout so the dp figures
// in the doc's table can be checked directly.

// import 'package:test/test.dart';
// import 'package:timez_core/timez_core.dart';

// const _dialRadius = 164.0;
//
// void main() {
//   group('bandForRadius', () {
//     test('deep inside the hub', () {
//       expect(bandForRadius(20, _dialRadius), equals(Band.hub));
//     });
//
//     test('deep inside the AM ring', () {
//       expect(bandForRadius(70, _dialRadius), equals(Band.am)); // 0.31R–0.58R -> 50.8–95.1dp
//     });
//
//     test('deep inside the PM ring', () {
//       expect(bandForRadius(120, _dialRadius), equals(Band.pm)); // 0.60R–0.87R -> 98.4–142.7dp
//     });
//
//     test('deep inside the tick & numeral track', () {
//       expect(bandForRadius(155, _dialRadius), equals(Band.tickTrack)); // 0.90R–1.00R -> 147.6–164dp
//     });
//
//     test('beyond the dial radius is outside', () {
//       expect(bandForRadius(170, _dialRadius), equals(Band.outside));
//     });
//
//     test('AM/PM gap is split evenly so neither ring claims the whole gap', () {
//       // Gap spans 0.58R–0.60R = 95.12dp–98.4dp; midpoint = 96.76dp.
//       expect(bandForRadius(96.0, _dialRadius), equals(Band.am));
//       expect(bandForRadius(97.5, _dialRadius), equals(Band.pm));
//     });
//   });
//
//   group('resolveLane', () {
//     const bandThickness = 44.0; // doc4 §2: 44dp band, split 21/2/21
//
//     test('deep inside lane 0', () {
//       expect(
//         resolveLane(offsetIntoBand: 5, bandThickness: bandThickness),
//         equals(LaneHit.lane0),
//       );
//     });
//
//     test('deep inside lane 1', () {
//       expect(
//         resolveLane(offsetIntoBand: 39, bandThickness: bandThickness),
//         equals(LaneHit.lane1),
//       );
//     });
//
//     test('exactly on the lane boundary is ambiguous', () {
//       expect(
//         resolveLane(offsetIntoBand: 22, bandThickness: bandThickness),
//         equals(LaneHit.ambiguous),
//       );
//     });
//
//     test('within 8dp of the boundary on either side is ambiguous', () {
//       expect(
//         resolveLane(offsetIntoBand: 14, bandThickness: bandThickness), // 22 - 8
//         equals(LaneHit.ambiguous),
//       );
//       expect(
//         resolveLane(offsetIntoBand: 30, bandThickness: bandThickness), // 22 + 8
//         equals(LaneHit.ambiguous),
//       );
//     });
//
//     test('just past the 8dp threshold resolves definitively', () {
//       expect(
//         resolveLane(offsetIntoBand: 13, bandThickness: bandThickness), // 22 - 9
//         equals(LaneHit.lane0),
//       );
//       expect(
//         resolveLane(offsetIntoBand: 31, bandThickness: bandThickness), // 22 + 9
//         equals(LaneHit.lane1),
//       );
//     });
//   });
//
//   group('angleToTime round-trips timeToAngle at every hour', () {
//     for (var hour = 0; hour < 24; hour++) {
//       test('hour $hour', () {
//         final forward = timeToAngle(hour: hour, minute: 0);
//         final back = angleToTime(forward.angle, forward.ring);
//         expect(back.hour, equals(hour));
//         expect(back.minute, equals(0));
//       });
//     }
//   });
//
//   group('minimum-sweep inflation does not affect hit results', () {
//     test('a pointer past the true end of a short block resolves to the next block', () {
//       // Block A: 09:00–09:05 (true sweep 2.5°, rendered inflated to 6° per
//       // doc4 §3, i.e. a visual end around 09:12). Block B starts exactly
//       // where A truly ends, at 09:05.
//       final a = ArcSegment(
//         blockId: 'a',
//         ring: Ring.am,
//         startAngle: 270.0, // 09:00
//         sweepAngle: 2.5,   // true 5-minute sweep, NOT the inflated 6°
//         lane: 0,
//         continuesFromPrevious: false,
//         continuesToNext: false,
//       );
//       final b = ArcSegment(
//         blockId: 'b',
//         ring: Ring.am,
//         startAngle: 272.5, // 09:05
//         sweepAngle: 5.0,   // 09:05–09:15
//         lane: 0,
//         continuesFromPrevious: false,
//         continuesToNext: false,
//       );
//
//       // 09:08 -> angle 274.0, which sits inside A's *inflated* visual span
//       // but well past A's true end and inside B's true span.
//       final hit = segmentAtAngle([a, b], Ring.am, 274.0);
//
//       expect(hit?.blockId, equals('b'));
//     });
//
//     test('a pointer just before the true end still resolves to the short block', () {
//       final a = ArcSegment(
//         blockId: 'a',
//         ring: Ring.am,
//         startAngle: 270.0,
//         sweepAngle: 2.5,
//         lane: 0,
//         continuesFromPrevious: false,
//         continuesToNext: false,
//       );
//
//       // 09:04 -> angle 272.0, still within A's true 2.5° sweep.
//       final hit = segmentAtAngle([a], Ring.am, 272.0);
//
//       expect(hit?.blockId, equals('a'));
//     });
//   });
// }

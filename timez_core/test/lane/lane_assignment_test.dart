// Spec: docs/03-domain-model.md §4.4, §10 "Lanes".
//
// Target API (not yet implemented — timez_core TDD workflow):
//   LaneAssignment assignLanes(List<ArcSegment> segments)
//   LaneAssignment { List<ArcSegment> segments; List<OverflowCluster> clusters; }
//   OverflowCluster { Ring ring; double startAngle; double sweepAngle; int hiddenCount; }
//
// Run independently per ring. Sort: startAngle asc, then longer sweepAngle
// first, then blockId — total and deterministic. Comparisons are half-open
// [start, end): touching segments do not overlap.

// import 'package:test/test.dart';
// import 'package:timez_core/timez_core.dart';

// ArcSegment _seg(String blockId, double start, double sweep) {
//   return ArcSegment(
//     blockId: blockId,
//     ring: Ring.pm,
//     startAngle: start,
//     sweepAngle: sweep,
//     lane: 0,
//     continuesFromPrevious: false,
//     continuesToNext: false,
//   );
// }
//
// void main() {
//   test('two overlapping segments get lanes 0 and 1', () {
//     final result = assignLanes([_seg('a', 0, 60), _seg('b', 30, 60)]);
//
//     final a = result.segments.firstWhere((s) => s.blockId == 'a');
//     final b = result.segments.firstWhere((s) => s.blockId == 'b');
//     expect({a.lane, b.lane}, equals({0, 1}));
//     expect(result.clusters, isEmpty);
//   });
//
//   test('three mutually overlapping segments produce one overflow cluster', () {
//     final result = assignLanes([
//       _seg('a', 0, 90),
//       _seg('b', 20, 80), // overlaps a
//       _seg('c', 40, 70), // overlaps both a and b
//     ]);
//
//     final a = result.segments.firstWhere((s) => s.blockId == 'a');
//     final b = result.segments.firstWhere((s) => s.blockId == 'b');
//     expect({a.lane, b.lane}, equals({0, 1}));
//     expect(result.segments.any((s) => s.blockId == 'c'), isFalse,
//         reason: 'segment that cannot get a free lane joins the overflow cluster instead');
//     expect(result.clusters, hasLength(1));
//     expect(result.clusters.single.hiddenCount, equals(1));
//   });
//
//   test('touching segments (end == next start) share lane 0', () {
//     final result = assignLanes([_seg('a', 0, 30), _seg('b', 30, 30)]);
//
//     final a = result.segments.firstWhere((s) => s.blockId == 'a');
//     final b = result.segments.firstWhere((s) => s.blockId == 'b');
//     expect(a.lane, equals(0));
//     expect(b.lane, equals(0));
//     expect(result.clusters, isEmpty);
//   });
//
//   test('lane assignment is identical across repeated runs with shuffled input', () {
//     final segments = [_seg('a', 0, 90), _seg('b', 20, 80), _seg('c', 40, 70)];
//
//     final baseline = assignLanes(segments);
//     final shuffledOrders = [
//       [segments[2], segments[0], segments[1]],
//       [segments[1], segments[2], segments[0]],
//       [segments[0], segments[2], segments[1]],
//     ];
//
//     for (final order in shuffledOrders) {
//       final result = assignLanes(order);
//       final baselineLanes = {
//         for (final s in baseline.segments) s.blockId: s.lane,
//       };
//       final resultLanes = {
//         for (final s in result.segments) s.blockId: s.lane,
//       };
//       expect(resultLanes, equals(baselineLanes));
//       expect(result.clusters.length, equals(baseline.clusters.length));
//     }
//   });
//
//   test('rings are assigned independently', () {
//     final amSeg = ArcSegment(
//       blockId: 'am1',
//       ring: Ring.am,
//       startAngle: 0,
//       sweepAngle: 60,
//       lane: 0,
//       continuesFromPrevious: false,
//       continuesToNext: false,
//     );
//     final pmSeg = _seg('pm1', 0, 60); // same angle, different ring
//
//     final result = assignLanes([amSeg, pmSeg]);
//
//     // Overlapping angles on different rings must not force each other into lane 1.
//     expect(result.segments.firstWhere((s) => s.blockId == 'am1').lane, equals(0));
//     expect(result.segments.firstWhere((s) => s.blockId == 'pm1').lane, equals(0));
//   });
// }

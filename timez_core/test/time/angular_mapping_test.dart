// Spec: docs/03-domain-model.md §4.1, §10 "Angles".
// Written ahead of `timeToAngle`/`Ring` (timez_core TDD workflow). Uncomment
// once lib/time/angular_mapping.dart lands.

// import 'package:test/test.dart';
// import 'package:timez_core/timez_core.dart';

// void main() {
//   group('timeToAngle', () {
//     final cases = [
//       (label: '00:00 → 0° AM',   hour: 0,  min: 0,  expectedAngle: 0.0,   expectedRing: Ring.am),
//       (label: '06:00 → 180° AM', hour: 6,  min: 0,  expectedAngle: 180.0, expectedRing: Ring.am),
//       (label: '11:59 → 359.5° AM', hour: 11, min: 59, expectedAngle: 359.5, expectedRing: Ring.am),
//       (label: '12:00 → 0° PM',   hour: 12, min: 0,  expectedAngle: 0.0,   expectedRing: Ring.pm),
//       (label: '18:00 → 180° PM', hour: 18, min: 0,  expectedAngle: 180.0, expectedRing: Ring.pm),
//       (label: '23:59 → 359.5° PM', hour: 23, min: 59, expectedAngle: 359.5, expectedRing: Ring.pm),
//     ];

//     for (final c in cases) {
//       test(c.label, () {
//         final result = timeToAngle(hour: c.hour, minute: c.min);
//         expect(result.angle, closeTo(c.expectedAngle, 0.001));
//         expect(result.ring, equals(c.expectedRing));
//       });
//     }
//   });
// }

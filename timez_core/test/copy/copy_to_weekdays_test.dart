// Spec: docs/03-domain-model.md §7, §10 "Copy".
//
// Target API (not yet implemented — timez_core TDD workflow):
//   List<Block> copyToWeekdays(Block block, Set<int> weekdays, int horizonWeeks)
//     weekdays use DateTime.monday..DateTime.sunday. horizonWeeks is clamped
//     to 26 internally — the cap is an engine invariant, not a UI hint.
//     Each copy: new UUID, same local wall-clock start/end, shares
//     copyGroupId, no link back to the original's lifecycle otherwise.
//
// All fixture times use America/New_York so the DST-preservation case can
// straddle the 2026-03-08 spring-forward transition (see time/day_window_test.dart).

// import 'package:test/test.dart';
// import 'package:timez_core/timez_core.dart';

// Block _block({
//   required DateTime startUtc,
//   required DateTime endUtc,
//   String timeZoneId = 'America/New_York',
// }) {
//   final now = DateTime.utc(2026, 1, 1);
//   return Block(
//     id: 'original',
//     title: 'Class',
//     notes: null,
//     startUtc: startUtc,
//     endUtc: endUtc,
//     timeZoneId: timeZoneId,
//     kind: BlockKind.event,
//     completedAt: null,
//     copyGroupId: null,
//     createdAt: now,
//     updatedAt: now,
//     deletedAt: null,
//     remoteId: null,
//     remoteEtag: null,
//     syncState: SyncState.localOnly,
//   );
// }
//
// void main() {
//   test('weekday selection is correct across a month boundary', () {
//     // 2026-03-30 is a Monday; horizon covers into April.
//     final block = _block(
//       startUtc: DateTime.utc(2026, 3, 30, 13, 0), // 09:00 EDT
//       endUtc: DateTime.utc(2026, 3, 30, 14, 0),   // 10:00 EDT
//     );
//
//     final copies = copyToWeekdays(block, {DateTime.monday}, 2);
//
//     expect(copies, isNotEmpty);
//     expect(copies.any((c) => c.startUtc == DateTime.utc(2026, 4, 6, 13, 0)), isTrue,
//         reason: 'the following Monday, 2026-04-06, crosses the March/April boundary');
//   });
//
//   test('local wall-clock time is preserved across a DST boundary', () {
//     // 2026-03-02 is a Monday, 09:00 EST (before spring-forward on 03-08).
//     final block = _block(
//       startUtc: DateTime.utc(2026, 3, 2, 14, 0), // 09:00 EST = 14:00 UTC
//       endUtc: DateTime.utc(2026, 3, 2, 15, 0),
//     );
//
//     final copies = copyToWeekdays(block, {DateTime.monday}, 2);
//     final nextMonday = copies.firstWhere(
//       (c) => c.startUtc == DateTime.utc(2026, 3, 9, 13, 0), // 09:00 EDT = 13:00 UTC
//       orElse: () => throw StateError('no copy found for 2026-03-09'),
//     );
//
//     // Same wall-clock 09:00, but a different UTC instant than a naive +7 days
//     // would produce (which would incorrectly stay at 14:00 UTC).
//     expect(nextMonday.startUtc, isNot(equals(DateTime.utc(2026, 3, 9, 14, 0))));
//     expect(nextMonday.endUtc.difference(nextMonday.startUtc), equals(const Duration(hours: 1)));
//   });
//
//   test('the horizon cap holds at 26 weeks even when a larger value is requested', () {
//     final block = _block(
//       startUtc: DateTime.utc(2026, 3, 2, 14, 0),
//       endUtc: DateTime.utc(2026, 3, 2, 15, 0),
//     );
//
//     final copies = copyToWeekdays(block, {DateTime.monday}, 52);
//
//     expect(copies.length, lessThanOrEqualTo(26));
//     for (final copy in copies) {
//       expect(
//         copy.startUtc.isBefore(block.startUtc.add(const Duration(days: 26 * 7 + 1))),
//         isTrue,
//       );
//     }
//   });
//
//   test('all copies share a copyGroupId and have distinct ids', () {
//     final block = _block(
//       startUtc: DateTime.utc(2026, 3, 2, 14, 0),
//       endUtc: DateTime.utc(2026, 3, 2, 15, 0),
//     );
//
//     final copies = copyToWeekdays(block, {DateTime.monday, DateTime.wednesday}, 3);
//
//     expect(copies, isNotEmpty);
//     final groupIds = copies.map((c) => c.copyGroupId).toSet();
//     expect(groupIds, hasLength(1));
//     expect(groupIds.single, isNotNull);
//
//     final ids = copies.map((c) => c.id).toSet();
//     expect(ids.length, equals(copies.length), reason: 'every copy must have a distinct id');
//     expect(ids.contains(block.id), isFalse, reason: 'copies are new rows, not the original');
//   });
//
//   test('multiple selected weekdays each produce their own copies', () {
//     final block = _block(
//       startUtc: DateTime.utc(2026, 3, 2, 14, 0), // Monday
//       endUtc: DateTime.utc(2026, 3, 2, 15, 0),
//     );
//
//     final copies = copyToWeekdays(block, {DateTime.monday, DateTime.wednesday}, 1);
//
//     final weekdaysProduced = copies
//         .map((c) => c.startUtc.toUtc().weekday)
//         .toSet();
//     expect(weekdaysProduced, containsAll(<int>{DateTime.monday, DateTime.wednesday}));
//   });
// }

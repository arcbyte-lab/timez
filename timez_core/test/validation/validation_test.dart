// Spec: docs/03-domain-model.md §8, §10 "Validation".
//
// Target API (not yet implemented — timez_core TDD workflow):
//   List<ValidationIssue> validate(Block block, {List<String> tagIds = const []})
//   ValidationIssue ::= titleRequired | titleTooLong | endBeforeStart
//                     | durationTooShort | durationTooLong | tooManyTags
//                     | invalidTimeZone
//   Never throws for user input. Overlap is deliberately not a rule (ADR-013).
//
// One positive (rule satisfied) and one negative (rule violated) case per row.

// import 'package:test/test.dart';
// import 'package:timez_core/timez_core.dart';

// Block _validBlock({
//   String title = 'Study session',
//   DateTime? startUtc,
//   DateTime? endUtc,
//   String timeZoneId = 'Asia/Jakarta',
// }) {
//   final now = DateTime.utc(2026, 1, 1);
//   return Block(
//     id: 'b1',
//     title: title,
//     notes: null,
//     startUtc: startUtc ?? DateTime.utc(2026, 3, 10, 3, 0),
//     endUtc: endUtc ?? DateTime.utc(2026, 3, 10, 4, 0), // 1h, well within bounds
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
//   test('a fully valid block has no issues', () {
//     expect(validate(_validBlock()), isEmpty);
//   });
//
//   group('title', () {
//     test('empty after trim -> titleRequired', () {
//       expect(validate(_validBlock(title: '   ')), contains(ValidationIssue.titleRequired));
//     });
//
//     test('non-empty after trim -> no titleRequired', () {
//       expect(validate(_validBlock(title: '  Class  ')), isNot(contains(ValidationIssue.titleRequired)));
//     });
//
//     test('over 120 chars -> titleTooLong', () {
//       expect(validate(_validBlock(title: 'a' * 121)), contains(ValidationIssue.titleTooLong));
//     });
//
//     test('exactly 120 chars -> no titleTooLong', () {
//       expect(validate(_validBlock(title: 'a' * 120)), isNot(contains(ValidationIssue.titleTooLong)));
//     });
//   });
//
//   group('interval', () {
//     test('end <= start -> endBeforeStart', () {
//       final start = DateTime.utc(2026, 3, 10, 4, 0);
//       expect(
//         validate(_validBlock(startUtc: start, endUtc: start)),
//         contains(ValidationIssue.endBeforeStart),
//       );
//       expect(
//         validate(_validBlock(startUtc: start, endUtc: start.subtract(const Duration(minutes: 10)))),
//         contains(ValidationIssue.endBeforeStart),
//       );
//     });
//
//     test('end strictly after start -> no endBeforeStart', () {
//       final start = DateTime.utc(2026, 3, 10, 4, 0);
//       expect(
//         validate(_validBlock(startUtc: start, endUtc: start.add(const Duration(minutes: 30)))),
//         isNot(contains(ValidationIssue.endBeforeStart)),
//       );
//     });
//
//     test('duration under 5 minutes -> durationTooShort', () {
//       final start = DateTime.utc(2026, 3, 10, 4, 0);
//       expect(
//         validate(_validBlock(startUtc: start, endUtc: start.add(const Duration(minutes: 4)))),
//         contains(ValidationIssue.durationTooShort),
//       );
//     });
//
//     test('duration exactly 5 minutes -> no durationTooShort', () {
//       final start = DateTime.utc(2026, 3, 10, 4, 0);
//       expect(
//         validate(_validBlock(startUtc: start, endUtc: start.add(const Duration(minutes: 5)))),
//         isNot(contains(ValidationIssue.durationTooShort)),
//       );
//     });
//
//     test('duration over 24 hours -> durationTooLong', () {
//       final start = DateTime.utc(2026, 3, 10, 4, 0);
//       expect(
//         validate(_validBlock(startUtc: start, endUtc: start.add(const Duration(hours: 24, minutes: 1)))),
//         contains(ValidationIssue.durationTooLong),
//       );
//     });
//
//     test('duration exactly 24 hours -> no durationTooLong', () {
//       final start = DateTime.utc(2026, 3, 10, 4, 0);
//       expect(
//         validate(_validBlock(startUtc: start, endUtc: start.add(const Duration(hours: 24)))),
//         isNot(contains(ValidationIssue.durationTooLong)),
//       );
//     });
//   });
//
//   group('tags', () {
//     test('more than 5 tags -> tooManyTags', () {
//       final tagIds = List.generate(6, (i) => 'tag$i');
//       expect(validate(_validBlock(), tagIds: tagIds), contains(ValidationIssue.tooManyTags));
//     });
//
//     test('exactly 5 tags -> no tooManyTags', () {
//       final tagIds = List.generate(5, (i) => 'tag$i');
//       expect(validate(_validBlock(), tagIds: tagIds), isNot(contains(ValidationIssue.tooManyTags)));
//     });
//
//     test('zero tags -> no tooManyTags', () {
//       expect(validate(_validBlock(), tagIds: const []), isNot(contains(ValidationIssue.tooManyTags)));
//     });
//   });
//
//   group('timezone', () {
//     test('unknown timeZoneId -> invalidTimeZone', () {
//       expect(
//         validate(_validBlock(timeZoneId: 'Not/AZone')),
//         contains(ValidationIssue.invalidTimeZone),
//       );
//     });
//
//     test('known IANA timeZoneId -> no invalidTimeZone', () {
//       expect(
//         validate(_validBlock(timeZoneId: 'Asia/Jakarta')),
//         isNot(contains(ValidationIssue.invalidTimeZone)),
//       );
//     });
//   });
//
//   test('overlap is not a validation rule (ADR-013) — validate never inspects other blocks', () {
//     // validate() takes a single Block; there is no signature that accepts
//     // sibling blocks to check against, by design.
//     expect(validate(_validBlock()), isA<List<ValidationIssue>>());
//   });
// }

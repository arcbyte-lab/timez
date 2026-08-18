// Spec: docs/03-domain-model.md §5, §10 "Color"; docs/04-radial-geometry.md
// §10 "Contrast" (computed in the engine alongside color derivation).
//
// Target API (not yet implemented — timez_core TDD workflow):
//   int deriveColor(List<Tag> attachedTags) -> ARGB int
//     Primary tag = attached tag with lowest sortOrder. Untagged (empty list)
//     returns `neutralColorSentinel`. Completion state is irrelevant here —
//     the engine returns color only, never opacity/strikethrough.
//   bool needsContrastOutline(int foregroundArgb, int backgroundArgb)
//     True when contrast ratio < 3:1.
//
// NOTE: lib/entities/tag.dart currently types sortOrder as String, which
// does not match doc3 §2.2 (int). These tests are written against the
// spec's typed Tag; fixing tag.dart's field types is part of the same pass.

// import 'package:test/test.dart';
// import 'package:timez_core/timez_core.dart';

// Tag _tag(String id, {required int sortOrder, required int colorArgb}) {
//   final now = DateTime.utc(2026, 1, 1);
//   return Tag(
//     id: id,
//     name: id,
//     colorArgb: colorArgb,
//     sortOrder: sortOrder,
//     createdAt: now,
//     updatedAt: now,
//     deletedAt: null,
//   );
// }
//
// void main() {
//   group('deriveColor', () {
//     test('lowest sortOrder wins as the primary tag', () {
//       final tags = [
//         _tag('work', sortOrder: 2, colorArgb: 0xFF00FF00),
//         _tag('focus', sortOrder: 0, colorArgb: 0xFFFF0000),
//         _tag('study', sortOrder: 1, colorArgb: 0xFF0000FF),
//       ];
//
//       expect(deriveColor(tags), equals(0xFFFF0000));
//     });
//
//     test('untagged block returns the neutral sentinel', () {
//       expect(deriveColor(const []), equals(neutralColorSentinel));
//     });
//
//     test('sort order changes propagate to the derived color', () {
//       final focus = _tag('focus', sortOrder: 0, colorArgb: 0xFFFF0000);
//       final work = _tag('work', sortOrder: 1, colorArgb: 0xFF00FF00);
//       expect(deriveColor([focus, work]), equals(0xFFFF0000));
//
//       // focus demoted below work.
//       final focusDemoted = _tag('focus', sortOrder: 2, colorArgb: 0xFFFF0000);
//       expect(deriveColor([focusDemoted, work]), equals(0xFF00FF00));
//     });
//
//     test('a single attached tag is always primary regardless of sortOrder value', () {
//       final onlyTag = _tag('gym', sortOrder: 5, colorArgb: 0xFF123456);
//       expect(deriveColor([onlyTag]), equals(0xFF123456));
//     });
//   });
//
//   group('needsContrastOutline', () {
//     test('low-contrast tag color against a light background needs an outline', () {
//       // Near-white on near-white: contrast ratio close to 1:1.
//       expect(needsContrastOutline(0xFFFDFDFD, 0xFFFFFFFF), isTrue);
//     });
//
//     test('high-contrast tag color against a light background needs no outline', () {
//       // Pure black on white: contrast ratio 21:1.
//       expect(needsContrastOutline(0xFF000000, 0xFFFFFFFF), isFalse);
//     });
//
//     test('mid-gray comfortably above the 3:1 threshold needs no outline', () {
//       // #767676 on white is ~4.5:1 by the WCAG relative-luminance formula,
//       // clearing the 3:1 threshold with room to spare.
//       expect(needsContrastOutline(0xFF767676, 0xFFFFFFFF), isFalse);
//     });
//   });
// }

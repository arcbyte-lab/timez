// Spec: docs/03-domain-model.md §4.2, §4.3, §10 "Segmentation".
//
// Target API (not yet implemented — timez_core TDD workflow):
//   List<ArcSegment> segmentsForDay(List<Block> blocks, DateTime localDate, String timeZoneId)
//   ArcSegment { blockId, ring, startAngle, sweepAngle, lane, continuesFromPrevious, continuesToNext }
//
// NOTE: lib/entities/block.dart currently types startUtc/endUtc/kind/etc as
// String, which does not match doc3 §2.1 (DateTime, BlockKind, ...). These
// tests are written against the spec's typed Block, so block.dart needs
// fixing before this file will even compile — that fix is part of the same
// TDD pass, not a bug in this test file.
//
// All fixture times use Asia/Jakarta (fixed UTC+7, no DST) so the day window
// math stays simple: for localDate 2026-03-10, dayStart = 2026-03-09T17:00Z,
// dayEnd = 2026-03-10T17:00Z (see time/day_window_test.dart).

import 'package:test/test.dart';
import 'package:timez_core/timez_core.dart';

const _zone = 'Asia/Jakarta';

Block _block({
  String id = 'b1',
  required DateTime startUtc,
  required DateTime endUtc,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Block(
    id: id,
    title: 'Test block',
    notes: null,
    startUtc: startUtc,
    endUtc: endUtc,
    timeZoneId: _zone,
    kind: BlockKind.event,
    completedAt: null,
    copyGroupId: null,
    createdAt: now,
    updatedAt: now,
    deletedAt: null,
    remoteId: null,
    remoteEtag: null,
    syncState: SyncState.localOnly,
  );
}

void main() {
  final localDate = DateTime(2026, 3, 10);

  test(
    'block exactly ending at noon: one AM segment, sweep ends at 360°, no split',
    () {
      final block = _block(
        startUtc: DateTime.utc(2026, 3, 10, 3, 0), // 10:00 local
        endUtc: DateTime.utc(2026, 3, 10, 5, 0), // 12:00 local
      );

      final segments = segmentsForDay([block], localDate, _zone);

      expect(segments, hasLength(1));
      expect(segments.single.ring, equals(Ring.am));
      expect(segments.single.startAngle, closeTo(300.0, 0.001));
      expect(segments.single.sweepAngle, closeTo(60.0, 0.001));
      expect(
        segments.single.startAngle + segments.single.sweepAngle,
        closeTo(360.0, 0.001),
      );
    },
  );

  test('block starting exactly at noon: one PM segment', () {
    final block = _block(
      startUtc: DateTime.utc(2026, 3, 10, 5, 0), // 12:00 local
      endUtc: DateTime.utc(2026, 3, 10, 6, 0), // 13:00 local
    );

    final segments = segmentsForDay([block], localDate, _zone);

    expect(segments, hasLength(1));
    expect(segments.single.ring, equals(Ring.pm));
    expect(segments.single.startAngle, closeTo(0.0, 0.001));
    expect(segments.single.sweepAngle, closeTo(30.0, 0.001));
  });

  test('24-hour block produces a full AM ring and a full PM ring', () {
    final block = _block(
      startUtc: DateTime.utc(2026, 3, 9, 17, 0), // 00:00 local, day 10
      endUtc: DateTime.utc(2026, 3, 10, 17, 0), // 00:00 local, day 11
    );

    final segments = segmentsForDay([block], localDate, _zone);

    expect(segments, hasLength(2));
    final am = segments.firstWhere((s) => s.ring == Ring.am);
    final pm = segments.firstWhere((s) => s.ring == Ring.pm);
    expect(am.startAngle, closeTo(0.0, 0.001));
    expect(am.sweepAngle, closeTo(360.0, 0.001));
    expect(pm.startAngle, closeTo(0.0, 0.001));
    expect(pm.sweepAngle, closeTo(360.0, 0.001));
    // True start/end of the block, not window-clipped.
    expect(am.continuesFromPrevious, isFalse);
    expect(pm.continuesToNext, isFalse);
    // Interior edge created by the noon split.
    expect(am.continuesToNext, isTrue);
    expect(pm.continuesFromPrevious, isTrue);
  });

  test('5-minute block renders a 2.5° sweep', () {
    final block = _block(
      startUtc: DateTime.utc(2026, 3, 10, 2, 0), // 09:00 local
      endUtc: DateTime.utc(2026, 3, 10, 2, 5), // 09:05 local
    );

    final segments = segmentsForDay([block], localDate, _zone);

    expect(segments, hasLength(1));
    expect(segments.single.startAngle, closeTo(270.0, 0.001));
    expect(segments.single.sweepAngle, closeTo(2.5, 0.001));
  });

  test('block wholly outside the window produces no segments', () {
    final block = _block(
      startUtc: DateTime.utc(2026, 3, 8, 1, 0), // 2026-03-08 08:00 local
      endUtc: DateTime.utc(2026, 3, 8, 2, 0), // 2026-03-08 09:00 local
    );

    final segments = segmentsForDay([block], localDate, _zone);

    expect(segments, isEmpty);
  });

  test(
    'a block spanning noon (not a window boundary) splits with interior continuation flags',
    () {
      final block = _block(
        startUtc: DateTime.utc(2026, 3, 10, 3, 0), // 10:00 local
        endUtc: DateTime.utc(2026, 3, 10, 7, 0), // 14:00 local
      );

      final segments = segmentsForDay([block], localDate, _zone);
      final am = segments.firstWhere((s) => s.ring == Ring.am);
      final pm = segments.firstWhere((s) => s.ring == Ring.pm);

      expect(am.continuesFromPrevious, isFalse); // true start, 10:00
      expect(am.continuesToNext, isTrue); // split at noon
      expect(pm.continuesFromPrevious, isTrue); // split at noon
      expect(pm.continuesToNext, isFalse); // true end, 14:00
    },
  );

  test(
    'a block spanning midnight produces correct segments on both adjacent days',
    () {
      final block = _block(
        id: 'midnight-block',
        startUtc: DateTime.utc(2026, 3, 9, 16, 0), // 2026-03-09 23:00 local
        endUtc: DateTime.utc(2026, 3, 9, 18, 0), // 2026-03-10 01:00 local
      );

      final day1 = segmentsForDay([block], DateTime(2026, 3, 9), _zone);
      final day2 = segmentsForDay([block], DateTime(2026, 3, 10), _zone);

      expect(day1, hasLength(1));
      expect(day1.single.ring, equals(Ring.pm));
      expect(day1.single.startAngle, closeTo(330.0, 0.001)); // 23:00 -> 330°
      expect(day1.single.sweepAngle, closeTo(30.0, 0.001)); // up to 24:00
      expect(day1.single.continuesFromPrevious, isFalse); // true start, 23:00
      expect(day1.single.continuesToNext, isTrue); // clipped at window end

      expect(day2, hasLength(1));
      expect(day2.single.ring, equals(Ring.am));
      expect(day2.single.startAngle, closeTo(0.0, 0.001));
      expect(day2.single.sweepAngle, closeTo(30.0, 0.001)); // up to 01:00
      expect(
        day2.single.continuesFromPrevious,
        isTrue,
      ); // clipped at window start
      expect(day2.single.continuesToNext, isFalse); // true end, 01:00

      // All four boundaries across the pair of segments are accounted for.
      expect([
        day1.single.continuesFromPrevious,
        day1.single.continuesToNext,
        day2.single.continuesFromPrevious,
        day2.single.continuesToNext,
      ], equals([false, true, true, false]));
    },
  );

  // A zero-length or inverted-interval block is rejected by validate() and
  // is never expected to reach segmentsForDay — see validation/validation_test.dart.
}

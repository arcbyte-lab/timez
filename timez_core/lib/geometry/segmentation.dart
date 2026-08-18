// Spec: docs/03-domain-model.md §4.2, §4.3, §10 "Segmentation".
//
// segmentsForDay(blocks, localDate, zone) turns each Block that intersects
// the local day window into at most two ArcSegments (one per ring the block
// touches). Lane assignment (§4.4) is a separate later stage — see
// lib/geometry/lane_assignment.dart — so every segment here carries lane 0.

import 'package:timez_core/entities/block.dart';
import 'package:timez_core/time/angular_mapping.dart';
import 'package:timez_core/time/day_window.dart';

/// The renderable unit. A block produces one or more of these per day.
class ArcSegment {
  /// The logical block this belongs to.
  final String blockId;

  final Ring ring;

  /// Degrees, 0–360, clockwise from top.
  final double startAngle;

  /// Degrees, positive, ≤ 360.
  final double sweepAngle;

  /// 0 or 1 — assigned by a later lane-assignment pass (§4.4).
  final int lane;

  /// True if the block began before this segment.
  final bool continuesFromPrevious;

  /// True if the block extends past this segment.
  final bool continuesToNext;

  const ArcSegment({
    required this.blockId,
    required this.ring,
    required this.startAngle,
    required this.sweepAngle,
    required this.lane,
    required this.continuesFromPrevious,
    required this.continuesToNext,
  });
}

class _Part {
  final Ring ring;
  final DateTime start;
  final DateTime end;

  const _Part(this.ring, this.start, this.end);
}

/// Converts [blocks] into the arc segments visible on [localDate] in
/// [timeZoneId].
///
/// 1. The local day window `[dayStart, dayEnd)` is computed via [DayWindow].
/// 2. Deleted blocks and blocks that don't intersect the window are dropped.
/// 3. Each remaining block's interval is clipped to the window; whichever
///    ends were clipped become `continuesFromPrevious`/`continuesToNext`.
/// 4. If the clipped interval crosses local noon it is split into an AM and
///    a PM part; the interior edge created by the split is always marked as
///    a continuation on both sides, regardless of window clipping.
/// 5. Each part becomes one [ArcSegment].
List<ArcSegment> segmentsForDay(
  List<Block> blocks,
  DateTime localDate,
  String timeZoneId,
) {
  final window = DayWindow(localDate, timeZoneId);
  final dayStart = window.startUtc();
  final dayEnd = window.endUtc();
  final noon = window.noonUtc();

  final segments = <ArcSegment>[];

  for (final block in blocks) {
    if (block.deletedAt != null) continue;
    if (!block.endUtc.isAfter(dayStart) || !block.startUtc.isBefore(dayEnd)) {
      continue; // no intersection with [dayStart, dayEnd)
    }

    final clippedStart =
        block.startUtc.isBefore(dayStart) ? dayStart : block.startUtc;
    final clippedEnd = block.endUtc.isAfter(dayEnd) ? dayEnd : block.endUtc;
    if (!clippedStart.isBefore(clippedEnd)) continue; // defensive

    final windowTruncatedStart =
        !clippedStart.isAtSameMomentAs(block.startUtc);
    final windowTruncatedEnd = !clippedEnd.isAtSameMomentAs(block.endUtc);

    final parts = <_Part>[];
    if (!clippedEnd.isAfter(noon)) {
      parts.add(_Part(Ring.am, clippedStart, clippedEnd));
    } else if (!clippedStart.isBefore(noon)) {
      parts.add(_Part(Ring.pm, clippedStart, clippedEnd));
    } else {
      parts.add(_Part(Ring.am, clippedStart, noon));
      parts.add(_Part(Ring.pm, noon, clippedEnd));
    }

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final isFirstPart = i == 0;
      final isLastPart = i == parts.length - 1;

      segments.add(
        ArcSegment(
          blockId: block.id,
          ring: part.ring,
          startAngle: _angleForInstant(part.start, timeZoneId),
          sweepAngle: _sweepDegrees(part.start, part.end),
          lane: 0,
          continuesFromPrevious: isFirstPart ? windowTruncatedStart : true,
          continuesToNext: isLastPart ? windowTruncatedEnd : true,
        ),
      );
    }
  }

  return segments;
}

double _angleForInstant(DateTime instant, String timeZoneId) {
  final local = toLocal(instant, timeZoneId);
  final minutesSinceMidnight = local.hour * 60 +
      local.minute +
      local.second / 60 +
      local.millisecond / 60000 +
      local.microsecond / 60000000;
  final minutesSinceHalfDayStart = minutesSinceMidnight % 720; // 12h = 720min
  return minutesSinceHalfDayStart * 0.5;
}

double _sweepDegrees(DateTime start, DateTime end) {
  final minutes = end.difference(start).inMicroseconds / 60000000;
  return minutes * 0.5;
}

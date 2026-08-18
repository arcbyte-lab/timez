// Spec: docs/03-domain-model.md §3, §10 "Time and day windows".

// Target API (not yet implemented — timez_core TDD workflow):
//   DayWindow dayWindow(DateTime localDate, String timeZoneId)
//     -> { startUtc, endUtc } UTC instants bounding local midnight to next
//        local midnight, resolved via the `timezone` package. Must not
//        assume 24h.
//   DateTime localDateForInstant(DateTime utcInstant, String timeZoneId)
//     -> the local calendar date (y/m/d, time-of-day zeroed) that instant
//        falls on in `timeZoneId`.

import 'package:test/test.dart';
import 'package:timez_core/timez_core.dart';

void main() {
  group('dayWindow', () {
    test('fixed-offset zone (Asia/Jakarta, UTC+7) is exactly 24h', () {
      final window = DayWindow(DateTime(2026, 3, 10), 'Asia/Jakarta');

      expect(window.startUtc(), equals(DateTime.utc(2026, 3, 9, 17, 0)));
      expect(window.endUtc(), equals(DateTime.utc(2026, 3, 10, 17, 0)));
      expect(
        window.endUtc().difference(window.startUtc()),
        equals(const Duration(hours: 24)),
      );
    });

    test('DST spring-forward day in America/New_York is 23h', () {
      // 2026-03-08: clocks jump 02:00 -> 03:00 EST(-5) -> EDT(-4).
      final window = DayWindow(DateTime(2026, 3, 8), 'America/New_York');

      expect(
        window.startUtc(),
        equals(DateTime.utc(2026, 3, 8, 5, 0)),
      ); // 00:00 EST
      expect(
        window.endUtc(),
        equals(DateTime.utc(2026, 3, 9, 4, 0)),
      ); // 00:00 EDT next day
      expect(
        window.endUtc().difference(window.startUtc()),
        equals(const Duration(hours: 23)),
      );
    });

    test('DST fall-back day in America/New_York is 25h', () {
      // 2026-11-01: clocks fall back 02:00 -> 01:00 EDT(-4) -> EST(-5).
      final window = DayWindow(DateTime(2026, 11, 1), 'America/New_York');

      expect(
        window.startUtc(),
        equals(DateTime.utc(2026, 11, 1, 4, 0)),
      ); // 00:00 EDT
      expect(
        window.endUtc(),
        equals(DateTime.utc(2026, 11, 2, 5, 0)),
      ); // 00:00 EST next day
      expect(
        window.endUtc().difference(window.startUtc()),
        equals(const Duration(hours: 25)),
      );
    });

    test('does not hardcode 24h for a DST-observing zone', () {
      final normalDay = DayWindow(DateTime(2026, 6, 15), 'America/New_York');
      final springForward = DayWindow(DateTime(2026, 3, 8), 'America/New_York');

      expect(
        normalDay.endUtc().difference(normalDay.startUtc()),
        equals(const Duration(hours: 24)),
      );
      expect(
        springForward.endUtc().difference(springForward.startUtc()),
        isNot(equals(const Duration(hours: 24))),
      );
    });
  });

  group('localDateForInstant', () {
    test('instant just before local midnight belongs to the earlier date', () {
      // 23:45 local on 2026-03-08 in Asia/Jakarta (UTC+7).
      final instant = DateTime.utc(2026, 3, 8, 16, 45);
      final localDate = localDateForInstant(instant, 'Asia/Jakarta');

      expect(localDate, equals(DateTime(2026, 3, 8)));
    });

    test('instant just after local midnight belongs to the later date', () {
      // 00:15 local on 2026-03-09 in Asia/Jakarta (UTC+7) — 30 minutes after
      // the previous case, straddling the same UTC hour boundary.
      final instant = DateTime.utc(2026, 3, 8, 17, 15);
      final localDate = localDateForInstant(instant, 'Asia/Jakarta');

      expect(localDate, equals(DateTime(2026, 3, 9)));
    });

    test('local date derivation is independent of the UTC calendar date', () {
      // 01:00 UTC on 2026-03-09 is still 2026-03-08 local in a UTC-negative zone.
      final instant = DateTime.utc(2026, 3, 9, 1, 0);
      final localDate = localDateForInstant(instant, 'America/New_York');

      expect(localDate, equals(DateTime(2026, 3, 8)));
    });
  });
}

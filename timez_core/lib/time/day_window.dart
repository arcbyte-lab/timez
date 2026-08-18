// Spec: docs/03-domain-model.md §3, §10 "Time and day windows".
//
// A local calendar day is not assumed to be 24 hours (ADR-011). Under DST it
// may be 23 or 25 hours; in a fixed-offset zone like Asia/Jakarta it happens
// to always be 24. The window is always derived from the IANA timezone
// database via the `timezone` package, never by adding a constant duration.

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

bool _tzInitialized = false;

/// Loads the IANA timezone database. Safe to call more than once — only the
/// first call has any effect.
void _ensureTimeZonesInitialized() {
  if (_tzInitialized) return;
  tz_data.initializeTimeZones();
  _tzInitialized = true;
}

/// The UTC instant window `[startUtc, endUtc)` spanning local midnight of
/// [localDate] to the next local midnight, in [timeZoneId].
///
/// [localDate]'s time-of-day component is ignored; only the calendar date
/// (year/month/day) is used.
class DayWindow {
  final DateTime localDate;
  final String timeZoneId;

  DayWindow(this.localDate, this.timeZoneId);

  /// The UTC instant of local midnight starting this day.
  DateTime startUtc() {
    _ensureTimeZonesInitialized();
    final location = tz.getLocation(timeZoneId);
    final start = tz.TZDateTime(
      location,
      localDate.year,
      localDate.month,
      localDate.day,
    );
    return start.toUtc();
  }

  /// The UTC instant of the next local midnight, ending this day.
  DateTime endUtc() {
    _ensureTimeZonesInitialized();
    final location = tz.getLocation(timeZoneId);
    final nextDate = localDate.add(const Duration(days: 1));
    final end = tz.TZDateTime(
      location,
      nextDate.year,
      nextDate.month,
      nextDate.day,
    );
    return end.toUtc();
  }

  /// The UTC instant of local noon on this day (used to split segments
  /// between the AM and PM rings — see docs/03-domain-model.md §4.3).
  DateTime noonUtc() {
    _ensureTimeZonesInitialized();
    final location = tz.getLocation(timeZoneId);
    final noon = tz.TZDateTime(
      location,
      localDate.year,
      localDate.month,
      localDate.day,
      12,
    );
    return noon.toUtc();
  }
}

/// The local calendar date (year/month/day, time-of-day zeroed) that
/// [utcInstant] falls on in [timeZoneId].
DateTime localDateForInstant(DateTime utcInstant, String timeZoneId) {
  final local = toLocal(utcInstant, timeZoneId);
  return DateTime(local.year, local.month, local.day);
}

/// The local wall-clock representation of [instant] in [timeZoneId].
tz.TZDateTime toLocal(DateTime instant, String timeZoneId) {
  _ensureTimeZonesInitialized();
  final location = tz.getLocation(timeZoneId);
  return tz.TZDateTime.from(instant, location);
}

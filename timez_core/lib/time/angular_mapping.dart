// Spec: docs/03-domain-model.md §4.1, §10 "Angles".
//
// The face spans 12 hours over 360° (30° per hour, 0.5° per minute). 0° is
// the 12 o'clock position, angles increase clockwise. The AM ring (inner)
// covers local 00:00–12:00; the PM ring (outer) covers 12:00–24:00. Both
// rings start at 0°, which is why midnight and noon sit at the same angular
// position on their respective rings.

enum Ring { am, pm }

/// The angular position of a local wall-clock time on its ring.
class AngleResult {
  final double angle;
  final Ring ring;

  const AngleResult(this.angle, this.ring);
}

/// Maps a local wall-clock [hour] (0–23) and [minute] (0–59) to its position
/// on the two-ring dial.
AngleResult timeToAngle({required int hour, required int minute}) {
  final ring = hour < 12 ? Ring.am : Ring.pm;
  final minutesSinceHalfDayStart = (hour % 12) * 60 + minute;
  final angle = minutesSinceHalfDayStart * 0.5;
  return AngleResult(angle, ring);
}

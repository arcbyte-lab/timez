// Spec: docs/03-domain-model.md §2.2.

/// A user-defined label attached to blocks (§2.3). Tags carry all domain
/// vocabulary — new categories are new tags, never new typed subsystems
/// (ADR-003).
class Tag {
  /// UUID v7.
  final String id;

  /// 1–24 chars after trim. Unique case-insensitively among non-deleted tags.
  final String name;

  /// 32-bit ARGB. The engine treats color as an opaque integer.
  final int colorArgb;

  /// Dense, zero-based. Determines the primary tag (§5).
  final int sortOrder;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Non-null is a tombstone.
  final DateTime? deletedAt;

  Tag({
    required this.id,
    required this.name,
    required this.colorArgb,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}

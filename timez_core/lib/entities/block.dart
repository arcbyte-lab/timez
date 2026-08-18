// Spec: docs/03-domain-model.md §2.1.

import 'package:timez_core/enums/block_kind.dart';
import 'package:timez_core/enums/sync_state.dart';

/// The single content primitive (ADR-003). A span of time with a title and
/// tags. `event`/`task` is a property of [kind], not a subtype.
class Block {
  /// UUID v7, generated locally at creation. Time-ordered, so it also sorts
  /// by creation. Never changes, never reused.
  final String id;

  /// 1–120 chars after trim. Required.
  final String title;

  /// Max 2000 chars.
  final String? notes;

  /// UTC instant. Always `isUtc == true`.
  final DateTime startUtc;

  /// UTC instant. Strictly greater than [startUtc].
  final DateTime endUtc;

  /// IANA identifier, e.g. `Asia/Jakarta`. The zone the block was authored in.
  final String timeZoneId;

  final BlockKind kind;

  /// UTC. Non-null means done. Meaningful for [BlockKind.task]; ignored for
  /// [BlockKind.event].
  final DateTime? completedAt;

  /// Set on blocks produced by one bulk-copy action (§7).
  final String? copyGroupId;

  /// UTC.
  final DateTime createdAt;

  /// UTC. Bumped on every mutation. Drives conflict resolution.
  final DateTime updatedAt;

  /// UTC. Non-null is a tombstone (§6.2).
  final DateTime? deletedAt;

  /// Google Calendar event id. Null until first successful push.
  final String? remoteId;

  /// Last etag seen from Google. Used for change detection.
  final String? remoteEtag;

  final SyncState syncState;

  Block({
    required this.id,
    required this.title,
    this.notes,
    required this.startUtc,
    required this.endUtc,
    required this.timeZoneId,
    required this.kind,
    this.completedAt,
    this.copyGroupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.remoteId,
    this.remoteEtag,
    required this.syncState,
  });
}

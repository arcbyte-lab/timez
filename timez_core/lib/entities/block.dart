import 'package:timez_core/enums/block_kind.dart';
import 'package:timez_core/enums/sync_state.dart';

class Block {
  final String id,
      title,
      notes,
      startUtc,
      endUtc,
      timeZoneId,
      completedAt,
      copyGroupId,
      createdAt,
      updatedAt,
      deletedAt,
      remoteId,
      remoteEtag;
  final BlockKind kind;
  final SyncState syncState;

  Block(
    this.id,
    this.title,
    this.notes,
    this.startUtc,
    this.endUtc,
    this.timeZoneId,
    this.kind,
    this.completedAt,
    this.copyGroupId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.remoteId,
    this.remoteEtag,
    this.syncState,
  );
}

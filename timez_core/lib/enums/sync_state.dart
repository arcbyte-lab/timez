enum SyncState {
  localOnly, // never pushed; no remoteId
  pendingCreate, // awaiting first push
  pendingUpdate, // local edit newer than last push
  pendingDelete, // tombstoned locally, deletion not yet pushed
  synced, // local and remote agree as of last sync
  conflicted, // divergent edits, awaiting resolution
}

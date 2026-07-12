/// Minimal, provider-agnostic view of a downloaded item's on-disk footprint
/// and watch state, decoupled from `SyncedItem` so the reclaim policy stays
/// pure and independently testable (#43).
class SyncedItemUsage {
  final String id;
  final int fileSizeBytes;
  final bool played;
  final DateTime? lastPlayed;

  const SyncedItemUsage({
    required this.id,
    required this.fileSizeBytes,
    required this.played,
    this.lastPlayed,
  }) : assert(fileSizeBytes >= 0, 'fileSizeBytes must not be negative');
}

class SmartDownloadPolicyResult {
  final List<String> reclaimItemIds;
  final int bytesUsed;
  final int bytesFreed;

  const SmartDownloadPolicyResult({
    required this.reclaimItemIds,
    required this.bytesUsed,
    required this.bytesFreed,
  });

  int get bytesUsedAfterReclaim => bytesUsed - bytesFreed;
}

/// Decides which already-downloaded items should be auto-reclaimed to stay
/// within a global storage budget.
///
/// Conservative by design (per the epic's "auto-delete must be conservative"
/// requirement): only watched items are ever reclaim candidates, oldest
/// watched first (LRU by `lastPlayed`). Items without a playback timestamp are
/// reclaimed only after items with known history, and equal timestamps are
/// ordered by ID for deterministic results. Unwatched items are never touched,
/// even if the budget stays exceeded after reclaiming everything watched —
/// that case is surfaced via [SmartDownloadPolicyResult.bytesUsedAfterReclaim]
/// rather than solved by evicting something the user hasn't seen yet.
class SmartDownloadPolicy {
  final int? storageBudgetBytes;

  const SmartDownloadPolicy({this.storageBudgetBytes})
      : assert(storageBudgetBytes == null || storageBudgetBytes >= 0, 'storageBudgetBytes must not be negative');

  SmartDownloadPolicyResult evaluate(List<SyncedItemUsage> items) {
    final bytesUsed = items.fold<int>(0, (sum, item) => sum + item.fileSizeBytes);

    final budget = storageBudgetBytes;
    if (budget == null || bytesUsed <= budget) {
      return SmartDownloadPolicyResult(reclaimItemIds: const [], bytesUsed: bytesUsed, bytesFreed: 0);
    }

    final reclaimCandidates = items.where((item) => item.played).toList()
      ..sort((a, b) {
        final aDate = a.lastPlayed;
        final bDate = b.lastPlayed;
        if (aDate == null && bDate == null) return a.id.compareTo(b.id);
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        final dateComparison = aDate.compareTo(bDate);
        return dateComparison != 0 ? dateComparison : a.id.compareTo(b.id);
      });

    final reclaimIds = <String>[];
    var freed = 0;
    for (final candidate in reclaimCandidates) {
      if (bytesUsed - freed <= budget) break;
      reclaimIds.add(candidate.id);
      freed += candidate.fileSizeBytes;
    }

    return SmartDownloadPolicyResult(reclaimItemIds: reclaimIds, bytesUsed: bytesUsed, bytesFreed: freed);
  }
}

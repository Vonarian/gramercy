class PurgeResult {
  final bool success;
  final int deletedCount;
  final String? backupPath;
  final String? errorMessage;

  const PurgeResult({
    required this.success,
    this.deletedCount = 0,
    this.backupPath,
    this.errorMessage,
  });
}

class FreshStringsStatus {
  final bool hasFiles;
  final int fileCount;
  final List<String> keyFilesFound;

  const FreshStringsStatus({
    required this.hasFiles,
    required this.fileCount,
    this.keyFilesFound = const [],
  });
}

class RebuildSummary {
  final bool success;
  final int filesReloaded;
  final int overridesApplied;
  final String? errorMessage;

  const RebuildSummary({
    required this.success,
    this.filesReloaded = 0,
    this.overridesApplied = 0,
    this.errorMessage,
  });
}

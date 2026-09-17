class LocalizationEntry {
  final String key;
  final String value;
  final String baseValue;
  final bool isOverridden;

  const LocalizationEntry({
    required this.key,
    required this.value,
    required this.baseValue,
    required this.isOverridden,
  });
}

enum FilterMode {
  all,
  overriddenOnly,
  unmodifiedOnly,
}

enum ExportStatus {
  idle,
  inProgress,
  success,
  error,
}

class ExportState {
  final ExportStatus status;
  final String? message;

  const ExportState({
    this.status = ExportStatus.idle,
    this.message,
  });
}

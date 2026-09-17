class LocalizationEntry {
  final String key;
  final String value;
  final String baseValue;
  final bool isOverridden;
  final String lowerKey;
  final String lowerValue;

  LocalizationEntry({
    required this.key,
    required this.value,
    required this.baseValue,
    required this.isOverridden,
    String? lowerKey,
    String? lowerValue,
  }) : lowerKey = lowerKey ?? key.toLowerCase(),
       lowerValue = lowerValue ?? value.toLowerCase();

  const LocalizationEntry.raw({
    required this.key,
    required this.value,
    required this.baseValue,
    required this.isOverridden,
    required this.lowerKey,
    required this.lowerValue,
  });

  bool matchesQuery(String lowerQuery) {
    if (lowerQuery.isEmpty) return true;
    return lowerKey.contains(lowerQuery) || lowerValue.contains(lowerQuery);
  }
}

enum FilterMode { all, overriddenOnly, unmodifiedOnly }

enum ExportStatus { idle, inProgress, success, error }

class ExportState {
  final ExportStatus status;
  final String? message;

  const ExportState({this.status = ExportStatus.idle, this.message});
}

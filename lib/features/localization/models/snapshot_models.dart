import 'package:path/path.dart' as p;

class SnapshotMetadata {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? description;
  final int totalOverrides;
  final String filePath;

  const SnapshotMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description,
    required this.totalOverrides,
    required this.filePath,
  });

  factory SnapshotMetadata.fromJson(
    Map<String, dynamic> json,
    String filePath,
  ) {
    final rawDate = json['createdAt'] ?? json['exportedAt'];
    final createdAt = rawDate is String
        ? DateTime.parse(rawDate)
        : DateTime.now().toUtc();
    final overridesList = json['overrides'] as List<dynamic>?;
    final total =
        (json['totalOverrides'] as num?)?.toInt() ?? overridesList?.length ?? 0;

    return SnapshotMetadata(
      id: json['id'] as String? ?? p.basenameWithoutExtension(filePath),
      name: json['name'] as String? ?? json['label'] as String? ?? 'Snapshot',
      createdAt: createdAt,
      description: json['description'] as String?,
      totalOverrides: total,
      filePath: filePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      if (description != null) 'description': description,
      'totalOverrides': totalOverrides,
      'filePath': filePath,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnapshotMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          createdAt == other.createdAt &&
          description == other.description &&
          totalOverrides == other.totalOverrides &&
          filePath == other.filePath;

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, description, totalOverrides, filePath);

  @override
  String toString() =>
      'SnapshotMetadata(id: $id, name: $name, totalOverrides: $totalOverrides)';
}

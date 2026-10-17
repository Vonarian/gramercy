import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('dbProvider must be overridden in ProviderScope');
});

/// Live count of overrides for one file (drift watch query, cached per
/// family so widget rebuilds re-subscribe nothing).
final fileOverridesCountProvider = StreamProvider.family<int, String>((
  ref,
  fileName,
) {
  return ref.watch(dbProvider).watchOverridesCountForFile(fileName);
});

/// Live count of overrides across all files.
final totalOverridesCountProvider = StreamProvider<int>((ref) {
  return ref.watch(dbProvider).watchTotalOverridesCount();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('dbProvider must be overridden in ProviderScope');
});

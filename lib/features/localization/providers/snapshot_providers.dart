import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/features/localization/providers/db_provider.dart';
import 'package:gramercy/features/localization/services/snapshot_service.dart';
import 'package:path/path.dart' as p;

export 'package:gramercy/features/localization/services/snapshot_service.dart';

Directory _defaultSnapshotDirectory() {
  final home = Platform.environment['HOME'] ?? '';
  var base = Platform.environment['APPDATA'] ?? '';
  if (!Platform.isWindows && home.isNotEmpty) {
    base = Platform.isMacOS
        ? '$home/Library/Application Support'
        : '$home/.local/share';
  }
  final root = base.isEmpty ? Directory.systemTemp.path : base;
  return Directory(p.join(root, 'gramercy', 'snapshots'));
}

final snapshotServiceProvider = Provider<SnapshotService>((ref) {
  return SnapshotService(
    db: ref.watch(dbProvider),
    baseDir: _defaultSnapshotDirectory(),
  );
});

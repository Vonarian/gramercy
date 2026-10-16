import 'dart:io';

import 'package:path/path.dart' as p;

/// Pure look-up of the per-user app-support root, mirroring the snapshot
/// vault mechanism exactly (`_defaultSnapshotDirectory` in
/// localization_providers.dart): APPDATA on Windows; home-derived dirs on
/// macOS/Linux desktops.
String appSupportRoot({
  required bool isWindows,
  required bool isMacos,
  String home = '',
  String appData = '',
}) {
  var base = appData;
  if (!isWindows && home.isNotEmpty) {
    base = isMacos ? '$home/Library/Application Support' : '$home/.local/share';
  }
  return base;
}

/// Fixed log file path inside the app-support dir (sibling of snapshots/).
/// Returns null when the platform lookup fails; never throws.
String? resolveLogFilePath() {
  try {
    final root = appSupportRoot(
      isWindows: Platform.isWindows,
      isMacos: Platform.isMacOS,
      home: Platform.environment['HOME'] ?? '',
      appData: Platform.environment['APPDATA'] ?? '',
    );
    final support = root.isEmpty ? Directory.systemTemp.path : root;
    return p.join(support, 'gramercy', 'gramercy.log');
  } catch (_) {
    return null;
  }
}

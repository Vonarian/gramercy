import 'dart:io';

class ConfigBlkStatus {
  final bool exists;
  final bool isLocalizationEnabled;
  final String filePath;

  const ConfigBlkStatus({
    required this.exists,
    required this.isLocalizationEnabled,
    required this.filePath,
  });
}

/// Reads config.blk and verifies whether testLocalization:b=yes is enabled inside debug { ... }
ConfigBlkStatus checkConfigBlkStatusWorker(String configBlkPath) {
  final file = File(configBlkPath);
  if (!file.existsSync()) {
    return ConfigBlkStatus(
      exists: false,
      isLocalizationEnabled: false,
      filePath: configBlkPath,
    );
  }

  final content = file.readAsStringSync();
  final debugBlockRegex = RegExp(r'debug\s*\{([^}]*)\}', multiLine: true);
  final match = debugBlockRegex.firstMatch(content);

  if (match != null) {
    final blockContent = match.group(1) ?? '';
    final enabled = RegExp(r'testLocalization:b\s*=\s*yes')
        .hasMatch(blockContent);
    return ConfigBlkStatus(
      exists: true,
      isLocalizationEnabled: enabled,
      filePath: configBlkPath,
    );
  }

  return ConfigBlkStatus(
    exists: true,
    isLocalizationEnabled: false,
    filePath: configBlkPath,
  );
}

/// Writes [content] into [configBlkPath] atomically: the copy goes to a
/// `<path>.tmp` sibling first (flushed), then a single rename swaps it over
/// the target, so a crash mid-write can never leave a half-written
/// config.blk (finding F1-5).
///
/// - [File.rename] replaces an existing file target on Windows (verified
///   empirically on Dart 3.13.3 / Windows: the old target content is
///   replaced and the tmp is consumed), so the live file is never deleted
///   first and the swap is a single same-directory metadata step with no
///   delete-then-rename residual window.
/// - A `<path>.tmp` orphan left by a hard crash can occur only between the
///   flushed write and the rename; the next patch truncates and reclaims
///   it via [File.writeAsString]'s default write mode.
/// - The tmp never survives success or failure: the finally removes it.
/// - The target's directory must already exist (the tmp lives in it).
Future<void> writeConfigBlkAtomic(String configBlkPath, String content) async {
  final tmp = File('$configBlkPath.tmp');
  try {
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(configBlkPath);
  } finally {
    if (await tmp.exists()) {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }
}

/// Captures the pristine game file once, before Gramercy's first patch.
///
/// Never refresh `.bak` when the live file looks "newer" (F1-5 review note):
/// after Gramercy's own patch the live config.blk is ALWAYS newer than the
/// .bak, so an mtime-based refresh rule would clobber the pre-Gramercy
/// restore copy with Gramercy-modified output. A stale .bak (the game
/// rewriting config.blk itself) is intentionally accepted so the original
/// stays restorable.
Future<void> _captureFirstBak(File file) async {
  final backupFile = File('${file.path}.bak');
  if (await backupFile.exists()) {
    return;
  }
  try {
    await file.copy(backupFile.path);
  } catch (_) {}
}

/// Injects or activates testLocalization:b=yes inside config.blk
Future<bool> patchConfigBlkWorker(String configBlkPath) async {
  final file = File(configBlkPath);
  if (!await file.exists()) {
    return false;
  }

  final content = await file.readAsString();
  await _captureFirstBak(file);
  final match = RegExp(
    r'debug\s*\{([^}]*)\}',
    multiLine: true,
  ).firstMatch(content);
  if (match == null) {
    await writeConfigBlkAtomic(configBlkPath, _withAppendedDebugBlock(content));
    return true;
  }

  final blockContent = match.group(1) ?? '';
  if (RegExp(r'testLocalization:b\s*=\s*no').hasMatch(blockContent)) {
    final swappedBlock = blockContent.replaceAll(
      RegExp(r'testLocalization:b\s*=\s*no'),
      'testLocalization:b=yes',
    );
    await _writeDebugBlock(configBlkPath, content, match, swappedBlock);
  } else if (!RegExp(r'testLocalization:b\s*=\s*yes').hasMatch(blockContent)) {
    await _writeDebugBlock(
      configBlkPath,
      content,
      match,
      '\n  testLocalization:b=yes$blockContent',
    );
  }
  return true;
}

Future<void> _writeDebugBlock(
  String configBlkPath,
  String content,
  RegExpMatch match,
  String newBlock,
) async {
  final updatedContent = content.replaceRange(
    match.start,
    match.end,
    'debug{$newBlock}',
  );
  await writeConfigBlkAtomic(configBlkPath, updatedContent);
}

String _withAppendedDebugBlock(String content) =>
    '$content\n\ndebug {\n  testLocalization:b=yes\n}\n';

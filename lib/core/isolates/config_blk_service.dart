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
    final enabled =
        RegExp(r'testLocalization:b\s*=\s*yes').hasMatch(blockContent);
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

/// Injects or activates testLocalization:b=yes inside config.blk
Future<bool> patchConfigBlkWorker(String configBlkPath) async {
  final file = File(configBlkPath);
  if (!await file.exists()) {
    return false;
  }

  final content = await file.readAsString();
  final backupFile = File('$configBlkPath.bak');
  if (!await backupFile.exists()) {
    try {
      await file.copy(backupFile.path);
    } catch (_) {}
  }

  final debugBlockRegex = RegExp(r'debug\s*\{([^}]*)\}', multiLine: true);
  final match = debugBlockRegex.firstMatch(content);

  String updatedContent;
  if (match != null) {
    final blockContent = match.group(1) ?? '';
    if (RegExp(r'testLocalization:b\s*=\s*no').hasMatch(blockContent)) {
      final updatedBlock = blockContent.replaceAll(
        RegExp(r'testLocalization:b\s*=\s*no'),
        'testLocalization:b=yes',
      );
      updatedContent = content.replaceRange(
        match.start,
        match.end,
        'debug{$updatedBlock}',
      );
    } else if (!RegExp(r'testLocalization:b\s*=\s*yes').hasMatch(blockContent)) {
      final updatedBlock = '\n  testLocalization:b=yes$blockContent';
      updatedContent = content.replaceRange(
        match.start,
        match.end,
        'debug{$updatedBlock}',
      );
    } else {
      return true;
    }
  } else {
    updatedContent = '$content\n\ndebug {\n  testLocalization:b=yes\n}\n';
  }

  await file.writeAsString(updatedContent, flush: true);
  return true;
}

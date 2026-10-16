import 'dart:io';

import 'package:gramercy/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;

bool _isLink(FileSystemEntity entity) =>
    FileSystemEntity.typeSync(entity.path, followLinks: false) ==
    FileSystemEntityType.link;

class BackupService {
  const BackupService();

  Future<String?> backupLocalizationFolder(String wtPath) async {
    if (wtPath.isEmpty) return null;
    final langDir = Directory(p.join(wtPath, 'lang'));
    if (!await langDir.exists()) return null;

    final filesToBackup = <File>[];
    var skippedLinks = 0;
    await for (final entity in langDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (_isLink(entity)) {
        skippedLinks++;
        continue;
      }
      filesToBackup.add(entity);
    }
    if (skippedLinks > 0) {
      AppLogger.instance.i(
        'Skipped $skippedLinks symlinked file(s) in ${langDir.path}',
        tag: 'BACKUP',
      );
    }

    if (filesToBackup.isEmpty) return null;

    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${pad(now.month)}${pad(now.day)}_${pad(now.hour)}${pad(now.minute)}${pad(now.second)}';
    final backupDir = Directory(
      p.join(wtPath, 'lang_backups', 'backup_$stamp'),
    );
    await backupDir.create(recursive: true);

    for (final file in filesToBackup) {
      final dest = p.join(backupDir.path, p.basename(file.path));
      await file.copy(dest);
    }

    AppLogger.instance.i(
      'Backed up ${filesToBackup.length} files to ${backupDir.path}',
      tag: 'BACKUP',
    );
    return backupDir.path;
  }
}

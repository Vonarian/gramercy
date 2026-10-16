import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/features/localization/services/backup_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  final service = const BackupService();

  setUp(() {
    AppLogger.instance
      ..configure(
        minLevel: LogLevel.info,
        consoleOutput: false,
        fileOutput: false,
      )
      ..clear();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    AppLogger.instance.clear();
  });

  /// Builds wt/lang with [realCount] real csv files and one symlink
  /// lang/link.csv -> wt/secret.txt containing [secretMarker].
  Future<Directory> buildSandbox({
    required String secretMarker,
    int realCount = 1,
  }) async {
    final wt = Directory(p.join(tempDir.path, 'wt'));
    final lang = Directory(p.join(wt.path, 'lang'));
    await lang.create(recursive: true);
    for (var i = 0; i < realCount; i++) {
      await File(p.join(lang.path, 'real_fail_$i.csv'))
          .writeAsString('REAL-$i');
    }
    final secret = File(p.join(wt.path, 'secret.txt'));
    await secret.writeAsString(secretMarker);
    await Link(p.join(lang.path, 'link.csv')).create(secret.path);
    return wt;
  }

  group('BackupService symlink refusal (F1-2a)', () {
    test(
      'backup dir contains only real files, never symlink target content',
      () async {
        tempDir = await Directory.systemTemp.createTemp('wt_backup_sec_');
        const marker = 'SECRET-MARKER-xxxx';
        final wt = await buildSandbox(secretMarker: marker);

        final backupPath = await service.backupLocalizationFolder(wt.path);

        expect(backupPath, isNotNull);
        final backupDir = Directory(backupPath!);
        expect(backupDir.existsSync(), isTrue);

        final backedUpNames = backupDir
            .listSync()
            .map((e) => p.basename(e.path))
            .toSet();
        // RED pre-fix: link.csv (copy of the target) leaks into the backup.
        expect(backedUpNames, {'real_fail_0.csv'});

        final real = File(p.join(backupDir.path, 'real_fail_0.csv'));
        expect(real.readAsStringSync(), 'REAL-0');

        // No artifact inside the backup may carry the secret payload.
        final leaked = backupDir
            .listSync()
            .whereType<File>()
            .where((f) => f.readAsStringSync().contains(marker))
            .toList();
        expect(leaked, isEmpty);
      },
    );

    test('skipped symlinks are counted and reported at info level', () async {
      tempDir = await Directory.systemTemp.createTemp('wt_backup_sec_');
      final wt = await buildSandbox(
        secretMarker: 'SECRET-MARKER-xxxx',
        realCount: 2,
      );

      await service.backupLocalizationFolder(wt.path);

      final skippedLog = AppLogger.instance.entries.any(
        (e) => e.tag == 'BACKUP' && e.message.contains('Skipped 1 symlink'),
      );
      expect(skippedLog, isTrue);
    });

    test('returns null when lang contains only symlinks', () async {
      tempDir = await Directory.systemTemp.createTemp('wt_backup_sec_');
      final wt = await buildSandbox(
        secretMarker: 'SECRET-MARKER-xxxx',
        realCount: 0,
      );
      final langBackups = Directory(p.join(wt.path, 'lang_backups'));

      final backupPath = await service.backupLocalizationFolder(wt.path);

      expect(backupPath, isNull);
      expect(langBackups.existsSync(), isFalse);
    });

    test('returns null for an empty lang dir (existing semantics)', () async {
      tempDir = await Directory.systemTemp.createTemp('wt_backup_sec_');
      final wt = Directory(p.join(tempDir.path, 'wt'));
      await Directory(p.join(wt.path, 'lang')).create(recursive: true);

      final backupPath = await service.backupLocalizationFolder(wt.path);

      expect(backupPath, isNull);
    });

    test('returns null when lang dir is missing', () async {
      tempDir = await Directory.systemTemp.createTemp('wt_backup_sec_');
      final wt = Directory(p.join(tempDir.path, 'wt'));

      expect(await service.backupLocalizationFolder(wt.path), isNull);
    });
  });
}

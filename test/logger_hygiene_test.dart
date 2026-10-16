import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/logging/log_path.dart';
import 'package:path/path.dart' as p;

void main() {
  group('DRIFT log hygiene (F2-5)', () {
    late AppDatabase db;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wt_logger_hyg_');
      db = AppDatabase(NativeDatabase.memory());
      AppLogger.instance
        ..configure(
          minLevel: LogLevel.verbose,
          consoleOutput: false,
          fileOutput: false,
        )
        ..clear();
    });

    tearDown(() async {
      await db.close();
      AppLogger.instance.clear();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'Saved override log line carries no raw CR/LF from override fields',
      () async {
        await db.saveOverride(
          LocalizationsOverridesCompanion.insert(
            fileName: 'units.csv\n',
            stringKey: 'forged_key\n[ERR ] bogus crash line\n',
            customValue: 'value\r\nwith\rCR and LF',
          ),
        );

        final saved = AppLogger.instance.entries.where(
          (e) => e.tag == 'DRIFT' && e.message.startsWith('Saved override'),
        );
        expect(saved, hasLength(1));

        final line = saved.single.message;

        // RED pre-fix: raw newlines land in the log message.
        expect(line.contains('\n'), isFalse);
        expect(line.contains('\r'), isFalse);

        // The recorded message still carries the field content, folded
        // (trailing spaces are the sanitised newline positions).
        expect(line, contains('[units.csv ]'));
        expect(line, contains('forged_key [ERR ] bogus crash line'));
        expect(line, contains('"value with CR and LF"'));
      },
    );

    test('AppLogger.scrub folds every CR/LF variant into spaces', () {
      // Spec case: CRLF + newline + forged-level bracket stays one line.
      expect(AppLogger.scrub('a\r\nb [ERR]\n'), 'a b [ERR] ');
      expect(AppLogger.scrub('x\ny'), 'x y');
      expect(AppLogger.scrub('p\rq'), 'p q');
      expect(AppLogger.scrub('clean'), 'clean');
      expect(AppLogger.scrub(''), '');
    });
  });

  group('File logging preference actually writes (F1-7)', () {
    late Directory tempDir;
    late Directory logDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wt_logger_hyg_');
      logDir = Directory(p.join(tempDir.path, 'gramercy'));
      await logDir.create(recursive: true);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('configured logger appends formatted entries to the log file', () {
      final logFile = p.join(logDir.path, 'gramercy.log');
      final logger = AppLogger(consoleOutput: false);
      logger.configure(fileOutput: true, logFilePath: logFile);

      logger.i('file logging smoke entry');

      final file = File(logFile);
      expect(file.existsSync(), isTrue, reason: 'log file must be created');
      expect(file.readAsStringSync(), contains('file logging smoke entry'));
      logger.dispose();
    });

    test('main.dart wires logFilePath from the app-support resolver', () {
      // Structural pin (disclosed as string-level, not behavioral):
      // main's configure call must pass logFilePath.
      final src = File('lib/main.dart').readAsStringSync();
      expect(src, contains('resolveLogFilePath()'));
      expect(src, contains('logFilePath: logFilePath'));
    });
  });

  group('resolveLogFilePath mechanism (F1-7)', () {
    test('mirrors the snapshot vault root resolution exactly', () {
      // Windows: APPDATA wins even when HOME is set.
      expect(
        appSupportRoot(
          isWindows: true,
          isMacos: false,
          home: '/home/user',
          appData: r'C:\Users\user\AppData',
        ),
        r'C:\Users\user\AppData',
      );
      // macOS: Library/Application Support derived from HOME.
      expect(
        appSupportRoot(
          isWindows: false,
          isMacos: true,
          home: '/Users/user',
          appData: 'ignored',
        ),
        '/Users/user/Library/Application Support',
      );
      // Linux: XDG data home derived from HOME.
      expect(
        appSupportRoot(
          isWindows: false,
          isMacos: false,
          home: '/home/user',
          appData: 'ignored',
        ),
        '/home/user/.local/share',
      );
      // No environment clues: empty root (caller falls back to systemTemp).
      expect(appSupportRoot(isWindows: true, isMacos: false), '');
    });

    test('places gramercy.log inside the gramercy support folder', () {
      final path = resolveLogFilePath();
      expect(path, isNotNull);
      expect(p.basename(path!), 'gramercy.log');
      expect(p.basename(p.dirname(path)), 'gramercy');
    });
  });
}

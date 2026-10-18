import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/features/localization/services/game_process_service.dart';

ProcessResult _res(int exitCode, String stdout) =>
    ProcessResult(0, exitCode, stdout, '');

void main() {
  setUp(() {
    AppLogger.instance
      ..configure(minLevel: LogLevel.verbose, fileOutput: false)
      ..clear();
  });

  group('GameProcessService probe precision (audit B3)', () {
    test('windows runs tasklist with an exact IMAGENAME filter', () {
      final cmd = GameProcessServiceProbeCommand.windows();
      expect(cmd.$1, 'tasklist');
      expect(cmd.$2, ['/FI', 'IMAGENAME eq aces.exe', '/NH']);
    });

    test('posix probes the exact binary name, not a substring', () {
      // RED before the fix: pgrep -f aces matched any command line
      // containing "aces" (e.g. editor sessions open on aces_notes.txt).
      final cmd = GameProcessServiceProbeCommand.posix();
      expect(cmd.$1, 'pgrep');
      expect(cmd.$2, ['-x', 'aces']);
    });

    test('no loose launcher.exe fallback probe remains', () {
      // The launcher.exe heuristic matched ANY game's launcher and gated the
      // destructive purge button on a false positive. Only aces presence
      // matters for the running-game check.
      expect(
        GameProcessServiceProbeCommand.windows().$2.join(' '),
        isNot(contains('launcher.exe')),
      );
    });

    test('tasklistParser treats a listed aces.exe as running', () {
      const output = '''
========================= ==================================
Image Name                PID Session Name
========================= ==================================
aces.exe                  1234 Console
''';
      expect(GameProcessService.tasklistIsGameRunning(output), isTrue);
    });

    test('tasklistParser reports not-running on INFO header only', () {
      const output = '''
INFO: No tasks are running which match the specified criteria.
''';
      expect(GameProcessService.tasklistIsGameRunning(output), isFalse);
    });
  });

  group('GameProcessService runtime behavior', () {
    test('posix: exit code zero means the game is running', () async {
      final calls = <(String, List<String>)>[];
      final service = GameProcessService(
        runProcess: (exe, args) async {
          calls.add((exe, args));
          return _res(0, 'process matches');
        },
      );

      expect(await service.isGameRunning(), isTrue);
      expect(calls.single.$1, 'pgrep');
      expect(calls.single.$2, ['-x', 'aces']);
    });

    test('posix: non-zero exit code means the game is not running', () async {
      final service = GameProcessService(
        runProcess: (_, _) async => _res(1, ''),
      );

      expect(await service.isGameRunning(), isFalse);
    });

    test('a probe failure degrades to not-running with a warning', () async {
      final service = GameProcessService(
        runProcess: (_, _) async => throw const OSError('no probe binary'),
      );

      expect(await service.isGameRunning(), isFalse);
      expect(
        AppLogger.instance.entries.single.message,
        contains('Error checking game process'),
      );
    });

    test('posix launch uses the platform opener with the steam URI', () async {
      final calls = <(String, List<String>)>[];
      final service = GameProcessService(
        runProcess: (exe, args) async {
          calls.add((exe, args));
          return _res(0, '');
        },
      );

      expect(await service.launchWarThunder('/wt'), isTrue);
      expect(calls.single.$1, anyOf('open', 'xdg-open'));
      expect(calls.single.$2, ['steam://rungameid/236390']);
    });

    test('a launcher failure is reported as false', () async {
      final service = GameProcessService(
        runProcess: (_, _) async => _res(1, 'nope'),
      );

      expect(await service.launchWarThunder('/wt'), isFalse);
    });
  });
}

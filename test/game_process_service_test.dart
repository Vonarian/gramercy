import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/features/localization/services/game_process_service.dart';

void main() {
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

  group('GameProcessService runtime behavior (host platform branch)', () {
    test('isGameRunning is false when the probe command fails', () async {
      final service = GameProcessService(
        runProcess: (_, _) => throw const OSError('no probe binary'),
      );
      expect(await service.isGameRunning(), isFalse);
    });

    test('isGameRunning true on exitCode 0 (posix pgrep -x)', () async {
      if (!Platform.isWindows) {
        final service = GameProcessService(
          runProcess: (exe, args) async => ProcessResult(0, 0, '', ''),
        );
        expect(await service.isGameRunning(), isTrue);
      }
    });

    test('isGameRunning false on exitCode 1 (no process matched)', () async {
      if (!Platform.isWindows) {
        final service = GameProcessService(
          runProcess: (exe, args) async => ProcessResult(0, 1, '', ''),
        );
        expect(await service.isGameRunning(), isFalse);
      }
    });
  });
}

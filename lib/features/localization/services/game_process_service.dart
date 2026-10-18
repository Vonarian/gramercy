import 'dart:io';

import 'package:gramercy/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;

/// Trait names for the game and its launcher, single source of truth.
const String kGameBinaryName = 'aces';
const String kGameImageName = 'aces.exe';

/// The probe command the platform process check should run (audit B3):
/// EXACT image/binary names only. `pgrep -f` matched any command line that
/// contained "aces" (editor buffers, notes files), and the old secondary
/// `launcher.exe` filter matched any game's launcher — both flipped the
/// destructive purge gate on false positives.
class GameProcessServiceProbeCommand {
  const GameProcessServiceProbeCommand._();

  static (String, List<String>) windows() =>
      ('tasklist', ['/FI', 'IMAGENAME eq $kGameImageName', '/NH']);

  static (String, List<String>) posix() => ('pgrep', ['-x', kGameBinaryName]);
}

class GameProcessService {
  static const String _warThunderSteamUri = 'steam://rungameid/236390';
  const GameProcessService({ProcessRunner? runProcess})
    : _runProcess = runProcess ?? _defaultRunProcess;

  final ProcessRunner _runProcess;

  static Future<ProcessResult> _defaultRunProcess(
    String executable,
    List<String> arguments,
  ) => Process.run(executable, arguments);

  /// True iff the tasklist /FI output actually contains the game image
  /// (filters out the "INFO: No tasks..." banner).
  static bool tasklistIsGameRunning(String stdout) =>
      stdout.toLowerCase().contains(kGameImageName);

  Future<bool> isGameRunning() async {
    try {
      if (Platform.isWindows) {
        final (exe, args) = GameProcessServiceProbeCommand.windows();
        final res = await _runProcess(exe, args);
        return tasklistIsGameRunning(res.stdout.toString());
      } else if (Platform.isLinux || Platform.isMacOS) {
        final (exe, args) = GameProcessServiceProbeCommand.posix();
        final res = await _runProcess(exe, args);
        return res.exitCode == 0;
      }
      return false;
    } catch (e) {
      AppLogger.instance.w('Error checking game process: $e', tag: 'PROCESS');
      return false;
    }
  }

  Future<bool> launchWarThunder(String wtPath) async {
    try {
      if (Platform.isWindows) {
        return await _launchWindows(wtPath);
      } else if (Platform.isLinux || Platform.isMacOS) {
        final (exe, args) = (
          Platform.isLinux ? 'xdg-open' : 'open',
          <String>[_warThunderSteamUri],
        );
        final res = await _runProcess(exe, args);
        return res.exitCode == 0;
      }
      return false;
    } catch (e) {
      AppLogger.instance.w(
        'Could not auto-launch War Thunder: $e',
        tag: 'PROCESS',
      );
      return false;
    }
  }

  /// Windows launch order: launcher.exe, then any aces.exe layout, and the
  /// Steam URI protocol as the last resort so a Steam-managed install still
  /// opens (audit B3 detection keeps the human out of manual config).
  Future<bool> _launchWindows(String wtPath) async {
    final launcher = File(p.join(wtPath, 'launcher.exe'));
    final aces = File(p.join(wtPath, 'win64', 'aces.exe'));
    final acesRoot = File(p.join(wtPath, 'aces.exe'));

    if (await launcher.exists()) {
      await _startDetached(launcher.path);
      return true;
    } else if (await aces.exists()) {
      await _startDetached(aces.path);
      return true;
    } else if (await acesRoot.exists()) {
      await _startDetached(acesRoot.path);
      return true;
    }
    final res = await _runProcess('cmd', ['/c', 'start', _warThunderSteamUri]);
    return res.exitCode == 0;
  }

  Future<void> _startDetached(String path) =>
      Process.start(path, [], mode: ProcessStartMode.detached);
}

/// Injectable seam so tests can stub probe/launch results.
typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

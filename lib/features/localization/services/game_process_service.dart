import 'dart:io';

import 'package:gramercy/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;

class GameProcessService {
  const GameProcessService();

  Future<bool> isGameRunning() async {
    try {
      if (Platform.isWindows) {
        final res = await Process.run('tasklist', [
          '/FI',
          'IMAGENAME eq aces.exe',
          '/NH',
        ]);
        final stdout = res.stdout.toString().toLowerCase();
        if (stdout.contains('aces.exe')) return true;

        final launcherRes = await Process.run('tasklist', [
          '/FI',
          'IMAGENAME eq launcher.exe',
          '/NH',
        ]);
        return launcherRes.stdout.toString().toLowerCase().contains(
          'launcher.exe',
        );
      } else if (Platform.isLinux || Platform.isMacOS) {
        final res = await Process.run('pgrep', ['-f', 'aces']);
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
        final launcher = File(p.join(wtPath, 'launcher.exe'));
        final aces = File(p.join(wtPath, 'win64', 'aces.exe'));
        final acesRoot = File(p.join(wtPath, 'aces.exe'));

        if (await launcher.exists()) {
          await Process.start(
            launcher.path,
            [],
            mode: ProcessStartMode.detached,
          );
          return true;
        } else if (await aces.exists()) {
          await Process.start(aces.path, [], mode: ProcessStartMode.detached);
          return true;
        } else if (await acesRoot.exists()) {
          await Process.start(
            acesRoot.path,
            [],
            mode: ProcessStartMode.detached,
          );
          return true;
        } else {
          await Process.run('cmd', ['/c', 'start', 'steam://rungameid/236390']);
          return true;
        }
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', ['steam://rungameid/236390']);
        return true;
      } else if (Platform.isMacOS) {
        await Process.run('open', ['steam://rungameid/236390']);
        return true;
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
}

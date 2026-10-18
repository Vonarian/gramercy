import 'dart:io';

import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/core/services/steam_library_scanner.dart';

typedef CommandRunner = Future<ProcessResult> Function(
  String executable,
  List<String> args,
);

/// First-run War Thunder install detection (audit B3):
/// 1. Asks the Windows registry for Steam's install root when applicable
///    (`HKCU\Software\Valve\Steam\SteamPath`) — covers non-default Steam
///    installs that the hard-coded candidate list misses.
/// 2. Runs [SteamLibraryScanner.findCandidateInstallDirs] with that root
///    prepended, so `libraryfolders.vdf` drives library discovery.
/// 3. Persists the first candidate that exists on disk, but ONLY when the
///    user has not already picked a path — an explicit pref always wins.
class SteamInstallPrefill {
  const SteamInstallPrefill._();

  /// Extracts the `SteamPath` REG_SZ value from `reg query` stdout.
  static String? parseRegSteamPath(String stdout) {
    final match = RegExp(
      r'SteamPath\s+REG_SZ\s+(.+)',
      multiLine: true,
    ).firstMatch(stdout);
    if (match == null) return null;
    final value = match.group(1)!.trim();
    return value.isEmpty ? null : value;
  }

  /// Looks up Steam's install path in the Windows registry. Returns null on
  /// every non-Windows platform, missing key, or any failure — never throws.
  static Future<String?> steamPathFromWindowsRegistry({
    CommandRunner? runCommand,
  }) async {
    if (!Platform.isWindows) return null;
    try {
      final run = runCommand ?? _defaultRun;
      final result = await run('reg', [
        'query',
        r'HKCU\Software\Valve\Steam',
        '/v',
        'SteamPath',
      ]);
      if (result.exitCode != 0) return null;
      return parseRegSteamPath(result.stdout.toString());
    } catch (_) {
      return null;
    }
  }

  static Future<ProcessResult> _defaultRun(
    String executable,
    List<String> arguments,
  ) => Process.run(executable, arguments);

  /// Detects and persists a War Thunder install path when [prefs] has none.
  /// Returns the path that was written, or null when the pref already exists
  /// or no candidate directory exists. [overrideCandidates] exists for tests
  /// so discovery can be pinned without touching the host filesystem.
  static Future<String?> autoFillMissingInstallPath({
    required PreferencesService prefs,
    String? windowsSteamRoot,
    List<String>? overrideCandidates,
  }) async {
    final existing = prefs.wtInstallPath;
    if (existing != null && existing.isNotEmpty) return null;

    final root = windowsSteamRoot ?? await steamPathFromWindowsRegistry();
    final candidates =
        overrideCandidates ??
        SteamLibraryScanner.findCandidateInstallDirs(windowsSteamRoot: root);
    for (final candidate in candidates) {
      if (candidate.isNotEmpty && Directory(candidate).existsSync()) {
        await prefs.setWtInstallPath(candidate);
        return candidate;
      }
    }
    return null;
  }
}

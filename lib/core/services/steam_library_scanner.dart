import 'dart:io';

import 'package:path/path.dart' as p;

/// Detects War Thunder installations across Steam libraries and standalone directories.
class SteamLibraryScanner {
  const SteamLibraryScanner._();

  static const String warThunderAppId = '236390';
  static final RegExp _pathEntryRegex = RegExp(
    r'"path"\s+"([^"]+)"',
    caseSensitive: false,
  );
  static final RegExp _folderBlockRegex = RegExp(
    r'"\d+"\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}',
    multiLine: true,
  );

  /// Extracts all library folder paths from Steam's `libraryfolders.vdf` format.
  static List<String> parseLibraryFoldersVdf(String content) {
    if (content.isEmpty) return const [];
    final results = <String>[];
    for (final match in _pathEntryRegex.allMatches(content)) {
      final rawPath = match.group(1);
      if (rawPath != null && rawPath.trim().isNotEmpty) {
        results.add(rawPath.replaceAll(r'\\', r'\'));
      }
    }
    return results;
  }

  /// Finds libraries that explicitly contain War Thunder app ID (236390).
  static List<String> findWarThunderLibraries(String content) {
    if (!content.contains(warThunderAppId)) return const [];
    final matches = <String>[];
    for (final blockMatch in _folderBlockRegex.allMatches(content)) {
      final block = blockMatch.group(1) ?? '';
      if (block.contains(warThunderAppId)) {
        final pathMatch = _pathEntryRegex.firstMatch(block);
        if (pathMatch != null) {
          final raw = pathMatch.group(1)!;
          matches.add(raw.replaceAll(r'\\', r'\'));
        }
      }
    }
    return matches;
  }

  /// Appends the standard sub-path to reach the War Thunder game folder.
  static String resolveGamePath(String libraryRoot, {bool isWindows = false}) {
    if (isWindows) {
      final normalized = libraryRoot.replaceAll('/', r'\');
      return p.windows.join(normalized, 'steamapps', 'common', 'War Thunder');
    }
    return p.posix.join(libraryRoot, 'steamapps', 'common', 'War Thunder');
  }

  /// Returns candidate directory paths where War Thunder might be installed.
  static List<String> findCandidateInstallDirs({
    String? homeDir,
    bool? isWindows,
    bool? isMacOS,
    bool? isLinux,
    String? windowsSteamRoot,
  }) {
    final win = isWindows ?? Platform.isWindows;
    final mac = isMacOS ?? Platform.isMacOS;
    final lin = isLinux ?? Platform.isLinux;
    final home = homeDir ?? Platform.environment['HOME'] ?? '';
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';

    final candidates = <String>[];
    final vdfPaths = <String>[
      if (windowsSteamRoot != null && windowsSteamRoot.isNotEmpty)
        p.join(windowsSteamRoot, 'steamapps', 'libraryfolders.vdf'),
      ..._findSteamVdfPaths(win, mac, lin, home),
    ];
    for (final vdfPath in vdfPaths) {
      final file = File(vdfPath);
      if (file.existsSync()) {
        try {
          final content = file.readAsStringSync();
          final wtLibs = findWarThunderLibraries(content);
          final allLibs = wtLibs.isNotEmpty
              ? wtLibs
              : parseLibraryFoldersVdf(content);
          for (final lib in allLibs) {
            candidates.add(resolveGamePath(lib, isWindows: win));
          }
        } catch (_) {}
      }
    }

    candidates.addAll(
      _getStandaloneCandidates(win, mac, lin, home, localAppData),
    );
    return candidates;
  }

  static List<String> _findSteamVdfPaths(
    bool win,
    bool mac,
    bool lin,
    String home,
  ) {
    if (win) {
      return [
        r'C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf',
        r'C:\Program Files\Steam\steamapps\libraryfolders.vdf',
      ];
    }
    if (mac && home.isNotEmpty) {
      return [
        '$home/Library/Application Support/Steam/steamapps/libraryfolders.vdf',
      ];
    }
    if (lin && home.isNotEmpty) {
      return [
        '$home/.local/share/Steam/steamapps/libraryfolders.vdf',
        '$home/.steam/steam/steamapps/libraryfolders.vdf',
      ];
    }
    return const [];
  }

  static List<String> _getStandaloneCandidates(
    bool win,
    bool mac,
    bool lin,
    String home,
    String localAppData,
  ) {
    if (win) {
      return [
        r'C:\Games\WarThunder',
        r'C:\WarThunder',
        if (localAppData.isNotEmpty) p.windows.join(localAppData, 'WarThunder'),
      ];
    }
    if (mac && home.isNotEmpty) {
      return [
        '$home/Library/Application Support/WarThunder',
        '/Applications/WarThunder.app',
      ];
    }
    if (lin && home.isNotEmpty) {
      return ['$home/.config/WarThunder'];
    }
    return const [];
  }
}

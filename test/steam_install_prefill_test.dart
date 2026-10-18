import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/core/services/steam_install_prefill.dart';
import 'package:gramercy/core/services/steam_library_scanner.dart';
import 'package:mocktail/mocktail.dart';

class _MockPrefs extends Mock implements PreferencesService {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  // Stateful stub: the write stub captures into a slot the getter stub
  // reads, so later `prefs.wtInstallPath` reflects what was persisted (a
  // pinned thenReturn getter would make persistence assertions moot).
  PreferencesService prefsWith({String? storedPath}) {
    String? persisted = storedPath;
    final prefs = _MockPrefs();
    when(() => prefs.wtInstallPath).thenAnswer((_) => persisted);
    when(() => prefs.setWtInstallPath(any())).thenAnswer((inv) async {
      persisted = inv.positionalArguments[0] as String?;
      return true;
    });
    return prefs;
  }

  group('steam registry parsing (B3 install detection)', () {
    test('parseRegSteamPath extracts value from reg query output', () {
      const stdout = '''
HKEY_CURRENT_USER\\Software\\Valve\\Steam
    SteamPath    REG_SZ    C:\\Program Files (x86)\\Steam
''';
      expect(
        SteamInstallPrefill.parseRegSteamPath(stdout),
        r'C:\Program Files (x86)\Steam',
      );
    });

    test('parseRegSteamPath returns null on missing REG_SZ value', () {
      expect(SteamInstallPrefill.parseRegSteamPath(''), isNull);
      expect(SteamInstallPrefill.parseRegSteamPath('No value'), isNull);
    });
  });

  group('first-run wt install prefill', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('wt_prefill_');
      await Directory('${tempDir.path}/steamapps/common/War Thunder')
          .create(recursive: true);
      await File('${tempDir.path}/steamapps/libraryfolders.vdf')
          .writeAsString('''
"libraryfolders"
{
  "0"
  {
    "path"    "${_vdfEscape(tempDir.path)}"
    "apps"
    {
      "236390"    "1"
    }
  }
}
''');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'prefills the persisted path when pref empty and reg library found',
      () async {
        final prefs = prefsWith(storedPath: null);
        final filled = await SteamInstallPrefill.autoFillMissingInstallPath(
          prefs: prefs,
          windowsSteamRoot: tempDir.path,
        );
        expect(filled, equals('${tempDir.path}/steamapps/common/War Thunder'));
        expect(prefs.wtInstallPath, equals(filled));
      },
    );

    test('leaves an existing pref untouched (no re-detection)', () async {
      final prefs = prefsWith(storedPath: '/Users/me/CustomWt');
      final filled = await SteamInstallPrefill.autoFillMissingInstallPath(
        prefs: prefs,
        windowsSteamRoot: tempDir.path,
      );
      expect(filled, isNull, reason: 'existing pref must never be rewritten');
      expect(prefs.wtInstallPath, equals('/Users/me/CustomWt'));
    });

    test(
      'falls back to standalone candidates when steam vdf missing',
      () async {
        final prefs = prefsWith(storedPath: null);
        await Directory('${tempDir.path}/War Thunder').create();

        final filled = await SteamInstallPrefill.autoFillMissingInstallPath(
          prefs: prefs,
          windowsSteamRoot: '${tempDir.path}/missing-steam',
          overrideCandidates: ['${tempDir.path}/War Thunder'],
        );
        expect(filled, equals('${tempDir.path}/War Thunder'));
        expect(prefs.wtInstallPath, equals('${tempDir.path}/War Thunder'));
      },
    );

    test('returns null without crashing when nothing exists', () async {
      final prefs = prefsWith(storedPath: null);
      final filled = await SteamInstallPrefill.autoFillMissingInstallPath(
        prefs: prefs,
        overrideCandidates: const ['/definitely/not/here'],
      );
      expect(filled, isNull);
      expect(prefs.wtInstallPath, isNull);
    });
  });

  group('scanner windowsSteamRoot plumbing', () {
    test('windowsSteamRoot probe lists first when its vdf exists', () async {
      final temp = await Directory.systemTemp.createTemp('wt_regroot_');
      addTearDown(() => temp.delete(recursive: true));
      await Directory('${temp.path}/steamapps/common/War Thunder')
          .create(recursive: true);
      await File('${temp.path}/steamapps/libraryfolders.vdf')
          .writeAsString('{"0" { "path" "${_vdfEscape(temp.path)}" } }');

      final candidates = SteamLibraryScanner.findCandidateInstallDirs(
        homeDir: '',
        isMacOS: true,
        windowsSteamRoot: temp.path,
      );

      expect(
        candidates.first,
        equals('${temp.path}/steamapps/common/War Thunder'),
      );
    });
  });
}

/// Escapes a real filesystem path into the escaped form a VDF stores
/// (doubles backslashes, escapes quotes).
String _vdfEscape(String path) {
  final escaped = path.replaceAll('\\', '\\\\');
  return escaped.replaceAll('"', r'\"');
}

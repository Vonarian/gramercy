import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/services/steam_library_scanner.dart';

void main() {
  group('SteamLibraryScanner VDF Parsing Tests', () {
    test(
      'extractLibraryPaths parses standard multi-library VDF with app 236390',
      () {
        const vdfContent = '''
"libraryfolders"
{
  "0"
  {
    "path"    "C:\\\\Program Files (x86)\\\\Steam"
    "label"   ""
    "contentid"   "123"
    "apps"
    {
      "730"   "1000"
    }
  }
  "1"
  {
    "path"    "D:\\\\Games\\\\SteamLibrary"
    "label"   "Secondary"
    "apps"
    {
      "236390"    "456789"
    }
  }
}
''';

        final libraries = SteamLibraryScanner.parseLibraryFoldersVdf(
          vdfContent,
        );
        expect(libraries, contains('D:\\Games\\SteamLibrary'));
        expect(libraries, contains('C:\\Program Files (x86)\\Steam'));

        final wtLibraries = SteamLibraryScanner.findWarThunderLibraries(
          vdfContent,
        );
        expect(wtLibraries, contains('D:\\Games\\SteamLibrary'));
      },
    );

    test('parseLibraryFoldersVdf handles POSIX paths with unquoted or quoted whitespace', () {
      const vdfContent = '''
"libraryfolders"
{
  "0"
  {
    "path"    "/home/user/.local/share/Steam"
    "apps"
    {
      "236390"    "12345"
    }
  }
  "1"
  {
    "path"    "/mnt/storage/SteamLibrary"
  }
}
''';

      final libraries = SteamLibraryScanner.parseLibraryFoldersVdf(vdfContent);
      expect(libraries, [
        '/home/user/.local/share/Steam',
        '/mnt/storage/SteamLibrary',
      ]);
    });

    test(
      'parseLibraryFoldersVdf returns empty on malformed or empty string',
      () {
        expect(SteamLibraryScanner.parseLibraryFoldersVdf(''), isEmpty);
        expect(
          SteamLibraryScanner.parseLibraryFoldersVdf('not valid vdf'),
          isEmpty,
        );
      },
    );

    test(
      'resolveGamePathFromLibrary derives canonical War Thunder directory',
      () {
        final posixPath = SteamLibraryScanner.resolveGamePath(
          '/home/user/SteamLibrary',
          isWindows: false,
        );
        expect(
          posixPath,
          '/home/user/SteamLibrary/steamapps/common/War Thunder',
        );

        final winPath = SteamLibraryScanner.resolveGamePath(
          r'D:\SteamLibrary',
          isWindows: true,
        );
        expect(winPath, r'D:\SteamLibrary\steamapps\common\War Thunder');
      },
    );
  });
}

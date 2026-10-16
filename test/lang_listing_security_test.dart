import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/features/localization/providers/config_providers.dart';
import 'package:gramercy/features/localization/providers/environment_providers.dart';
import 'package:path/path.dart' as p;

/// Fixed wtPath state for the provider under test; set before container use.
String _fixedWtPath = '';

class _FixedWtPathNotifier extends WtPathNotifier {
  @override
  String? build() => _fixedWtPath;
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [wtPathProvider.overrideWith(_FixedWtPathNotifier.new)],
    );
  });

  tearDown(() async {
    container.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('availableFilesProvider symlink refusal (F1-2b)', () {
    test(
      'lists only real csv files; symlinked csv is never selectable',
      () async {
        tempDir = await Directory.systemTemp.createTemp('wt_listing_sec_');
        final wt = Directory(p.join(tempDir.path, 'wt'));
        final lang = Directory(p.join(wt.path, 'lang'));
        await lang.create(recursive: true);
        await File(p.join(lang.path, 'keep.csv')).writeAsString('REAL');
        final target = Directory(p.join(tempDir.path, 'outside_lang'));
        await target.create(recursive: true);
        await File(p.join(target.path, 'linked_target.csv'))
            .writeAsString('FORGED');
        await Link(p.join(lang.path, 'link.csv'))
            .create(p.join(target.path, 'linked_target.csv'));
        _fixedWtPath = wt.path;

        final files = await container.read(availableFilesProvider.future);

        // RED pre-fix: link.csv is returned as a selectable file.
        expect(files, ['keep.csv']);
      },
    );

    test(
      'falls back to the default list when no real csv files exist',
      () async {
        tempDir = await Directory.systemTemp.createTemp('wt_listing_sec_');
        final wt = Directory(p.join(tempDir.path, 'wt'));
        final lang = Directory(p.join(wt.path, 'lang'));
        await lang.create(recursive: true);
        final target = Directory(p.join(tempDir.path, 'outside_lang'));
        await target.create(recursive: true);
        await Link(p.join(lang.path, 'only_link.csv'))
            .create(File(p.join(target.path, 'x.csv')).path);
        _fixedWtPath = wt.path;

        final files = await container.read(availableFilesProvider.future);

        expect(files, [
          'units.csv',
          'menu.csv',
          'missions.csv',
          'ui.csv',
          'hud.csv',
          'shop.csv',
          'encyclopedia.csv',
        ]);
      },
    );
  });

  group('visibleLangCsvFiles helper (F1-2b)', () {
    test('returns exactly the real csv basenames, links excluded', () async {
      tempDir = await Directory.systemTemp.createTemp('wt_listing_sec_');
      final lang = Directory(p.join(tempDir.path, 'lang'));
      await lang.create(recursive: true);
      await File(p.join(lang.path, 'keep.csv')).writeAsString('REAL');
      final target = Directory(p.join(tempDir.path, 'outside'));
      await target.create(recursive: true);
      await File(p.join(target.path, 'linked_target.csv'))
          .writeAsString('FORGED');
      await Link(p.join(lang.path, 'link.csv'))
          .create(p.join(target.path, 'linked_target.csv'));

      final files = await visibleLangCsvFiles(lang);

      expect(files, ['keep.csv']);
    });

    test('keeps ignoring non-csv entities, dirs, and nested content', () async {
      tempDir = await Directory.systemTemp.createTemp('wt_listing_sec_');
      final lang = Directory(p.join(tempDir.path, 'lang'));
      await lang.create(recursive: true);
      await File(p.join(lang.path, 'notes.txt')).writeAsString('txt');
      await File(p.join(lang.path, 'units.csv')).writeAsString('CSV');
      await File(p.join(lang.path, 'readme.md')).writeAsString('ignored too');
      await Directory(p.join(lang.path, 'subdir')).create(recursive: true);

      final files = await visibleLangCsvFiles(lang);

      expect(files, unorderedEquals(['units.csv']));
    });
  });
}

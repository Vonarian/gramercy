import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/core/security/lang_file_guard.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

class _CountingWorker extends LocalizationWorkerService {
  int loadBaseStringsCalls = 0;

  @override
  Future<Map<String, String>> loadBaseStrings(String filePath) {
    loadBaseStringsCalls++;
    return super.loadBaseStrings(filePath);
  }
}

class _FixedWtPath extends WtPathNotifier {
  _FixedWtPath(this._path);
  final String _path;

  @override
  String? build() => _path;
}

void main() {
  group('lang/ join guard (defense-in-depth, audit B1)', () {
    test(
      'baseStringsProvider refuses to join unsafe lang file names',
      () async {
        // Before the change: baseStringsProvider joined selectedFileProvider's
        // value straight into p.join(wtPath, 'lang', fileName), so a traversal
        // name would reach the filesystem (Lang_file_guard semantics ignored).
        final temp = await Directory.systemTemp.createTemp('lang_guard_test_');
        addTearDown(() => temp.delete(recursive: true));

        final worker = _CountingWorker();
        final container = ProviderContainer(
          overrides: [
            wtPathProvider.overrideWith(() => _FixedWtPath(temp.path)),
            workerServiceProvider.overrideWithValue(worker),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(
          baseStringsProvider('../config.blk').future,
        );

        expect(result, isEmpty);
        expect(
          worker.loadBaseStringsCalls,
          0,
          reason: 'unsafe name must never reach the filesystem',
        );
      },
    );

    test('safe names still load', () async {
      final temp = await Directory.systemTemp.createTemp('lang_guard_ok_');
      addTearDown(() => temp.delete(recursive: true));
      await Directory('${temp.path}/lang').create();
      await File('${temp.path}/lang/units.csv')
          .writeAsString('<ID>;<English>\r\nus_m4a3;M4A3\r\n');

      final worker = _CountingWorker();
      final container = ProviderContainer(
        overrides: [
          wtPathProvider.overrideWith(() => _FixedWtPath(temp.path)),
          workerServiceProvider.overrideWithValue(worker),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        baseStringsProvider('units.csv').future,
      );
      expect(result, equals({'us_m4a3': 'M4A3'}));
      expect(worker.loadBaseStringsCalls, 1);
    });

    test('guard itself rejects traversal and drive-relative names', () {
      expect(safeLangFilePath('/wt', 'units.csv'), isNotNull);
      expect(safeLangFilePath('/wt', '../config.blk'), isNull);
      expect(safeLangFilePath('/wt', 'C:victim.csv'), isNull);
      expect(safeLangFilePath('/wt', 'units.csv:hidden'), isNull);
    });
  });
}

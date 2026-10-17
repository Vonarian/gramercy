import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockDb extends Mock implements AppDatabase {}

class _FixedWtPath extends WtPathNotifier {
  _FixedWtPath(this._path);
  final String _path;

  @override
  String? build() => _path;
}

class _FixedSelectedFile extends SelectedFileNotifier {
  _FixedSelectedFile(this._file);
  final String _file;

  @override
  String build() => _file;
}

class _FixedAutoExport extends AutoExportNotifier {
  @override
  bool build() => true;
}

class _FakeWorker extends LocalizationWorkerService {
  int loadBaseStringsCalls = 0;
  int patchConfigBlkCalls = 0;

  @override
  Future<Map<String, String>> loadBaseStrings(String filePath) {
    loadBaseStringsCalls++;
    return super.loadBaseStrings(filePath);
  }

  @override
  Future<bool> patchConfigBlk(String configBlkPath) {
    patchConfigBlkCalls++;
    return Future.value(true);
  }
}

extension _DeployCount on List<ExportStatus> {
  int get deployCount => where((s) => s == ExportStatus.success).length;
}

Future<void> _settle({int attempts = 30}) async {
  for (var i = 0; i < attempts; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue('');
  });

  group('ExportNotifier auto-deploy hot path', () {
    late Directory tempDir;
    late String wtPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gramercy_deploy_test_');
      wtPath = '${tempDir.path}/wt';
      await Directory('$wtPath/lang').create(recursive: true);
      await File('$wtPath/lang/units.csv')
          .writeAsString('<ID>;<English>\r\nus_m4a3;M4A3 (76) W\r\n');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    ProviderContainer buildContainer({
      required _MockDb db,
      required LocalizationWorkerService worker,
      Duration debounce = const Duration(milliseconds: 50),
    }) {
      return ProviderContainer(
        overrides: [
          wtPathProvider.overrideWith(() => _FixedWtPath(wtPath)),
          selectedFileProvider.overrideWith(
            () => _FixedSelectedFile('units.csv'),
          ),
          autoExportProvider.overrideWith(_FixedAutoExport.new),
          autoExportDebounceProvider.overrideWithValue(debounce),
          dbProvider.overrideWithValue(db),
          workerServiceProvider.overrideWithValue(worker),
        ],
      );
    }

    test('auto-export after several saves coalesces into ONE deploy', () async {
      // Before the change: every save awaited exportCurrentFile, so three
      // rapid saves produced three full export pipelines.
      final db = _MockDb();
      when(() => db.getOverridesForFile(any())).thenAnswer((_) async => []);
      final worker = _FakeWorker();
      final container = buildContainer(db: db, worker: worker);
      addTearDown(container.dispose);

      final statuses = <ExportStatus>[];
      container.listen(exportNotifierProvider, (_, next) {
        statuses.add(next.status);
      });

      final notifier = container.read(exportNotifierProvider.notifier);
      notifier.requestAutoExport();
      notifier.requestAutoExport();
      notifier.requestAutoExport();

      await _settle();

      expect(statuses.deployCount, 1, reason: 'statuses=$statuses');
    });

    test(
      'deploying must NOT re-parse base strings (no cache invalidation)',
      () async {
        // Before the change: _deploy invalidated baseStringsProvider, so every
        // deploy re-read/re-parsed the whole CSV (double parse per edit).
        final db = _MockDb();
        when(() => db.getOverridesForFile(any())).thenAnswer((_) async => []);
        final worker = _FakeWorker();
        final container = buildContainer(db: db, worker: worker);
        addTearDown(container.dispose);

        final sub = container.listen(
          baseStringsProvider('units.csv'),
          (_, _) {},
        );
        addTearDown(sub.close);
        final first = await container.read(
          baseStringsProvider('units.csv').future,
        );
        expect(first, equals({'us_m4a3': 'M4A3 (76) W'}));
        expect(worker.loadBaseStringsCalls, 1);

        final notifier = container.read(exportNotifierProvider.notifier);
        final ok = await notifier.exportCurrentFile();
        expect(ok, isTrue);

        await _settle();

        expect(
          worker.loadBaseStringsCalls,
          1,
          reason: 'deploy must reuse the parsed cache',
        );
      },
    );
  });
}

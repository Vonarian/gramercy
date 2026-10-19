import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/config_providers.dart';
import 'package:gramercy/features/localization/providers/logging_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PreferencesService> _prefsFor(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return PreferencesService(await SharedPreferences.getInstance());
}

void main() {
  setUp(() {
    AppLogger.instance
      ..configure(minLevel: LogLevel.verbose, fileOutput: false)
      ..clear();
  });

  tearDown(() {
    AppLogger.instance
      ..configure(minLevel: LogLevel.info, fileOutput: false)
      ..clear();
  });

  group('LogLevelNotifier', () {
    test(
      'builds from the persisted preference and retunes the logger',
      () async {
        final prefs = await _prefsFor({
          PreferencesService.keyLogLevel: 'error',
        });
        final container = ProviderContainer(
          overrides: [prefsProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        expect(container.read(logLevelNotifierProvider), LogLevel.error);
        expect(AppLogger.instance.minLevel, LogLevel.error);
      },
    );

    test('falls back to info on an unknown saved level', () async {
      final prefs = await _prefsFor({PreferencesService.keyLogLevel: 'banana'});
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(logLevelNotifierProvider), LogLevel.info);
    });

    test('setLogLevel echoes state and persists the preference', () async {
      final prefs = await _prefsFor({});
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(logLevelNotifierProvider.notifier)
          .setLogLevel(LogLevel.warning);

      expect(container.read(logLevelNotifierProvider), LogLevel.warning);
      expect(AppLogger.instance.minLevel, LogLevel.warning);
      expect(prefs.logLevel, 'warning');
    });
  });

  group('LogEntriesNotifier', () {
    test('appends entries streamed from the logger after build', () async {
      final prefs = await _prefsFor({});
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      AppLogger.instance.i('Boot line', tag: 'BOOT');
      expect(
        container.read(logEntriesNotifierProvider).last.message,
        'Boot line',
      );

      AppLogger.instance.w('Late line');
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(logEntriesNotifierProvider).map((e) => e.message),
        containsAllInOrder(['Boot line', 'Late line']),
      );
    });

    test('clear() empties state and the logger buffer', () async {
      final prefs = await _prefsFor({});
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      AppLogger.instance.i('Something happened');
      container.read(logEntriesNotifierProvider.notifier).clear();

      expect(container.read(logEntriesNotifierProvider), isEmpty);
      expect(AppLogger.instance.entries, isEmpty);
    });
  });

  group('FileLoggingNotifier', () {
    test('builds from the persisted preference and tunes the logger', () async {
      final prefs = await _prefsFor({
        PreferencesService.keyEnableFileLogging: true,
      });
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(fileLoggingNotifierProvider), isTrue);
      expect(AppLogger.instance.fileOutput, isTrue);
    });

    test('setEnabled echoes state and persists the preference', () async {
      final prefs = await _prefsFor({});
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(fileLoggingNotifierProvider.notifier)
          .setEnabled(true);

      expect(container.read(fileLoggingNotifierProvider), isTrue);
      expect(AppLogger.instance.fileOutput, isTrue);
      expect(prefs.enableFileLogging, isTrue);
    });
  });
}

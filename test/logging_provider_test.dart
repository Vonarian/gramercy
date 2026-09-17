import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/config_providers.dart';
import 'package:gramercy/features/localization/providers/logging_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Logging Providers Tests', () {
    late ProviderContainer container;
    late PreferencesService prefsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'log_level': 'warning'});
      final prefs = await SharedPreferences.getInstance();
      prefsService = PreferencesService(prefs);

      container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefsService)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('logLevelNotifierProvider initializes from preferences', () {
      final level = container.read(logLevelNotifierProvider);
      expect(level, LogLevel.warning);
    });

    test(
      'logLevelNotifierProvider updates level, logger and preferences',
      () async {
        final notifier = container.read(logLevelNotifierProvider.notifier);
        await notifier.setLogLevel(LogLevel.debug);

        expect(container.read(logLevelNotifierProvider), LogLevel.debug);
        expect(prefsService.logLevel, 'debug');
        expect(AppLogger.instance.minLevel, LogLevel.debug);
      },
    );
  });
}

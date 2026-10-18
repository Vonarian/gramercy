import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/logging/log_path.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/core/services/steam_install_prefill.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/home_screen.dart';
import 'package:gramercy/ui/fallback/unsupported_platform_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:worker_manager/worker_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail gracefully on a handset instead of half-initializing desktop
  // window/process plugins (mobile review, option A).
  if (Platform.isIOS || Platform.isAndroid) {
    runApp(
      MaterialApp(
        home: UnsupportedPlatformScreen(platform: Platform.operatingSystem),
      ),
    );
    return;
  }

  // 1. Initialize Isolate Worker Manager
  await workerManager.init();

  // 2. Desktop Window Optimization
  await _setupDesktopWindow();

  // 3. Initialize Services: prefs, database, logging, first-run detection
  final (preferencesService, database) = await _initServices();

  // 4. Run Application with Injected Dependencies
  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(database),
        prefsProvider.overrideWithValue(preferencesService),
      ],
      child: const WarThunderEditorApp(),
    ),
  );
}

Future<(PreferencesService, AppDatabase)> _initServices() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(sharedPreferences);
  final database = AppDatabase();

  final logFilePath = resolveLogFilePath();
  AppLogger.instance.configure(
    minLevel: LogLevel.fromString(preferencesService.logLevel),
    fileOutput: logFilePath != null && preferencesService.enableFileLogging,
    logFilePath: logFilePath,
  );
  AppLogger.instance.i('War Thunder Localization Editor booted');

  // First-run install detection (audit B3): prefills the persisted War
  // Thunder install path from Steam libraries/registry. Explicit user
  // choices always win — an existing pref is never rewritten.
  await SteamInstallPrefill.autoFillMissingInstallPath(
    prefs: preferencesService,
  );

  return (preferencesService, database);
}

Future<void> _setupDesktopWindow() async {
  final isTest = Platform.environment.containsKey('FLUTTER_TEST');
  if (!isTest && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1200, 800),
        minimumSize: Size(960, 640),
        center: true,
        title: 'War Thunder Localization Editor',
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {
      // Non-fatal if window_manager cannot initialize
    }
  }
}

class WarThunderEditorApp extends StatelessWidget {
  const WarThunderEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'War Thunder Localization Editor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

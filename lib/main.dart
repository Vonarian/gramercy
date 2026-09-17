import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/database/database.dart';
import 'package:gramercy/core/logging/app_logger.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:worker_manager/worker_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Isolate Worker Manager
  await workerManager.init();

  // 2. Desktop Window Optimization
  await _setupDesktopWindow();

  // 3. Initialize Persistent Storage: SharedPreferences & Drift SQLite
  final sharedPreferences = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(sharedPreferences);
  final database = AppDatabase();

  // 4. Configure Application Logging
  AppLogger.instance.configure(
    minLevel: LogLevel.fromString(preferencesService.logLevel),
    fileOutput: preferencesService.enableFileLogging,
  );
  AppLogger.instance.i('War Thunder Localization Editor booted');

  // 5. Run Application with Injected Dependencies
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

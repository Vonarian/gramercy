import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_entry.dart';
import 'config_providers.dart';

final loggerProvider = Provider<AppLogger>((ref) {
  return AppLogger.instance;
});

class LogLevelNotifier extends Notifier<LogLevel> {
  @override
  LogLevel build() {
    final prefs = ref.watch(prefsProvider);
    final saved = prefs.logLevel;
    final level = LogLevel.fromString(saved, fallback: LogLevel.info);
    AppLogger.instance.minLevel = level;
    return level;
  }

  Future<void> setLogLevel(LogLevel level) async {
    state = level;
    AppLogger.instance.minLevel = level;
    final prefs = ref.read(prefsProvider);
    await prefs.setLogLevel(level.name);
  }
}

final logLevelNotifierProvider = NotifierProvider<LogLevelNotifier, LogLevel>(
  LogLevelNotifier.new,
);

class LogEntriesNotifier extends Notifier<List<LogEntry>> {
  StreamSubscription<LogEntry>? _sub;

  @override
  List<LogEntry> build() {
    final logger = ref.watch(loggerProvider);
    _sub?.cancel();
    _sub = logger.stream.listen((entry) {
      state = [...state, entry];
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    return logger.entries;
  }

  void clear() {
    ref.read(loggerProvider).clear();
    state = const [];
  }
}

final logEntriesNotifierProvider =
    NotifierProvider<LogEntriesNotifier, List<LogEntry>>(
      LogEntriesNotifier.new,
    );

class FileLoggingNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(prefsProvider);
    final enabled = prefs.enableFileLogging;
    AppLogger.instance.fileOutput = enabled;
    return enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    AppLogger.instance.fileOutput = enabled;
    final prefs = ref.read(prefsProvider);
    await prefs.setEnableFileLogging(enabled);
  }
}

final fileLoggingNotifierProvider = NotifierProvider<FileLoggingNotifier, bool>(
  FileLoggingNotifier.new,
);

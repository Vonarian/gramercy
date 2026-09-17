import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'log_entry.dart';

class AppLogger {
  static final AppLogger instance = AppLogger();

  LogLevel minLevel;
  bool consoleOutput;
  bool fileOutput;
  String? logFilePath;
  final int maxBufferSize;

  final List<LogEntry> _buffer = [];
  final StreamController<LogEntry> _controller = StreamController<LogEntry>.broadcast();

  AppLogger({
    this.minLevel = LogLevel.info,
    this.consoleOutput = true,
    this.fileOutput = false,
    this.logFilePath,
    this.maxBufferSize = 500,
  });

  void configure({
    LogLevel? minLevel,
    bool? consoleOutput,
    bool? fileOutput,
    String? logFilePath,
  }) {
    if (minLevel != null) this.minLevel = minLevel;
    if (consoleOutput != null) this.consoleOutput = consoleOutput;
    if (fileOutput != null) this.fileOutput = fileOutput;
    if (logFilePath != null) this.logFilePath = logFilePath;
  }

  void log(
    LogLevel level,
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index || minLevel == LogLevel.none) return;

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );

    _appendBuffer(entry);
    if (consoleOutput) _printConsole(entry);
    if (fileOutput && logFilePath != null) _appendFile(entry);

    if (!_controller.isClosed) {
      _controller.add(entry);
    }
  }

  void _appendBuffer(LogEntry entry) {
    if (_buffer.length >= maxBufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(entry);
  }

  void _printConsole(LogEntry entry) {
    dev.log(
      entry.message,
      name: entry.tag,
      error: entry.error,
      stackTrace: entry.stackTrace,
      level: _devLogLevel(entry.level),
    );
  }

  void _appendFile(LogEntry entry) {
    try {
      final file = File(logFilePath!);
      file.writeAsStringSync('${entry.toFormattedString()}\n', mode: FileMode.append);
    } catch (_) {}
  }

  static int _devLogLevel(LogLevel lvl) {
    switch (lvl) {
      case LogLevel.verbose: return 300;
      case LogLevel.debug: return 500;
      case LogLevel.info: return 800;
      case LogLevel.warning: return 900;
      case LogLevel.error: return 1000;
      case LogLevel.none: return 0;
    }
  }

  void v(String msg, {String tag = 'APP', Object? error, StackTrace? stack}) =>
      log(LogLevel.verbose, msg, tag: tag, error: error, stackTrace: stack);

  void d(String msg, {String tag = 'APP', Object? error, StackTrace? stack}) =>
      log(LogLevel.debug, msg, tag: tag, error: error, stackTrace: stack);

  void i(String msg, {String tag = 'APP', Object? error, StackTrace? stack}) =>
      log(LogLevel.info, msg, tag: tag, error: error, stackTrace: stack);

  void w(String msg, {String tag = 'APP', Object? error, StackTrace? stack}) =>
      log(LogLevel.warning, msg, tag: tag, error: error, stackTrace: stack);

  void e(String msg, {String tag = 'APP', Object? error, StackTrace? stack}) =>
      log(LogLevel.error, msg, tag: tag, error: error, stackTrace: stack);

  List<LogEntry> get entries => List.unmodifiable(_buffer);
  Stream<LogEntry> get stream => _controller.stream;

  void clear() => _buffer.clear();

  void dispose() {
    _controller.close();
  }
}

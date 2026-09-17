import 'package:flutter/foundation.dart';

enum LogLevel {
  verbose('VERB'),
  debug('DEBG'),
  info('INFO'),
  warning('WARN'),
  error('ERR '),
  none('NONE');

  const LogLevel(this.label);
  final String label;

  static LogLevel fromString(String val, {LogLevel fallback = LogLevel.info}) {
    final lower = val.trim().toLowerCase();
    for (final level in LogLevel.values) {
      if (level.name.toLowerCase() == lower) return level;
    }
    return fallback;
  }
}

@immutable
class LogEntry {
  final LogLevel level;
  final String message;
  final String tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.level,
    required this.message,
    this.tag = 'APP',
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  String toFormattedString() {
    final timeStr = _formatTimestamp(timestamp);
    final errorPart = error != null ? ' | Error: $error' : '';
    return '$timeStr [${level.label}] [$tag] $message$errorPart';
  }

  static String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  String toString() => toFormattedString();
}

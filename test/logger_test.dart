import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/logging/app_logger.dart';

void main() {
  group('LogLevel & LogEntry Tests', () {
    test('LogLevel precedence and parsing', () {
      expect(LogLevel.verbose.index < LogLevel.debug.index, isTrue);
      expect(LogLevel.debug.index < LogLevel.info.index, isTrue);
      expect(LogLevel.info.index < LogLevel.warning.index, isTrue);
      expect(LogLevel.warning.index < LogLevel.error.index, isTrue);
      expect(LogLevel.error.index < LogLevel.none.index, isTrue);

      expect(LogLevel.fromString('debug'), LogLevel.debug);
      expect(LogLevel.fromString('INFO'), LogLevel.info);
      expect(LogLevel.fromString('warning'), LogLevel.warning);
      expect(LogLevel.fromString('ERROR'), LogLevel.error);
      expect(LogLevel.fromString('unknown', fallback: LogLevel.info), LogLevel.info);
    });

    test('LogEntry formatted line includes tag, level, message, and error', () {
      final entry = LogEntry(
        level: LogLevel.warning,
        message: 'Delta conflict resolved',
        tag: 'DRIFT',
        timestamp: DateTime(2026, 9, 17, 16, 0),
        error: 'DuplicateKeyException',
      );

      final line = entry.toFormattedString();
      expect(line, contains('[WARN]'));
      expect(line, contains('[DRIFT]'));
      expect(line, contains('Delta conflict resolved'));
      expect(line, contains('Error: DuplicateKeyException'));
    });
  });

  group('AppLogger Configurable Behavior Tests', () {
    late AppLogger logger;

    setUp(() {
      logger = AppLogger(maxBufferSize: 3);
      logger.configure(
        minLevel: LogLevel.info,
        consoleOutput: false,
      );
    });

    tearDown(() {
      logger.dispose();
    });

    test('Filters out logs below configured minLevel', () {
      logger.v('Verbose message', tag: 'TEST');
      logger.d('Debug message', tag: 'TEST');
      logger.i('Info message', tag: 'TEST');
      logger.w('Warning message', tag: 'TEST');
      logger.e('Error message', tag: 'TEST');

      final entries = logger.entries;
      expect(entries.length, 3);
      expect(entries.any((e) => e.level == LogLevel.verbose), isFalse);
      expect(entries.any((e) => e.level == LogLevel.debug), isFalse);
      expect(entries[0].message, 'Info message');
      expect(entries[1].message, 'Warning message');
      expect(entries[2].message, 'Error message');
    });

    test('Circular buffer limits size to maxBufferSize', () {
      logger.configure(minLevel: LogLevel.verbose, consoleOutput: false);

      logger.i('Msg 1');
      logger.i('Msg 2');
      logger.i('Msg 3');
      logger.i('Msg 4');

      final entries = logger.entries;
      expect(entries.length, 3);
      expect(entries[0].message, 'Msg 2');
      expect(entries[1].message, 'Msg 3');
      expect(entries[2].message, 'Msg 4');
    });

    test('Stream emits log entries reactively', () async {
      logger.configure(minLevel: LogLevel.debug, consoleOutput: false);

      final streamFuture = logger.stream.take(2).toList();
      logger.d('Stream 1');
      logger.i('Stream 2');

      final emitted = await streamFuture;
      expect(emitted.length, 2);
      expect(emitted[0].message, 'Stream 1');
      expect(emitted[1].message, 'Stream 2');
    });

    test('Clear logs empties the circular buffer', () {
      logger.configure(minLevel: LogLevel.debug, consoleOutput: false);
      logger.i('Message to clear');
      expect(logger.entries.isNotEmpty, isTrue);

      logger.clear();
      expect(logger.entries.isEmpty, isTrue);
    });
  });
}

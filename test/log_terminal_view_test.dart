import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/features/localization/ui/widgets/log_terminal_view.dart';

void main() {
  testWidgets('renders one formatted row per entry with truncated text', (
    tester,
  ) async {
    final entries = [
      LogEntry(
        level: LogLevel.info,
        message: 'Rebuild started',
        tag: 'REBUILD',
        timestamp: DateTime(2026, 1, 1, 12, 34, 56, 789),
      ),
      LogEntry(
        level: LogLevel.error,
        message: 'Export failed',
        tag: 'EXPORT',
        timestamp: DateTime(2026, 1, 1, 12, 34, 56),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LogTerminalView(entries: entries)),
      ),
    );

    expect(
      find.textContaining('[INFO] [REBUILD] Rebuild started'),
      findsOneWidget,
    );
    expect(
      find.textContaining('[ERR ] [EXPORT] Export failed'),
      findsOneWidget,
    );
  });

  testWidgets('renders an empty terminal without entries', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LogTerminalView(entries: [])),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });
}

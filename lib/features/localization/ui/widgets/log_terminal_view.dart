import 'package:flutter/material.dart';
import 'package:gramercy/core/logging/log_entry.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class LogTerminalView extends StatelessWidget {
  final List<LogEntry> entries;

  const LogTerminalView({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView.builder(
        itemCount: entries.length,
        itemExtent: 26.0,
        itemBuilder: (ctx, i) {
          final e = entries[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              e.toFormattedString(),
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 11,
                color: levelColor(e.level),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  static Color levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.warning:
        return AppTheme.primaryAmber;
      case LogLevel.error:
        return AppTheme.alertRed;
      case LogLevel.info:
        return AppTheme.tacticalCyan;
      default:
        return AppTheme.textSecondary;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/log_entry.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/logging_providers.dart';

class LogViewerDialog extends ConsumerStatefulWidget {
  const LogViewerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const LogViewerDialog(),
    );
  }

  @override
  ConsumerState<LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends ConsumerState<LogViewerDialog> {
  String _searchQuery = '';
  LogLevel? _filterLevel;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(logEntriesNotifierProvider);
    final activeLevel = ref.watch(logLevelNotifierProvider);
    final filtered = _filterEntries(entries);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 860,
        height: 560,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, activeLevel),
            const SizedBox(height: 12),
            _buildToolbar(filtered),
            const SizedBox(height: 12),
            Expanded(child: _buildLogTerminal(filtered)),
          ],
        ),
      ),
    );
  }

  List<LogEntry> _filterEntries(List<LogEntry> entries) {
    return entries.where((e) {
      if (_filterLevel != null && e.level.index < _filterLevel!.index) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return e.message.toLowerCase().contains(q) || e.tag.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Widget _buildHeader(BuildContext context, LogLevel activeLevel) {
    return Row(
      children: [
        const Icon(Icons.terminal_rounded, color: AppTheme.primaryAmber, size: 20),
        const SizedBox(width: 8),
        const Text(
          'DIAGNOSTICS CONSOLE',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const Spacer(),
        _buildLevelSelector(activeLevel),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 16,
        ),
      ],
    );
  }

  Widget _buildLevelSelector(LogLevel activeLevel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LogLevel>(
          value: activeLevel,
          dropdownColor: AppTheme.surface,
          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
          items: LogLevel.values
              .where((l) => l != LogLevel.none)
              .map((l) => DropdownMenuItem(value: l, child: Text('Min: ${l.name.toUpperCase()}')))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(logLevelNotifierProvider.notifier).setLogLevel(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildToolbar(List<LogEntry> filtered) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Filter log messages or tags...',
              prefixIcon: const Icon(Icons.search, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 14),
          label: const Text('Copy'),
          onPressed: () => _copyLogs(filtered),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_sweep, size: 14),
          label: const Text('Clear'),
          onPressed: () => ref.read(logEntriesNotifierProvider.notifier).clear(),
        ),
      ],
    );
  }

  Widget _buildLogTerminal(List<LogEntry> entries) {
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
                color: _levelColor(e.level),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  void _copyLogs(List<LogEntry> entries) {
    final text = entries.map((e) => e.toFormattedString()).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${entries.length} log lines to clipboard')),
    );
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.warning: return AppTheme.primaryAmber;
      case LogLevel.error: return AppTheme.alertRed;
      case LogLevel.info: return AppTheme.tacticalCyan;
      default: return AppTheme.textSecondary;
    }
  }
}

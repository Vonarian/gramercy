import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'log_viewer_dialog.dart';

class EditorStatusBar extends ConsumerWidget {
  const EditorStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileName = ref.watch(selectedFileProvider);
    final totalDbOverrides = ref.watch(dbProvider).watchTotalOverridesCount();
    final fileOverrides = ref.watch(dbProvider).watchOverridesCountForFile(fileName);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.storage, size: 13, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            StreamBuilder<int>(
              stream: fileOverrides,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Text(
                  'Delta Vault: $count override(s) in $fileName',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                );
              },
            ),
            const SizedBox(width: 16),
            StreamBuilder<int>(
              stream: totalDbOverrides,
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return Text(
                  '($total total across all files)',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                );
              },
            ),
            const SizedBox(width: 24),
            const Text(
              '• Ponytail Delta-Patching Engine • 120Hz Virtualized',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => LogViewerDialog.show(context),
              child: const Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 13, color: AppTheme.tacticalCyan),
                  SizedBox(width: 4),
                  Text(
                    'Diagnostics',
                    style: TextStyle(fontSize: 11, color: AppTheme.tacticalCyan),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

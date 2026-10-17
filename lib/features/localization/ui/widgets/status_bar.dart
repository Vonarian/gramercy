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
    final totalDbOverrides = ref.watch(totalOverridesCountProvider).value ?? 0;
    final fileOverrides =
        ref.watch(fileOverridesCountProvider(fileName)).value ?? 0;

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
            Text(
              'Delta Vault: $fileOverrides override(s) in $fileName',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '($totalDbOverrides total across all files)',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                  Icon(
                    Icons.terminal_rounded,
                    size: 13,
                    color: AppTheme.tacticalCyan,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Diagnostics',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.tacticalCyan,
                    ),
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

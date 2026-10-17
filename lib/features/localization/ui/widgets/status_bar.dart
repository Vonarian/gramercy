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
            _VaultInfo(
              fileOverrides: fileOverrides,
              fileName: fileName,
              totalDbOverrides: totalDbOverrides,
            ),
            const SizedBox(width: 24),
            const Text(
              '• Ponytail Delta-Patching Engine • 120Hz Virtualized',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(width: 16),
            const _DiagnosticsButton(),
          ],
        ),
      ),
    );
  }
}

class _VaultInfo extends StatelessWidget {
  final int fileOverrides;
  final String fileName;
  final int totalDbOverrides;

  const _VaultInfo({
    required this.fileOverrides,
    required this.fileName,
    required this.totalDbOverrides,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.storage, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(
          'Delta Vault: $fileOverrides override(s) in $fileName',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 16),
        Text(
          '($totalDbOverrides total across all files)',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _DiagnosticsButton extends StatelessWidget {
  const _DiagnosticsButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
    );
  }
}

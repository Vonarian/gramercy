import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/edit_dialog.dart';

class LocalizationRowItem extends StatelessWidget {
  final String fileName;
  final LocalizationEntry entry;
  final int index;
  final VoidCallback? onRevert;

  const LocalizationRowItem({
    super.key,
    required this.fileName,
    required this.entry,
    required this.index,
    this.onRevert,
  });

  @override
  Widget build(BuildContext context) {
    final isOverridden = entry.isOverridden;
    final rowBg = isOverridden
        ? AppTheme.emeraldGreen.withValues(alpha: 0.06)
        : (index.isEven ? AppTheme.background : AppTheme.surface);

    return InkWell(
      onTap: () => EditLocalizationDialog.show(context, fileName: fileName, entry: entry),
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(
            bottom: const BorderSide(color: AppTheme.border, width: 0.5),
            left: isOverridden
                ? const BorderSide(color: AppTheme.emeraldGreen, width: 2.5)
                : const BorderSide(color: Colors.transparent, width: 2.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildKeyColumn(),
            const SizedBox(width: 16),
            _buildBaseValueColumn(),
            const SizedBox(width: 16),
            _buildCustomValueColumn(),
            const SizedBox(width: 12),
            _buildActionsColumn(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyColumn() {
    return SizedBox(
      width: 240,
      child: Text(
        entry.key,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppTheme.monospace.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: entry.isOverridden ? AppTheme.primaryAmber : AppTheme.tacticalCyan,
        ),
      ),
    );
  }

  Widget _buildBaseValueColumn() {
    final baseText = entry.baseValue.isNotEmpty ? entry.baseValue : entry.value;
    return Expanded(
      child: Text(
        baseText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCustomValueColumn() {
    if (!entry.isOverridden) {
      return const Expanded(
        child: Text(
          '—',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      );
    }
    return Expanded(
      child: Text(
        entry.value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionsColumn(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (entry.isOverridden) ...[
            const _ModifiedBadge(),
            const SizedBox(width: 4),
            _buildRevertButton(),
          ],
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
            tooltip: 'Edit Override',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => EditLocalizationDialog.show(context, fileName: fileName, entry: entry),
          ),
        ],
      ),
    );
  }

  Widget _buildRevertButton() {
    if (onRevert != null) {
      return IconButton(
        icon: const Icon(Icons.undo, size: 15, color: AppTheme.alertRed),
        tooltip: 'Revert to Base Game',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        onPressed: onRevert,
      );
    }
    return Consumer(
      builder: (context, ref, _) => IconButton(
        icon: const Icon(Icons.undo, size: 15, color: AppTheme.alertRed),
        tooltip: 'Revert to Base Game',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        onPressed: () => revertLocalizationOverride(
          ref: ref,
          fileName: fileName,
          key: entry.key,
        ),
      ),
    );
  }
}

class _ModifiedBadge extends StatelessWidget {
  const _ModifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'MODIFIED',
        style: TextStyle(
          color: AppTheme.emeraldGreen,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

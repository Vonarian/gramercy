import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/edit_dialog.dart';

class LocalizationRowItem extends ConsumerWidget {
  final String fileName;
  final LocalizationEntry entry;
  final int index;

  const LocalizationRowItem({
    super.key,
    required this.fileName,
    required this.entry,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverridden = entry.isOverridden;
    final rowBg = isOverridden
        ? AppTheme.emeraldGreen.withValues(alpha: 0.08)
        : (index.isEven ? AppTheme.background : AppTheme.surface);

    return InkWell(
      onTap: () => EditLocalizationDialog.show(context, fileName: fileName, entry: entry),
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(
            bottom: const BorderSide(color: AppTheme.border, width: 0.5),
            left: isOverridden
                ? const BorderSide(color: AppTheme.emeraldGreen, width: 3.0)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildKeyColumn(),
            const SizedBox(width: 16),
            _buildValueColumn(),
            const SizedBox(width: 12),
            if (isOverridden) ...[
              _buildModifiedBadge(),
              const SizedBox(width: 8),
              _buildRevertButton(ref),
            ],
            _buildEditButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyColumn() {
    return SizedBox(
      width: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.key,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.tacticalCyan,
            ),
          ),
          if (entry.isOverridden && entry.baseValue.isNotEmpty)
            Text(
              'Orig: ${entry.baseValue}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildValueColumn() {
    return Expanded(
      child: Text(
        entry.value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: entry.isOverridden ? FontWeight.w600 : FontWeight.normal,
          color: entry.isOverridden ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildModifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.4)),
      ),
      child: const Text(
        'MODIFIED',
        style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRevertButton(WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.undo, size: 16, color: AppTheme.alertRed),
      tooltip: 'Revert to Base Game',
      onPressed: () => revertLocalizationOverride(ref: ref, fileName: fileName, key: entry.key),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMuted),
      tooltip: 'Edit Override',
      onPressed: () => EditLocalizationDialog.show(context, fileName: fileName, entry: entry),
    );
  }
}

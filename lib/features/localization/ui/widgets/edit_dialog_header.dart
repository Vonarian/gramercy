import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class EditDialogHeader extends StatelessWidget {
  final String fileName;
  final bool isOverridden;

  const EditDialogHeader({
    super.key,
    required this.fileName,
    required this.isOverridden,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.edit_note,
            color: AppTheme.primaryAmber,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Localization String',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                fileName,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        if (isOverridden)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.emeraldGreen.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'MODIFIED',
              style: TextStyle(
                color: AppTheme.emeraldGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

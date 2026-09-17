import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class EditDialogActions extends StatelessWidget {
  final bool isOverridden;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onRevert;

  const EditDialogActions({
    super.key,
    required this.isOverridden,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
    required this.onRevert,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isOverridden)
          OutlinedButton.icon(
            onPressed: isSaving ? null : onRevert,
            icon: const Icon(Icons.undo, size: 16, color: AppTheme.alertRed),
            label: const Text(
              'Revert to Base',
              style: TextStyle(color: AppTheme.alertRed),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.alertRed.withValues(alpha: 0.5)),
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: isSaving ? null : onCancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('Save Override'),
        ),
      ],
    );
  }
}

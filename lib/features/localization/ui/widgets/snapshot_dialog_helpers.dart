import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SnapshotEmptyState extends StatelessWidget {
  const SnapshotEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text(
            'No snapshots saved yet.\nAutomatic snapshots are created before War Thunder updates.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

Future<String?> promptSnapshotName(BuildContext context) {
  final controller = TextEditingController(text: 'Manual Checkpoint');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Create Snapshot'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Snapshot Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            Navigator.of(ctx).pop(text.isEmpty ? 'Manual Checkpoint' : text);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<bool?> confirmSnapshotDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

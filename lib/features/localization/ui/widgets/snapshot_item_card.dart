import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/snapshot_models.dart';

class SnapshotItemCard extends StatelessWidget {
  final SnapshotMetadata snapshot;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const SnapshotItemCard({
    super.key,
    required this.snapshot,
    required this.onRestore,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(child: _buildDetails()),
          const SizedBox(width: 12),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                snapshot.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(snapshot.createdAt),
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '${snapshot.totalOverrides} strings',
        style: const TextStyle(
          color: AppTheme.primaryAmber,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: onRestore,
          icon: const Icon(Icons.restore, size: 16),
          label: const Text('Restore', style: TextStyle(fontSize: 12)),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.primaryAmber,
            side: const BorderSide(color: AppTheme.border),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: AppTheme.textSecondary,
          ),
          tooltip: 'Delete Snapshot',
          splashRadius: 18,
        ),
      ],
    );
  }
}

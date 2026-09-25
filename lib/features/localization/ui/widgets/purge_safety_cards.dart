import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class PurgeSafetyInfo extends StatelessWidget {
  const PurgeSafetyInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• Auto-Backup: A full backup of lang/ will be saved to lang_backups/.',
            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
          ),
          SizedBox(height: 6),
          Text(
            '• Vault Preserved: All your saved custom overrides in SQLite are safe.',
            style: TextStyle(fontSize: 12, color: AppTheme.primaryAmber),
          ),
          SizedBox(height: 6),
          Text(
            '• Clean Regeneration: Deletes localization.blk and CSVs to force fresh game dumps.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class GameRunningStatus extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onRecheck;

  const GameRunningStatus({
    super.key,
    required this.isRunning,
    required this.onRecheck,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRunning) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 16),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'War Thunder is closed. Ready to purge safely.',
              style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreen),
            ),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.alertRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.alertRed),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.alertRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'War Thunder is running! Close the game before purging.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.alertRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: onRecheck,
            child: const Text('Recheck', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

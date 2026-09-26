import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/services/rebuild_service.dart';
import 'package:gramercy/features/localization/ui/widgets/purge_safety_cards.dart';

class PurgeConfirmDialog extends ConsumerStatefulWidget {
  final String wtPath;
  final VoidCallback onConfirmed;

  const PurgeConfirmDialog({
    super.key,
    required this.wtPath,
    required this.onConfirmed,
  });

  @override
  ConsumerState<PurgeConfirmDialog> createState() => _PurgeConfirmDialogState();
}

class _PurgeConfirmDialogState extends ConsumerState<PurgeConfirmDialog> {
  bool _isChecking = true;
  bool _isGameRunning = false;

  @override
  void initState() {
    super.initState();
    _checkProcess();
  }

  Future<void> _checkProcess() async {
    setState(() => _isChecking = true);
    final service = ref.read(rebuildServiceProvider);
    final running = await service.isGameRunning();
    if (mounted) {
      setState(() {
        _isGameRunning = running;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            const PurgeSafetyInfo(),
            const SizedBox(height: 14),
            _buildProcessWarning(),
            const SizedBox(height: 18),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.shield_outlined, color: AppTheme.primaryAmber, size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Confirm Cache Purge & Backup',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessWarning() {
    if (_isChecking) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Checking War Thunder process...',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      );
    }
    return GameRunningStatus(
      isRunning: _isGameRunning,
      onRecheck: _checkProcess,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _isGameRunning
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onConfirmed();
                },
          icon: const Icon(Icons.delete_sweep, size: 16),
          label: const Text('Backup & Purge Cache'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryAmber,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppTheme.surfaceElevated,
            disabledForegroundColor: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

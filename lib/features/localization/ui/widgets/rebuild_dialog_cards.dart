import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/ui/widgets/rebuild_step_card.dart';

class RebuildStep1Card extends StatelessWidget {
  final bool isPurging;
  final bool isPurged;
  final String? purgeMessage;
  final VoidCallback onPurgeTap;

  const RebuildStep1Card({
    super.key,
    required this.isPurging,
    required this.isPurged,
    required this.purgeMessage,
    required this.onPurgeTap,
  });

  @override
  Widget build(BuildContext context) {
    return RebuildStepCard(
      title: 'Step 1: Purge Localization Cache',
      subtitle: 'Backs up and clears lang/ to force vanilla string dump.',
      action: ElevatedButton.icon(
        onPressed: isPurging ? null : onPurgeTap,
        icon: isPurging
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_sweep, size: 16),
        label: Text(isPurged ? 'Purge Again' : 'Purge Cache'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceElevated,
          foregroundColor: AppTheme.primaryAmber,
        ),
      ),
      statusText: purgeMessage,
      isSuccess: isPurged,
    );
  }
}

class RebuildStep2Card extends StatelessWidget {
  final bool isLaunching;
  final bool isPurged;
  final bool hasFiles;
  final int fileCount;
  final VoidCallback onLaunchTap;

  const RebuildStep2Card({
    super.key,
    required this.isLaunching,
    this.isPurged = false,
    required this.hasFiles,
    required this.fileCount,
    required this.onLaunchTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = !isPurged
        ? 'Awaiting Step 1 cache purge...'
        : (hasFiles
              ? 'Fresh strings detected ($fileCount CSV files)'
              : 'Waiting for fresh CSVs... (launch game to hangar)');

    return RebuildStepCard(
      title: 'Step 2: Generate Fresh Strings',
      subtitle: isPurged
          ? 'Launch War Thunder to the hangar once to extract new CSVs.'
          : 'Complete Step 1 cache purge first.',
      action: ElevatedButton.icon(
        onPressed: (isLaunching || !isPurged) ? null : onLaunchTap,
        icon: const Icon(Icons.play_arrow, size: 16),
        label: Text(isLaunching ? 'Launching...' : 'Launch War Thunder'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceElevated,
          foregroundColor: AppTheme.tacticalCyan,
        ),
      ),
      statusText: statusText,
      isSuccess: isPurged && hasFiles,
    );
  }
}

class RebuildStep3Card extends StatelessWidget {
  final bool isReloading;
  final bool canReload;
  final String? rebuildMessage;
  final VoidCallback onReloadTap;

  const RebuildStep3Card({
    super.key,
    required this.isReloading,
    required this.canReload,
    required this.rebuildMessage,
    required this.onReloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return RebuildStepCard(
      title: 'Step 3: Reload & Apply Customizations',
      subtitle:
          'Re-synthesizes all your saved delta overrides with new game files.',
      action: ElevatedButton.icon(
        onPressed: canReload ? onReloadTap : null,
        icon: isReloading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Reload & Apply'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryAmber,
          foregroundColor: Colors.black,
        ),
      ),
      statusText: rebuildMessage,
      isSuccess: rebuildMessage?.startsWith('Done') ?? false,
    );
  }
}

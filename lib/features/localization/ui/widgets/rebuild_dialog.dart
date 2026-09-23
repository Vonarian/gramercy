import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/services/rebuild_service.dart';
import 'package:gramercy/features/localization/ui/widgets/rebuild_step_card.dart';

class RebuildDialog extends ConsumerStatefulWidget {
  const RebuildDialog({super.key});

  @override
  ConsumerState<RebuildDialog> createState() => _RebuildDialogState();
}

class _RebuildDialogState extends ConsumerState<RebuildDialog> {
  bool _isPurging = false;
  bool _isPurged = false;
  String? _purgeMessage;

  bool _isLaunching = false;
  Timer? _detectTimer;
  FreshStringsStatus _freshStatus = const FreshStringsStatus(
    hasFiles: false,
    fileCount: 0,
  );

  bool _isReloading = false;
  String? _rebuildMessage;

  @override
  void initState() {
    super.initState();
    _startDetectionPolling();
  }

  @override
  void dispose() {
    _detectTimer?.cancel();
    super.dispose();
  }

  void _startDetectionPolling() {
    _detectTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      final wtPath = ref.read(wtPathProvider);
      if (wtPath == null || wtPath.isEmpty) return;

      final service = ref.read(rebuildServiceProvider);
      final status = await service.checkFreshStringsExist(wtPath);
      if (mounted) {
        setState(() => _freshStatus = status);
      }
    });
  }

  Future<void> _handlePurge(String wtPath) async {
    setState(() {
      _isPurging = true;
      _purgeMessage = null;
    });
    final service = ref.read(rebuildServiceProvider);
    final res = await service.purgeLocalizationCache(wtPath);
    if (!mounted) return;

    setState(() {
      _isPurging = false;
      _isPurged = res.success;
      _purgeMessage = res.success
          ? 'Purged ${res.deletedCount} files. config.blk verified.'
          : 'Error: ${res.errorMessage}';
    });
  }

  Future<void> _handleLaunch(String wtPath) async {
    setState(() => _isLaunching = true);
    final service = ref.read(rebuildServiceProvider);
    await service.launchWarThunder(wtPath);
    if (mounted) setState(() => _isLaunching = false);
  }

  Future<void> _handleReload(String wtPath) async {
    setState(() {
      _isReloading = true;
      _rebuildMessage = null;
    });
    final service = ref.read(rebuildServiceProvider);
    final res = await service.reloadAndSynthesize(ref: ref, wtPath: wtPath);
    if (!mounted) return;

    setState(() {
      _isReloading = false;
      _rebuildMessage = res.success
          ? 'Done! ${res.filesReloaded} files reloaded, ${res.overridesApplied} overrides applied.'
          : 'Error: ${res.errorMessage}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final wtPath = ref.watch(wtPathProvider) ?? '';

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RebuildDialogHeader(),
            const SizedBox(height: 16),
            _buildStep1Purge(wtPath),
            const SizedBox(height: 12),
            _buildStep2Generate(wtPath),
            const SizedBox(height: 12),
            _buildStep3Deploy(wtPath),
            const SizedBox(height: 16),
            _buildFooterActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Purge(String wtPath) {
    return RebuildStepCard(
      title: 'Step 1: Purge Localization Cache',
      subtitle: 'Deletes old CSVs and stale .orig files; enables config.blk.',
      action: ElevatedButton.icon(
        onPressed: _isPurging ? null : () => _handlePurge(wtPath),
        icon: _isPurging
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_sweep, size: 16),
        label: Text(_isPurged ? 'Purge Again' : 'Purge Cache'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceElevated,
          foregroundColor: AppTheme.primaryAmber,
        ),
      ),
      statusText: _purgeMessage,
      isSuccess: _isPurged,
    );
  }

  Widget _buildStep2Generate(String wtPath) {
    final detected = _freshStatus.hasFiles;
    return RebuildStepCard(
      title: 'Step 2: Generate Fresh Strings',
      subtitle: 'Launch War Thunder to the hangar once to extract new CSVs.',
      action: ElevatedButton.icon(
        onPressed: _isLaunching ? null : () => _handleLaunch(wtPath),
        icon: const Icon(Icons.play_arrow, size: 16),
        label: Text(_isLaunching ? 'Launching...' : 'Launch War Thunder'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceElevated,
          foregroundColor: AppTheme.tacticalCyan,
        ),
      ),
      statusText: detected
          ? 'Fresh strings detected (${_freshStatus.fileCount} CSV files)'
          : 'Waiting for fresh CSVs... (launch game to hangar)',
      isSuccess: detected,
    );
  }

  Widget _buildStep3Deploy(String wtPath) {
    final canReload = _freshStatus.hasFiles && !_isReloading;
    return RebuildStepCard(
      title: 'Step 3: Reload & Apply Customizations',
      subtitle:
          'Re-synthesizes all your saved delta overrides with new game files.',
      action: ElevatedButton.icon(
        onPressed: canReload ? () => _handleReload(wtPath) : null,
        icon: _isReloading
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
      statusText: _rebuildMessage,
      isSuccess: _rebuildMessage?.startsWith('Done') ?? false,
    );
  }

  Widget _buildFooterActions() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    );
  }
}

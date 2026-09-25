import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/services/rebuild_service.dart';
import 'package:gramercy/features/localization/ui/widgets/purge_confirm_dialog.dart';
import 'package:gramercy/features/localization/ui/widgets/rebuild_dialog_cards.dart';
import 'package:gramercy/features/localization/ui/widgets/rebuild_step_card.dart';

class RebuildDialog extends ConsumerStatefulWidget {
  const RebuildDialog({super.key});

  @override
  ConsumerState<RebuildDialog> createState() => _RebuildDialogState();
}

class _RebuildDialogState extends ConsumerState<RebuildDialog> {
  bool _isPurging = false;
  bool _isPurged = false;
  DateTime? _purgedAt;
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
      if (!_isPurged || _purgedAt == null) return;
      final wtPath = ref.read(wtPathProvider);
      if (wtPath == null || wtPath.isEmpty) return;

      final service = ref.read(rebuildServiceProvider);
      final status = await service.checkFreshStringsExist(
        wtPath,
        since: _purgedAt,
      );
      if (mounted && _isPurged) setState(() => _freshStatus = status);
    });
  }

  void _confirmAndPurge(BuildContext context, String wtPath) {
    showDialog(
      context: context,
      builder: (_) => PurgeConfirmDialog(
        wtPath: wtPath,
        onConfirmed: () => _handlePurge(wtPath),
      ),
    );
  }

  Future<void> _handlePurge(String wtPath) async {
    setState(() {
      _isPurging = true;
      _purgeMessage = null;
      _freshStatus = const FreshStringsStatus(hasFiles: false, fileCount: 0);
    });
    final service = ref.read(rebuildServiceProvider);
    final res = await service.purgeLocalizationCache(wtPath);
    if (!mounted) return;

    setState(() {
      _isPurging = false;
      _isPurged = res.success;
      _purgedAt = res.purgedAt;
      _purgeMessage = res.success
          ? 'Purged ${res.deletedCount} files (backup saved).'
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RebuildDialogHeader(),
              const SizedBox(height: 16),
              RebuildStep1Card(
                isPurging: _isPurging,
                isPurged: _isPurged,
                purgeMessage: _purgeMessage,
                onPurgeTap: () => _confirmAndPurge(context, wtPath),
              ),
              const SizedBox(height: 12),
              RebuildStep2Card(
                isLaunching: _isLaunching,
                isPurged: _isPurged,
                hasFiles: _freshStatus.hasFiles,
                fileCount: _freshStatus.fileCount,
                onLaunchTap: () => _handleLaunch(wtPath),
              ),
              const SizedBox(height: 12),
              RebuildStep3Card(
                isReloading: _isReloading,
                canReload: _isPurged && _freshStatus.hasFiles && !_isReloading,
                rebuildMessage: _rebuildMessage,
                onReloadTap: () => _handleReload(wtPath),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

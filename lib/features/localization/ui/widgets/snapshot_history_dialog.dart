import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/snapshot_models.dart';
import '../../providers/localization_providers.dart';
import 'snapshot_dialog_helpers.dart';
import 'snapshot_item_card.dart';

class SnapshotHistoryDialog extends ConsumerStatefulWidget {
  const SnapshotHistoryDialog({super.key});

  @override
  ConsumerState<SnapshotHistoryDialog> createState() =>
      _SnapshotHistoryDialogState();
}

class _SnapshotHistoryDialogState extends ConsumerState<SnapshotHistoryDialog> {
  List<SnapshotMetadata> _snapshots = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    setState(() => _isLoading = true);
    final service = ref.read(snapshotServiceProvider);
    final list = await service.listSnapshots();
    if (!mounted) return;
    setState(() {
      _snapshots = list;
      _isLoading = false;
    });
  }

  Future<void> _createSnapshot() async {
    final label = await promptSnapshotName(context);
    if (label == null || !mounted) return;

    final service = ref.read(snapshotServiceProvider);
    final created = await service.createSnapshot(label: label);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (created == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No custom overrides to snapshot.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text('Snapshot "${created.name}" created.')),
      );
      await _loadSnapshots();
    }
  }

  Future<void> _restoreSnapshot(SnapshotMetadata snapshot) async {
    final confirmed = await confirmSnapshotDialog(
      context: context,
      title: 'Restore Snapshot?',
      message:
          'Restore "${snapshot.name}" (${snapshot.totalOverrides} strings)?\n\nExisting overrides will be updated with snapshot values.',
      confirmLabel: 'Confirm Restore',
    );
    if (confirmed != true || !mounted) return;

    final service = ref.read(snapshotServiceProvider);
    final count = await service.restoreSnapshot(snapshot.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored $count strings from "${snapshot.name}".'),
      ),
    );
  }

  Future<void> _deleteSnapshot(SnapshotMetadata snapshot) async {
    final confirmed = await confirmSnapshotDialog(
      context: context,
      title: 'Delete Snapshot?',
      message:
          'Are you sure you want to delete "${snapshot.name}"?\nThis action cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || !mounted) return;

    final service = ref.read(snapshotServiceProvider);
    await service.deleteSnapshot(snapshot.id);
    if (!mounted) return;

    await _loadSnapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Container(
        width: 580,
        height: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.history, color: AppTheme.primaryAmber, size: 22),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Edit History & Snapshots',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _createSnapshot,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('+ New Snapshot'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryAmber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 18),
          splashRadius: 18,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAmber),
      );
    }
    if (_snapshots.isEmpty) {
      return const SnapshotEmptyState();
    }
    return ListView.separated(
      itemCount: _snapshots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final snap = _snapshots[index];
        return SnapshotItemCard(
          snapshot: snap,
          onRestore: () => _restoreSnapshot(snap),
          onDelete: () => _deleteSnapshot(snap),
        );
      },
    );
  }
}

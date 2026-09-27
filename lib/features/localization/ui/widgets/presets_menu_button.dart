import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/db_provider.dart';
import '../../services/preset_service.dart';
import 'snapshot_history_dialog.dart';

class PresetsMenuButton extends ConsumerWidget {
  const PresetsMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Community Presets (Share & Import)',
      icon: const Icon(Icons.share, size: 18, color: AppTheme.textSecondary),
      color: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.border),
      ),
      onSelected: (action) {
        if (action == 'export') {
          _exportPreset(context, ref);
        } else if (action == 'import') {
          _importPreset(context, ref);
        } else if (action == 'snapshots') {
          showDialog<void>(
            context: context,
            builder: (_) => const SnapshotHistoryDialog(),
          );
        }
      },
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() => [
    _buildItem('export', Icons.file_upload_outlined, 'Export Preset (.json)'),
    _buildItem('import', Icons.file_download_outlined, 'Import Preset (.json)'),
    _buildItem('snapshots', Icons.history, 'Snapshot History...'),
  ];

  PopupMenuItem<String> _buildItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryAmber),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _exportPreset(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final overrides = await db.getAllOverrides();

    if (!context.mounted) return;
    if (overrides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No custom overrides to export.')),
      );
      return;
    }

    final jsonStr = ref.read(presetServiceProvider).serializePreset(overrides);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));

    final savedUri = await FilePicker.saveFile(
      dialogTitle: 'Export Gramercy Preset',
      fileName: 'gramercy_overrides.json',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (savedUri == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${overrides.length} overrides to preset.'),
        ),
      );
    }
  }

  Future<void> _importPreset(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Import Gramercy Preset',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (picked == null) return;

    try {
      final jsonStr = await _readFileContent(picked);
      if (jsonStr == null || !context.mounted) return;

      final companions = ref
          .read(presetServiceProvider)
          .deserializePreset(jsonStr);
      await _importCompanions(context, ref, companions);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import preset: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _importCompanions(
    BuildContext context,
    WidgetRef ref,
    List<LocalizationsOverridesCompanion> companions,
  ) async {
    if (companions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preset contains no valid overrides.')),
        );
      }
      return;
    }

    final count = await ref.read(dbProvider).batchUpsertOverrides(companions);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $count overrides from preset!'),
        ),
      );
    }
  }

  Future<String?> _readFileContent(PlatformFile picked) async {
    final bytes = await picked.readAsBytes();
    return utf8.decode(bytes);
  }
}

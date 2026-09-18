import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/db_provider.dart';
import '../../services/preset_service.dart';

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
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'export',
          child: Row(
            children: [
              Icon(
                Icons.file_upload_outlined,
                size: 18,
                color: AppTheme.primaryAmber,
              ),
              SizedBox(width: 8),
              Text('Export Preset (.json)', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'import',
          child: Row(
            children: [
              Icon(
                Icons.file_download_outlined,
                size: 18,
                color: AppTheme.primaryAmber,
              ),
              SizedBox(width: 8),
              Text('Import Preset (.json)', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
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
      if (jsonStr == null) return;

      final companions = ref
          .read(presetServiceProvider)
          .deserializePreset(jsonStr);

      if (companions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preset contains no valid overrides.'),
            ),
          );
        }
        return;
      }

      final count = await ref.read(dbProvider).batchUpsertOverrides(companions);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported $count overrides from preset!',
            ),
          ),
        );
      }
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

  Future<String?> _readFileContent(PlatformFile picked) async {
    final bytes = await picked.readAsBytes();
    return utf8.decode(bytes);
  }
}

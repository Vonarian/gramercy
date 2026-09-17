import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/config_status_pill.dart';

class CommandHeader extends ConsumerWidget {
  const CommandHeader({super.key});

  Future<void> _pickDirectory(BuildContext context, WidgetRef ref) async {
    final selectedDir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select War Thunder Root Directory',
    );
    if (selectedDir != null && selectedDir.isNotEmpty) {
      await ref.read(wtPathProvider.notifier).setPath(selectedDir);
      ref.invalidate(availableFilesProvider);
      ref.invalidate(configBlkStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wtPath = ref.watch(wtPathProvider);
    final autoExport = ref.watch(autoExportProvider);
    final selectedFile = ref.watch(selectedFileProvider);
    final availableFilesAsync = ref.watch(availableFilesProvider);
    final exportState = ref.watch(exportNotifierProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTacticalBadge(),
              const SizedBox(width: 16),
              Expanded(child: _buildPathSelector(context, ref, wtPath)),
              const SizedBox(width: 12),
              const ConfigStatusPill(),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActiveFileLabel(),
                const SizedBox(width: 8),
                _buildFileDropdown(ref, selectedFile, availableFilesAsync),
                const SizedBox(width: 24),
                _buildAutoExportToggle(ref, autoExport),
                const SizedBox(width: 16),
                _buildDeployButton(ref, exportState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryAmber,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, color: Colors.black, size: 16),
          SizedBox(width: 6),
          Text(
            'WT LOCALIZATION ENGINE',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathSelector(BuildContext context, WidgetRef ref, String? wtPath) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              wtPath ?? 'War Thunder root directory not configured',
              style: TextStyle(
                fontSize: 12,
                color: wtPath != null ? AppTheme.textPrimary : AppTheme.alertRed,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _pickDirectory(context, ref),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text('Browse', style: TextStyle(color: AppTheme.primaryAmber, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              final detected = ref.read(wtPathProvider.notifier).autoDetect();
              if (detected) {
                ref.invalidate(availableFilesProvider);
                ref.invalidate(configBlkStatusProvider);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text('Auto-Detect', style: TextStyle(color: AppTheme.tacticalCyan, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFileLabel() {
    return const Text('ACTIVE FILE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.6));
  }

  Widget _buildFileDropdown(WidgetRef ref, String selectedFile, AsyncValue<List<String>> availableFilesAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: availableFilesAsync.when(
          data: (files) {
            final effectiveFiles = files.contains(selectedFile) ? files : [selectedFile, ...files];
            return DropdownButton<String>(
              value: selectedFile,
              dropdownColor: AppTheme.surfaceElevated,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              items: effectiveFiles.map((file) => DropdownMenuItem(value: file, child: Text(file, style: const TextStyle(fontFamily: 'Consolas')))).toList(),
              onChanged: (newFile) {
                if (newFile != null) ref.read(selectedFileProvider.notifier).selectFile(newFile);
              },
            );
          },
          loading: () => Text(selectedFile),
          error: (err, _) => Text(selectedFile),
        ),
      ),
    );
  }

  Widget _buildAutoExportToggle(WidgetRef ref, bool autoExport) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Auto-Deploy on Save', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 6),
        Switch(value: autoExport, activeTrackColor: AppTheme.primaryAmber, onChanged: (val) => ref.read(autoExportProvider.notifier).setVal(val)),
      ],
    );
  }

  Widget _buildDeployButton(WidgetRef ref, ExportState exportState) {
    final inProgress = exportState.status == ExportStatus.inProgress;
    return ElevatedButton.icon(
      onPressed: inProgress ? null : () => ref.read(exportNotifierProvider.notifier).exportCurrentFile(),
      icon: inProgress
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
          : const Icon(Icons.rocket_launch, size: 16, color: Colors.black),
      label: Text(inProgress ? 'Deploying...' : 'Deploy to Game', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }
}

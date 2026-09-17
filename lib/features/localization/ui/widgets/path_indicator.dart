import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

class PathIndicator extends ConsumerWidget {
  const PathIndicator({super.key});

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
    final hasPath = wtPath != null && wtPath.isNotEmpty;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hasPath
              ? AppTheme.border
              : AppTheme.alertRed.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPath ? Icons.folder_outlined : Icons.folder_off_outlined,
            size: 15,
            color: hasPath ? AppTheme.textSecondary : AppTheme.alertRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasPath ? wtPath : 'War Thunder directory not set',
              style: TextStyle(
                fontSize: 12,
                color: hasPath ? AppTheme.textPrimary : AppTheme.alertRed,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildBrowseAction(context, ref),
          if (!hasPath) ...[
            const SizedBox(width: 6),
            _buildAutoDetectAction(ref),
          ],
        ],
      ),
    );
  }

  Widget _buildBrowseAction(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _pickDirectory(context, ref),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          'Browse',
          style: TextStyle(
            color: AppTheme.primaryAmber,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoDetectAction(WidgetRef ref) {
    return InkWell(
      onTap: () {
        final detected = ref.read(wtPathProvider.notifier).autoDetect();
        if (detected) {
          ref.invalidate(availableFilesProvider);
          ref.invalidate(configBlkStatusProvider);
        }
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          'Auto-Detect',
          style: TextStyle(
            color: AppTheme.tacticalCyan,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

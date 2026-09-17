import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

class EmptyStateView extends ConsumerWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wtPath = ref.watch(wtPathProvider);
    final fileName = ref.watch(selectedFileProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    if (wtPath == null || wtPath.isEmpty) {
      return _buildNoDirectoryState(ref);
    }

    if (searchQuery.isNotEmpty) {
      return _buildNoSearchMatchesState(searchQuery);
    }

    return _buildEmptyFileState(fileName);
  }

  Widget _buildNoDirectoryState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.military_tech_outlined, size: 64, color: AppTheme.primaryAmber),
            const SizedBox(height: 16),
            const Text(
              'Welcome to War Thunder Localization Editor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your War Thunder installation directory above to begin editing.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref.read(wtPathProvider.notifier).autoDetect(),
              icon: const Icon(Icons.auto_awesome, color: Colors.black, size: 16),
              label: const Text('Auto-Detect Installation', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchMatchesState(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text('No strings found matching "$query"', style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildEmptyFileState(String fileName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No entries in $fileName', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'If the lang/ directory is empty, click "Enable in config.blk" and run War Thunder once.\nThe game will automatically generate all localization CSVs into the lang/ directory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

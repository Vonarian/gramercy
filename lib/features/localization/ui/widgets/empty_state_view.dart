import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/config_status_pill.dart';

class EmptyStateView extends ConsumerWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wtPath = ref.watch(wtPathProvider);
    final fileName = ref.watch(selectedFileProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    if (wtPath == null || wtPath.isEmpty) {
      return _buildOnboarding(context, ref);
    }
    if (searchQuery.isNotEmpty) {
      return _buildNoSearchMatches(ref, searchQuery);
    }
    return _buildEmptyFileState(context, ref, fileName);
  }

  Widget _buildOnboarding(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.radio, size: 56, color: AppTheme.primaryAmber),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'War Thunder Localization Setup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Follow these quick steps to inspect and edit in-game strings:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildStepCard(
                step: '1',
                title: 'Set War Thunder Directory',
                subtitle: 'Locate your War Thunder installation folder.',
                action: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final ok = ref.read(wtPathProvider.notifier).autoDetect();
                        if (ok) {
                          ref.invalidate(availableFilesProvider);
                          ref.invalidate(configBlkStatusProvider);
                        }
                      },
                      icon: const Icon(Icons.auto_awesome, size: 14, color: Colors.black),
                      label: const Text('Auto-Detect', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final dir = await FilePicker.getDirectoryPath(dialogTitle: 'Select War Thunder Directory');
                        if (dir != null && dir.isNotEmpty) {
                          await ref.read(wtPathProvider.notifier).setPath(dir);
                          ref.invalidate(availableFilesProvider);
                          ref.invalidate(configBlkStatusProvider);
                        }
                      },
                      icon: const Icon(Icons.folder_open, size: 14),
                      label: const Text('Browse Folder'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildStepCard(
                step: '2',
                title: 'Enable Localization in config.blk',
                subtitle: 'War Thunder must have "testLocalization:b=yes" in its config.blk to load custom strings.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({required String step, required String title, required String subtitle, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primaryAmber.withValues(alpha: 0.2),
            child: Text(step, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (action != null) ...[const SizedBox(height: 12), action],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchMatches(WidgetRef ref, String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 40, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text('No strings matching "$query"', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(searchQueryProvider.notifier).clear(),
            child: const Text('Clear Search Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFileState(BuildContext context, WidgetRef ref, String fileName) {
    final configStatusAsync = ref.watch(configBlkStatusProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No entries in $fileName', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            const Text(
              'If the lang/ directory is empty, make sure testLocalization is enabled in config.blk\nand launch War Thunder once so it writes default CSV files.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            configStatusAsync.when(
              data: (status) {
                if (!status.isLocalizationEnabled && status.exists) {
                  return ElevatedButton.icon(
                    onPressed: () => patchConfigBlkHelper(ref),
                    icon: const Icon(Icons.tune, size: 14, color: Colors.black),
                    label: const Text('Enable in config.blk', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

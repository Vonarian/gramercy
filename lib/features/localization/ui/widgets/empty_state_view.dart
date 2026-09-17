import 'package:gramercy/features/localization/ui/widgets/onboarding_setup_view.dart';
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
      return const OnboardingSetupView();
    }
    if (searchQuery.isNotEmpty) {
      return _buildNoSearchMatches(ref, searchQuery);
    }
    return _buildEmptyFileState(context, ref, fileName);
  }

  Widget _buildNoSearchMatches(WidgetRef ref, String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 40, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            'No strings matching "$query"',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => ref.read(searchQueryProvider.notifier).clear(),
            child: const Text('Clear Search Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFileState(
    BuildContext context,
    WidgetRef ref,
    String fileName,
  ) {
    final configStatusAsync = ref.watch(configBlkStatusProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No entries in $fileName',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
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
                    label: const Text(
                      'Enable in config.blk',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/setup_step_card.dart';

class OnboardingSetupView extends ConsumerWidget {
  const OnboardingSetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.radio,
                    size: 56,
                    color: AppTheme.primaryAmber,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'War Thunder Localization Setup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Follow these quick steps to inspect and edit in-game strings:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SetupStepCard(
                step: '1',
                title: 'Set War Thunder Directory',
                subtitle: 'Locate your War Thunder installation folder.',
                action: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final ok = ref
                            .read(wtPathProvider.notifier)
                            .autoDetect();
                        if (ok) {
                          ref.invalidate(availableFilesProvider);
                          ref.invalidate(configBlkStatusProvider);
                        }
                      },
                      icon: const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Auto-Detect',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final dir = await FilePicker.getDirectoryPath(
                          dialogTitle: 'Select War Thunder Directory',
                        );
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
              const SetupStepCard(
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
}

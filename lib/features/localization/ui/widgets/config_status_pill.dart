import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:path/path.dart' as p;

Future<void> patchConfigBlkHelper(WidgetRef ref) async {
  final wtPath = ref.read(wtPathProvider);
  if (wtPath == null) return;
  final worker = ref.read(workerServiceProvider);
  final configBlkPath = p.join(wtPath, 'config.blk');
  await worker.patchConfigBlk(configBlkPath);
  ref.invalidate(configBlkStatusProvider);
}

class ConfigStatusPill extends ConsumerWidget {
  const ConfigStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configStatusAsync = ref.watch(configBlkStatusProvider);

    return configStatusAsync.when(
      data: (status) {
        if (!status.exists) return const SizedBox.shrink();
        if (status.isLocalizationEnabled) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 14),
                SizedBox(width: 6),
                Text(
                  'testLocalization: ACTIVE',
                  style: TextStyle(
                    color: AppTheme.emeraldGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
        return OutlinedButton.icon(
          onPressed: () => patchConfigBlkHelper(ref),
          icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.primaryAmber, size: 14),
          label: const Text('Enable in config.blk', style: TextStyle(color: AppTheme.primaryAmber, fontSize: 11)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryAmber),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, _) => const SizedBox.shrink(),
    );
  }
}

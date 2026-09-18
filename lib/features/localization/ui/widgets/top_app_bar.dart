import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/about_gramercy_dialog.dart';
import 'package:gramercy/features/localization/ui/widgets/config_status_pill.dart';
import 'package:gramercy/features/localization/ui/widgets/log_viewer_dialog.dart';
import 'package:gramercy/features/localization/ui/widgets/path_indicator.dart';
import 'package:gramercy/features/localization/ui/widgets/presets_menu_button.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoExport = ref.watch(autoExportProvider);
    final exportState = ref.watch(exportNotifierProvider);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1.0)),
      ),
      child: Row(
        children: [
          _buildBrand(context),
          const SizedBox(width: 16),
          const Expanded(child: PathIndicator()),
          const SizedBox(width: 12),
          const ConfigStatusPill(),
          const SizedBox(width: 16),
          _buildAutoExportSwitch(ref, autoExport),
          const SizedBox(width: 12),
          _buildDeployButton(ref, exportState),
          const SizedBox(width: 8),
          const PresetsMenuButton(),
          const SizedBox(width: 4),
          _buildLogButton(context),
          const SizedBox(width: 4),
          _buildAboutButton(context),
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => showDialog(
        context: context,
        builder: (_) => const AboutGramercyDialog(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.radio,
                color: AppTheme.primaryAmber,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GRAMERCY',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'WT LOCALIZATION',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAmber,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoExportSwitch(WidgetRef ref, bool autoExport) {
    return Tooltip(
      message: 'Automatically compile and export patched CSV on each edit',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Auto-Deploy',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: autoExport,
              activeTrackColor: AppTheme.primaryAmber,
              onChanged: (val) =>
                  ref.read(autoExportProvider.notifier).setVal(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployButton(WidgetRef ref, ExportState exportState) {
    final inProgress = exportState.status == ExportStatus.inProgress;
    return ElevatedButton.icon(
      onPressed: inProgress
          ? null
          : () => ref.read(exportNotifierProvider.notifier).exportCurrentFile(),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(0, 34),
      ),
      icon: inProgress
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : const Icon(Icons.rocket_launch, size: 14, color: Colors.black),
      label: Text(
        inProgress ? 'Deploying...' : 'Deploy to Game',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildLogButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.terminal, size: 18, color: AppTheme.textSecondary),
      tooltip: 'View System Logs',
      onPressed: () =>
          showDialog(context: context, builder: (_) => const LogViewerDialog()),
    );
  }

  Widget _buildAboutButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.info_outline,
        size: 18,
        color: AppTheme.textSecondary,
      ),
      tooltip: 'About & BattlEye Safety',
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const AboutGramercyDialog(),
      ),
    );
  }
}

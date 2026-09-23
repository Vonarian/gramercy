import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/ui/widgets/rebuild_dialog.dart';

class RebuildButton extends StatelessWidget {
  const RebuildButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.sync, color: AppTheme.primaryAmber, size: 20),
      tooltip: 'Rebuild Game Strings (Game Update)',
      onPressed: () =>
          showDialog(context: context, builder: (_) => const RebuildDialog()),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class LocalizationLoadingView extends StatelessWidget {
  const LocalizationLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryAmber),
          SizedBox(height: 16),
          Text(
            'Parsing localization CSV with worker isolate...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class LocalizationErrorView extends StatelessWidget {
  final Object error;

  const LocalizationErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.alertRed),
            const SizedBox(height: 16),
            const Text(
              'Failed to parse localization file.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class RebuildDialogHeader extends StatelessWidget {
  const RebuildDialogHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sync, color: AppTheme.primaryAmber, size: 24),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rebuild Game Strings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Safely refresh base files after a major War Thunder patch.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RebuildStepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget action;
  final String? statusText;
  final bool isSuccess;

  const RebuildStepCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    this.statusText,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              action,
            ],
          ),
          if (statusText != null) ...[
            const SizedBox(height: 6),
            Text(
              statusText!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSuccess
                    ? AppTheme.emeraldGreen
                    : AppTheme.primaryAmber,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

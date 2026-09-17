import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class ReadOnlyBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;

  const ReadOnlyBlock({
    super.key,
    required this.label,
    required this.value,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: SelectableText(
            value,
            style: TextStyle(
              fontFamily: isMonospace ? 'Consolas' : null,
              fontSize: 13,
              color: isMonospace ? AppTheme.tacticalCyan : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gramercy/core/theme/app_theme.dart';

class TableHeader extends StatelessWidget {
  const TableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 0.5),
          bottom: BorderSide(color: AppTheme.border, width: 1.0),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 240,
            child: Text(
              'KEY / ID',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'ORIGINAL BASE TEXT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'CUSTOM OVERRIDE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 190,
            child: Text(
              'ACTIONS',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

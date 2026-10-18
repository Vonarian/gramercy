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
          SizedBox(width: 240, child: _HeaderLabel('KEY / ID')),
          SizedBox(width: 16),
          Expanded(child: _HeaderLabel('ORIGINAL BASE TEXT')),
          SizedBox(width: 16),
          Expanded(child: _HeaderLabel('CUSTOM OVERRIDE')),
          SizedBox(width: 12),
          SizedBox(
            width: 190,
            child: _HeaderLabel('ACTIONS', textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const _HeaderLabel(this.text, {this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppTheme.textMuted,
      ),
    );
  }
}

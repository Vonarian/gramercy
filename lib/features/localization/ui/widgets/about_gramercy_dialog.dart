import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AboutGramercyDialog extends StatelessWidget {
  const AboutGramercyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildLoreCard(),
            const SizedBox(height: 12),
            _buildBattlEyeSafetyCard(),
            const SizedBox(height: 12),
            _buildSmartScreenNote(),
            const SizedBox(height: 20),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.radio, color: AppTheme.primaryAmber, size: 36),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gramercy Cockpit',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'v1.3.1 • War Thunder Custom Localization Engine',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoreCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.record_voice_over, color: AppTheme.primaryAmber, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Why "Gramercy"? In War Thunder, radio command [T-4-6] broadcasts "Gramercy!" ("Thank you!"). A tribute to the pilots and tankers.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattlEyeSafetyCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2316),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF225E35)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF4ADE80), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '100% BattlEye Anti-Cheat (BEAC) Safe',
                  style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Gramercy utilizes Gaijin\'s official "testLocalization:b=yes" hook. It modifies only plain CSV files in the game\'s lang folder without injecting code or modifying game memory.',
            style: TextStyle(
              color: Color(0xFFDCFCE7),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartScreenNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.textSecondary, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Open-source and unbloated. If Windows SmartScreen prompts on first launch, click "More info" → "Run anyway".',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: AppTheme.primaryAmber),
          ),
        ),
      ],
    );
  }
}

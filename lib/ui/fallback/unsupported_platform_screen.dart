import 'package:flutter/material.dart';

/// Graceful landing for a handset (mobile review, option A): the app is a
/// desktop tool — game files live on the PC, and phone OSes sandbox access
/// to them. Point users at the preset-pack hand-off instead of breaking.
class UnsupportedPlatformScreen extends StatelessWidget {
  const UnsupportedPlatformScreen({super.key, required this.platform});

  final String platform;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.computer, size: 48, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                'Gramercy is a desktop application',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Mobile builds are intentionally not shipped: War Thunder's "
                'lang folder lives on your PC, and $platform sandboxes '
                'access to it. Export a preset pack to any cloud-synced '
                'folder and re-import it on the desktop app.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

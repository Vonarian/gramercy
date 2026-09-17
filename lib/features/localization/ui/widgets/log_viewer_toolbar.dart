import 'package:flutter/material.dart';

class LogViewerToolbar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCopy;
  final VoidCallback onClear;

  const LogViewerToolbar({
    super.key,
    required this.onSearchChanged,
    required this.onCopy,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Filter log messages or tags...',
              prefixIcon: const Icon(Icons.search, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 14),
          label: const Text('Copy'),
          onPressed: onCopy,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_sweep, size: 14),
          label: const Text('Clear'),
          onPressed: onClear,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/edit_dialog_actions.dart';
import 'package:gramercy/features/localization/ui/widgets/edit_dialog_header.dart';
import 'package:gramercy/features/localization/ui/widgets/read_only_block.dart';

class EditLocalizationDialog extends ConsumerStatefulWidget {
  final String fileName;
  final LocalizationEntry entry;

  const EditLocalizationDialog({
    super.key,
    required this.fileName,
    required this.entry,
  });

  static Future<void> show(
    BuildContext context, {
    required String fileName,
    required LocalizationEntry entry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          EditLocalizationDialog(fileName: fileName, entry: entry),
    );
  }

  @override
  ConsumerState<EditLocalizationDialog> createState() =>
      _EditLocalizationDialogState();
}

class _EditLocalizationDialogState
    extends ConsumerState<EditLocalizationDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newValue = _controller.text;
    setState(() => _isSaving = true);

    try {
      if (newValue == widget.entry.baseValue && widget.entry.isOverridden) {
        await revertLocalizationOverride(
          ref: ref,
          fileName: widget.fileName,
          key: widget.entry.key,
        );
      } else {
        await saveLocalizationOverride(
          ref: ref,
          fileName: widget.fileName,
          key: widget.entry.key,
          customValue: newValue,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleRevert() async {
    setState(() => _isSaving = true);
    try {
      await revertLocalizationOverride(
        ref: ref,
        fileName: widget.fileName,
        key: widget.entry.key,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditDialogHeader(
                fileName: widget.fileName,
                isOverridden: widget.entry.isOverridden,
              ),
              const SizedBox(height: 20),
              ReadOnlyBlock(
                label: 'STRING KEY',
                value: widget.entry.key,
                isMonospace: true,
              ),
              const SizedBox(height: 16),
              ReadOnlyBlock(
                label: 'BASE GAME VALUE (ORIGINAL)',
                value: widget.entry.baseValue.isEmpty
                    ? '(No base string in original game CSV)'
                    : widget.entry.baseValue,
              ),
              const SizedBox(height: 16),
              _buildEditorInput(),
              const SizedBox(height: 24),
              EditDialogActions(
                isOverridden: widget.entry.isOverridden,
                isSaving: _isSaving,
                onCancel: () => Navigator.of(context).pop(),
                onSave: _handleSave,
                onRevert: _handleRevert,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CUSTOM OVERRIDE VALUE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter replacement name or text...',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

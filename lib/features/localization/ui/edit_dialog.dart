import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
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
      builder: (context) => EditLocalizationDialog(
        fileName: fileName,
        entry: entry,
      ),
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
              _buildDialogHeader(),
              const SizedBox(height: 20),
              ReadOnlyBlock(label: 'STRING KEY', value: widget.entry.key, isMonospace: true),
              const SizedBox(height: 16),
              ReadOnlyBlock(
                label: 'BASE GAME VALUE (ORIGINAL)',
                value: widget.entry.baseValue.isEmpty ? '(No base string in original game CSV)' : widget.entry.baseValue,
              ),
              const SizedBox(height: 16),
              _buildEditorInput(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.edit_note, color: AppTheme.primaryAmber, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Localization String', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(widget.fileName, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
        if (widget.entry.isOverridden)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
            ),
            child: const Text('MODIFIED', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildEditorInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CUSTOM OVERRIDE VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Enter replacement name or text...'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.entry.isOverridden)
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _handleRevert,
            icon: const Icon(Icons.undo, size: 16, color: AppTheme.alertRed),
            label: const Text('Revert to Base', style: TextStyle(color: AppTheme.alertRed)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.alertRed.withValues(alpha: 0.5))),
          ),
        const Spacer(),
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Save Override'),
        ),
      ],
    );
  }
}

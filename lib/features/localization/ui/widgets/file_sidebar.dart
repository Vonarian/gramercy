import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

class FileSidebar extends ConsumerStatefulWidget {
  const FileSidebar({super.key});

  @override
  ConsumerState<FileSidebar> createState() => _FileSidebarState();
}

class _FileSidebarState extends ConsumerState<FileSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final selectedFile = ref.watch(selectedFileProvider);
    final availableFilesAsync = ref.watch(availableFilesProvider);
    final width = _isCollapsed ? 56.0 : 220.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border, width: 1.0)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(),
          Expanded(
            child: availableFilesAsync.when(
              data: (files) => _buildFileList(files, selectedFile),
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAmber)),
              error: (_, _) => _buildFileList(const ['units.csv', 'menu.csv', 'ui.csv'], selectedFile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (_isCollapsed) {
      return SizedBox(
        height: 42,
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
            tooltip: 'Expand Sidebar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _isCollapsed = false),
          ),
        ),
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.folder_copy_outlined, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'CSV FILES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18, color: AppTheme.textMuted),
            tooltip: 'Collapse Sidebar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => setState(() => _isCollapsed = true),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(List<String> files, String selectedFile) {
    final effectiveFiles = files.contains(selectedFile) ? files : [selectedFile, ...files];
    return ListView.builder(
      itemCount: effectiveFiles.length,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemBuilder: (context, index) {
        final file = effectiveFiles[index];
        final isSelected = file == selectedFile;
        return _FileItem(
          file: file,
          isSelected: isSelected,
          isCollapsed: _isCollapsed,
          onTap: () => ref.read(selectedFileProvider.notifier).selectFile(file),
        );
      },
    );
  }
}

class _FileItem extends ConsumerWidget {
  final String file;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _FileItem({
    required this.file,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overridesAsync = ref.watch(overridesProvider(file));
    final overrideCount = overridesAsync.value?.length ?? 0;

    return Tooltip(
      message: isCollapsed ? '$file ($overrideCount modified)' : '',
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)) : null,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                Icons.description_outlined,
                size: 16,
                color: isSelected ? AppTheme.primaryAmber : AppTheme.textMuted,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppTheme.monospace.fontFamily,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (overrideCount > 0) _buildCountBadge(overrideCount),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.emeraldGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.emeraldGreen,
        ),
      ),
    );
  }
}

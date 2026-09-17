import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

class FileSidebarItem extends ConsumerWidget {
  final String file;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const FileSidebarItem({
    super.key,
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
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
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

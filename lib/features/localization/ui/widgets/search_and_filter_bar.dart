import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';

class SearchAndFilterBar extends ConsumerStatefulWidget {
  const SearchAndFilterBar({super.key});

  @override
  ConsumerState<SearchAndFilterBar> createState() => _SearchAndFilterBarState();
}

class _SearchAndFilterBarState extends ConsumerState<SearchAndFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = ref.watch(selectedFileProvider);
    final allEntries = ref.watch(synthesizedStringsProvider(fileName));
    final filteredEntries = ref.watch(filteredStringsProvider(fileName));
    final filterMode = ref.watch(filterModeProvider);
    final overriddenCount = allEntries.where((e) => e.isOverridden).length;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.surface,
      child: Row(
        children: [
          _buildFilePill(fileName),
          const SizedBox(width: 16),
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 16),
          _buildSegmentedFilter(filterMode, allEntries.length, overriddenCount),
          const SizedBox(width: 12),
          _buildCountBadge(filteredEntries.length, allEntries.length),
        ],
      ),
    );
  }

  Widget _buildFilePill(String fileName) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.table_chart_outlined, size: 16, color: AppTheme.primaryAmber),
        const SizedBox(width: 6),
        Text(
          fileName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.monospace.fontFamily,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final shortcutHint = Platform.isMacOS ? 'Cmd+F' : 'Ctrl+F';
    return SizedBox(
      height: 32,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search keys or text... ($shortcutHint)',
          hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.textMuted),
          prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 14, color: AppTheme.textMuted),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    ref.read(searchQueryProvider.notifier).clear();
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        onChanged: (val) {
          setState(() {});
          ref.read(searchQueryProvider.notifier).setQuery(val);
        },
      ),
    );
  }

  Widget _buildSegmentedFilter(FilterMode filterMode, int total, int modified) {
    return SegmentedButton<FilterMode>(
      segments: [
        ButtonSegment<FilterMode>(
          value: FilterMode.all,
          label: Text('All ($total)'),
        ),
        ButtonSegment<FilterMode>(
          value: FilterMode.overriddenOnly,
          label: Text('Modified ($modified)'),
        ),
        ButtonSegment<FilterMode>(
          value: FilterMode.unmodifiedOnly,
          label: const Text('Original'),
        ),
      ],
      selected: {filterMode},
      onSelectionChanged: (newSelection) {
        ref.read(filterModeProvider.notifier).setMode(newSelection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildCountBadge(int filtered, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$filtered / $total',
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }
}

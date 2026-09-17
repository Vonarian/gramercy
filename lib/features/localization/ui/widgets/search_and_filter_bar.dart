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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceElevated,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSearchField(),
            const SizedBox(width: 16),
            _buildSegmentedFilter(filterMode, allEntries.length, overriddenCount),
            const SizedBox(width: 16),
            Text(
              '${filteredEntries.length} results',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 380,
      height: 38,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by ID/key (e.g. us_m4a3) or localized text...',
          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).setQuery('');
                  },
                )
              : null,
        ),
        onChanged: (val) => ref.read(searchQueryProvider.notifier).setQuery(val),
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
        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
      ),
    );
  }
}

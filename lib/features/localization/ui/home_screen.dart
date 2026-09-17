import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/theme/app_theme.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/command_header.dart';
import 'package:gramercy/features/localization/ui/widgets/empty_state_view.dart';
import 'package:gramercy/features/localization/ui/widgets/localization_row_item.dart';
import 'package:gramercy/features/localization/ui/widgets/search_and_filter_bar.dart';
import 'package:gramercy/features/localization/ui/widgets/status_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<ExportState>(exportNotifierProvider, (prev, next) {
      if (next.status == ExportStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.emeraldGreen,
            content: Text(
              next.message ?? 'Export successful!',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (next.status == ExportStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.alertRed,
            content: Text(
              next.message ?? 'Export failed.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CommandHeader(),
            Divider(),
            SearchAndFilterBar(),
            Divider(),
            Expanded(child: _VirtualizedLocalizationList()),
            EditorStatusBar(),
          ],
        ),
      ),
    );
  }
}

class _VirtualizedLocalizationList extends ConsumerStatefulWidget {
  const _VirtualizedLocalizationList();

  @override
  ConsumerState<_VirtualizedLocalizationList> createState() => _VirtualizedLocalizationListState();
}

class _VirtualizedLocalizationListState extends ConsumerState<_VirtualizedLocalizationList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = ref.watch(selectedFileProvider);
    final baseStringsAsync = ref.watch(baseStringsProvider(fileName));
    final filteredEntries = ref.watch(filteredStringsProvider(fileName));

    return baseStringsAsync.when(
      data: (_) {
        if (filteredEntries.isEmpty) {
          return const EmptyStateView();
        }

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _scrollController,
            itemExtent: 56.0,
            addRepaintBoundaries: true,
            itemCount: filteredEntries.length,
            itemBuilder: (context, index) {
              final item = filteredEntries[index];
              return LocalizationRowItem(
                key: ValueKey(item.key),
                fileName: fileName,
                entry: item,
                index: index,
                onRevert: () => revertLocalizationOverride(
                  ref: ref,
                  fileName: fileName,
                  key: item.key,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryAmber),
            SizedBox(height: 16),
            Text('Parsing localization CSV with worker isolate...', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.alertRed),
              const SizedBox(height: 16),
              Text('Error loading $fileName: $err', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Make sure War Thunder path is set and lang/ contains CSV files.', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

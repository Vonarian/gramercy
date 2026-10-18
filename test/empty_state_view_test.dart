import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramercy/core/isolates/localization_worker.dart';
import 'package:gramercy/core/services/preferences_service.dart';
import 'package:gramercy/features/localization/providers/localization_providers.dart';
import 'package:gramercy/features/localization/ui/widgets/empty_state_view.dart';
import 'package:gramercy/features/localization/ui/widgets/onboarding_setup_view.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockWorker extends Mock implements LocalizationWorkerService {}

class _Bootstrapper extends ConsumerStatefulWidget {
  const _Bootstrapper({required this.child, required this.setup});
  final Widget child;
  final void Function(WidgetRef ref) setup;

  @override
  ConsumerState<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends ConsumerState<_Bootstrapper> {
  bool _setupDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_setupDone) {
      _setupDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.setup(ref);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> _pumpEmpty(
  WidgetTester tester, {
  Map<String, Object> prefValues = const {},
  ConfigBlkStatus? status,
  Future<void> Function(WidgetRef ref)? setup,
}) async {
  SharedPreferences.setMockInitialValues(prefValues);
  final prefs = PreferencesService(await SharedPreferences.getInstance());
  final worker = _MockWorker();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        workerServiceProvider.overrideWithValue(worker),
        if (status != null)
          configBlkStatusProvider.overrideWithValue(AsyncValue.data(status)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: _Bootstrapper(
            child: const EmptyStateView(),
            setup: (ref) => setup?.call(ref),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue('/tmp/config.blk');
  });

  testWidgets('without a wt path it renders the onboarding flow', (
    tester,
  ) async {
    await _pumpEmpty(tester);

    expect(find.byType(OnboardingSetupView), findsOneWidget);
  });

  testWidgets('with a wt path it renders the empty-file guidance', (
    tester,
  ) async {
    await _pumpEmpty(
      tester,
      prefValues: {PreferencesService.keyWtInstallPath: '/wt'},
      status: const ConfigBlkStatus(
        exists: true,
        isLocalizationEnabled: false,
        filePath: '/wt/config.blk',
      ),
    );

    expect(find.textContaining('No entries in units.csv'), findsOneWidget);
    expect(find.text('Enable in config.blk'), findsOneWidget);
  });

  testWidgets('search query renders the no-match hint and clears back', (
    tester,
  ) async {
    await _pumpEmpty(
      tester,
      prefValues: {PreferencesService.keyWtInstallPath: '/wt'},
      setup: (ref) async => ref
          .read(searchQueryProvider.notifier)
          .setQuery('sherman', immediate: true),
    );

    expect(
      find.textContaining('No strings matching "sherman"'),
      findsOneWidget,
    );

    await tester.tap(find.text('Clear Search Filter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No strings matching'), findsNothing);
    expect(find.textContaining('No entries in units.csv'), findsOneWidget);
  });
}

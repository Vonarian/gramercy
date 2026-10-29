import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'export_providers.dart';

Future<void> saveLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
  required String customValue,
}) => ref
    .read(exportNotifierProvider.notifier)
    .saveOverride(fileName: fileName, key: key, customValue: customValue);

Future<void> revertLocalizationOverride({
  required WidgetRef ref,
  required String fileName,
  required String key,
}) => ref
    .read(exportNotifierProvider.notifier)
    .revertOverride(fileName: fileName, key: key);

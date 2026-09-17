import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramercy/core/services/preferences_service.dart';

final prefsProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('prefsProvider must be overridden in ProviderScope');
});

class WtPathNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.watch(prefsProvider).wtInstallPath;
  }

  Future<void> setPath(String path) async {
    state = path;
    await ref.read(prefsProvider).setWtInstallPath(path);
  }

  bool autoDetect() {
    final home = Platform.environment['HOME'] ?? '';
    final candidatePaths = <String>[
      if (Platform.isWindows) ...[
        r'C:\Program Files (x86)\Steam\steamapps\common\War Thunder',
        r'D:\SteamLibrary\steamapps\common\War Thunder',
        r'E:\SteamLibrary\steamapps\common\War Thunder',
        r'C:\Games\WarThunder',
        r'C:\WarThunder',
      ],
      if (Platform.isLinux && home.isNotEmpty) ...[
        '$home/.local/share/Steam/steamapps/common/War Thunder',
        '$home/.steam/steam/steamapps/common/War Thunder',
        '$home/.steam/root/steamapps/common/War Thunder',
      ],
      if (Platform.isMacOS && home.isNotEmpty) ...[
        '$home/Library/Application Support/Steam/steamapps/common/War Thunder',
      ],
    ];

    for (final path in candidatePaths) {
      if (Directory(path).existsSync()) {
        setPath(path);
        return true;
      }
    }
    return false;
  }
}

final wtPathProvider = NotifierProvider<WtPathNotifier, String?>(
  WtPathNotifier.new,
);

class AutoExportNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(prefsProvider).autoExportOnSave;
  }

  Future<void> toggle() async {
    final newVal = !state;
    state = newVal;
    await ref.read(prefsProvider).setAutoExportOnSave(newVal);
  }

  Future<void> setVal(bool val) async {
    state = val;
    await ref.read(prefsProvider).setAutoExportOnSave(val);
  }
}

final autoExportProvider = NotifierProvider<AutoExportNotifier, bool>(
  AutoExportNotifier.new,
);

class SelectedFileNotifier extends Notifier<String> {
  @override
  String build() {
    return ref.watch(prefsProvider).lastOpenedCsv;
  }

  Future<void> selectFile(String fileName) async {
    state = fileName;
    await ref.read(prefsProvider).setLastOpenedCsv(fileName);
  }
}

final selectedFileProvider = NotifierProvider<SelectedFileNotifier, String>(
  SelectedFileNotifier.new,
);

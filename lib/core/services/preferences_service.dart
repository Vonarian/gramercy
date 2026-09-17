import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  static const String keyWtInstallPath = 'wt_install_path';
  static const String keyAutoExportOnSave = 'auto_export_on_save';
  static const String keyLastOpenedCsv = 'last_opened_csv';

  PreferencesService(this._prefs);

  String? get wtInstallPath => _prefs.getString(keyWtInstallPath);

  Future<bool> setWtInstallPath(String path) {
    return _prefs.setString(keyWtInstallPath, path);
  }

  bool get autoExportOnSave => _prefs.getBool(keyAutoExportOnSave) ?? false;

  Future<bool> setAutoExportOnSave(bool value) {
    return _prefs.setBool(keyAutoExportOnSave, value);
  }

  String get lastOpenedCsv => _prefs.getString(keyLastOpenedCsv) ?? 'units.csv';

  Future<bool> setLastOpenedCsv(String fileName) {
    return _prefs.setString(keyLastOpenedCsv, fileName);
  }
}

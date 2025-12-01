import 'package:flutter_app/features/settings/application/ports/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adapter implementing SettingsRepository using SharedPreferences
class PrefsSettingsRepository implements SettingsRepository {
  final SharedPreferences _prefs;

  PrefsSettingsRepository({required SharedPreferences prefs}) : _prefs = prefs;

  // Keys
  static const String _keyNetwork = 'bitcoin_network';
  static const String _keyHideBalance = 'hide_balance';

  @override
  Future<String?> getCurrentNetwork() async {
    return _prefs.getString(_keyNetwork);
  }

  @override
  Future<void> setCurrentNetwork(String network) async {
    await _prefs.setString(_keyNetwork, network);
  }

  @override
  Future<bool> getHideBalance() async {
    return _prefs.getBool(_keyHideBalance) ?? false;
  }

  @override
  Future<void> setHideBalance(bool hide) async {
    await _prefs.setBool(_keyHideBalance, hide);
  }

  // Clear all settings
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}

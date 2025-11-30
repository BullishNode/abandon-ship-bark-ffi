/// Port for settings repository
abstract class SettingsRepository {
  /// Get current Bitcoin network setting
  Future<String?> getCurrentNetwork();

  /// Set current Bitcoin network
  Future<void> setCurrentNetwork(String network);

  /// Get hide balance setting
  Future<bool> getHideBalance();

  /// Set hide balance setting
  Future<void> setHideBalance(bool hide);
}

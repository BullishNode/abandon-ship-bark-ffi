import 'package:equatable/equatable.dart';

/// Base class for settings events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

/// Event to load current settings
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Event to change the current network
class ChangeNetwork extends SettingsEvent {
  final String network;

  const ChangeNetwork(this.network);

  @override
  List<Object> get props => [network];
}

/// Event to toggle hide balance setting
class ToggleHideBalance extends SettingsEvent {
  const ToggleHideBalance();
}

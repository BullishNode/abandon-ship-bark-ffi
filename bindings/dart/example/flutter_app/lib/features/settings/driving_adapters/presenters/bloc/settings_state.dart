import 'package:equatable/equatable.dart';

/// Base class for settings states
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Loaded state with settings data
class SettingsLoaded extends SettingsState {
  final String currentNetwork;
  final List<String> availableNetworks;
  final bool hideBalance;
  final String? esploraEndpoint;

  const SettingsLoaded({
    required this.currentNetwork,
    required this.availableNetworks,
    required this.hideBalance,
    this.esploraEndpoint,
  });

  @override
  List<Object?> get props => [
    currentNetwork,
    availableNetworks,
    hideBalance,
    esploraEndpoint,
  ];

  SettingsLoaded copyWith({
    String? currentNetwork,
    List<String>? availableNetworks,
    bool? hideBalance,
    String? esploraEndpoint,
  }) {
    return SettingsLoaded(
      currentNetwork: currentNetwork ?? this.currentNetwork,
      availableNetworks: availableNetworks ?? this.availableNetworks,
      hideBalance: hideBalance ?? this.hideBalance,
      esploraEndpoint: esploraEndpoint ?? this.esploraEndpoint,
    );
  }
}

/// Error state
class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}

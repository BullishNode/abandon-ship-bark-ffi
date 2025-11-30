import 'package:flutter_app/core/application/usecases/usecase.dart';
import 'package:flutter_app/features/settings/application/usecases/get_all_networks.dart';
import 'package:flutter_app/features/settings/application/usecases/get_current_network.dart';
import 'package:flutter_app/features/settings/application/usecases/set_current_network.dart';
import 'package:flutter_app/features/settings/driving_adapters/presenters/bloc/settings_event.dart';
import 'package:flutter_app/features/settings/driving_adapters/presenters/bloc/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC for managing settings
/// Transforms data between use cases and UI
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetCurrentNetwork _getCurrentNetwork;
  final GetAllNetworks _getAllNetworks;
  final SetCurrentNetwork _setCurrentNetwork;

  SettingsBloc({
    required GetCurrentNetwork getCurrentNetwork,
    required GetAllNetworks getAllNetworks,
    required SetCurrentNetwork setCurrentNetwork,
  }) : _getCurrentNetwork = getCurrentNetwork,
       _getAllNetworks = getAllNetworks,
       _setCurrentNetwork = setCurrentNetwork,
       super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeNetwork>(_onChangeNetwork);
    on<ToggleHideBalance>(_onToggleHideBalance);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    // Get current network
    final currentNetworkResult = await _getCurrentNetwork(NoParams());

    // Get all available networks
    final allNetworksResult = await _getAllNetworks(NoParams());

    // Combine results
    currentNetworkResult.fold(
      (failure) => emit(SettingsError(failure.message)),
      (currentNetworkResponse) => allNetworksResult.fold(
        (failure) => emit(SettingsError(failure.message)),
        (allNetworksResponse) => emit(
          SettingsLoaded(
            currentNetwork: currentNetworkResponse.network,
            availableNetworks: allNetworksResponse.networks,
            hideBalance: false, // TODO: Get from use case when implemented
          ),
        ),
      ),
    );
  }

  Future<void> _onChangeNetwork(
    ChangeNetwork event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // Optimistically update UI
    emit(currentState.copyWith(currentNetwork: event.network));

    // Call use case to persist
    final result = await _setCurrentNetwork(
      SetCurrentNetworkCommand(network: event.network),
    );

    // Handle errors by reverting or showing error
    result.fold(
      (failure) {
        // Revert to previous state and show error
        emit(SettingsError(failure.message));
        // Reload settings to get back to consistent state
        add(const LoadSettings());
      },
      (_) {
        // Success - UI already updated optimistically
      },
    );
  }

  Future<void> _onToggleHideBalance(
    ToggleHideBalance event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // Toggle the value
    emit(currentState.copyWith(hideBalance: !currentState.hideBalance));

    // TODO: Call use case to persist when implemented
  }
}

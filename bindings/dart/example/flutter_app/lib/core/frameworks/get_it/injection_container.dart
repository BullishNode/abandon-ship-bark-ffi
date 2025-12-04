import 'package:flutter_app/core/frameworks/drift/app_database.dart'
    hide BarkWallet;
import 'package:flutter_app/features/esplora_settings/application/ports/bitcoin_network_port.dart'
    as esplora_network;
import 'package:flutter_app/features/esplora_settings/application/ports/esplora_settings_repository.dart';
import 'package:flutter_app/features/esplora_settings/application/usecases/get_esplora_endpoint_for_network.dart';
import 'package:flutter_app/features/esplora_settings/driven_adapters/drift_esplora_settings_repository.dart';
import 'package:flutter_app/features/esplora_settings/driven_adapters/facade_bitcoin_network_port.dart'
    as esplora_facade;
import 'package:flutter_app/features/esplora_settings/driving_adapters/facades/esplora_endpoint_facade.dart';
import 'package:flutter_app/features/settings/application/ports/settings_repository.dart';
import 'package:flutter_app/features/settings/application/usecases/get_all_networks.dart';
import 'package:flutter_app/features/settings/application/usecases/get_current_network.dart';
import 'package:flutter_app/features/settings/application/usecases/set_current_network.dart';
import 'package:flutter_app/features/settings/application/usecases/validate_network.dart';
import 'package:flutter_app/features/settings/driven_adapters/prefs_settings_repository.dart';
import 'package:flutter_app/features/settings/driving_adapters/facades/bitcoin_network_facade.dart';
import 'package:flutter_app/features/settings/driving_adapters/presenters/bloc/settings_bloc.dart';
import 'package:flutter_app/features/wallet/application/ports/bitcoin_network_port.dart'
    as wallet_network;
import 'package:flutter_app/features/wallet/application/ports/esplora_endpoint_port.dart';
import 'package:flutter_app/features/wallet/application/ports/wallets_repository_port.dart';
import 'package:flutter_app/features/wallet/application/services/wallet_service.dart';
import 'package:flutter_app/features/wallet/application/usecases/create_bark_wallet.dart';
import 'package:flutter_app/features/wallet/application/usecases/generate_payment_request.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_all_wallets.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_wallet_backup.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_wallet_balance.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_wallet_transactions.dart';
import 'package:flutter_app/features/wallet/application/usecases/get_wallet_vtxos.dart';
import 'package:flutter_app/features/wallet/application/usecases/sync_wallet.dart';
import 'package:flutter_app/features/wallet/application/ports/mnemonic_repository_port.dart';
import 'package:flutter_app/features/wallet/driven_adapters/wallets/bark_wallet.dart';
import 'package:flutter_app/features/wallet/driven_adapters/wallets/drift_wallets_repository.dart';
import 'package:flutter_app/features/wallet/driven_adapters/wallets/wallet_port_registry.dart';
import 'package:flutter_app/features/wallet/driven_adapters/facade_bitcoin_network_port.dart'
    as wallet_facade;
import 'package:flutter_app/features/wallet/driven_adapters/facade_esplora_endpoint_port.dart';
import 'package:flutter_app/features/wallet/driven_adapters/fss_mnemonic_repository.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Register dependencies following Clean Architecture layers:
  // 1. External dependencies (database, SharedPreferences, etc.)
  // 2. Repositories (adapters implementing ports)
  // 3. Use cases (application layer business logic)
  // 4. Facades (driving adapters exposing use cases to other features)
  // 5. BLoCs/Cubits (presentation layer state management)

  await _initFrameworks();
  await _initDrivenAdapters();
  await _initUseCases();
  await _initDrivingAdapters();
}

// External dependencies (Database, SharedPreferences, etc.)
Future<void> _initFrameworks() async {
  // Register Drift database
  final database = AppDatabase();
  sl.registerLazySingleton<AppDatabase>(() => database);

  // Register SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Register FlutterSecureStorage
  const flutterSecureStorage = FlutterSecureStorage();
  sl.registerLazySingleton<FlutterSecureStorage>(() => flutterSecureStorage);
}

// Repositories (Adapters implementing port interfaces)
Future<void> _initDrivenAdapters() async {
  // Settings repository
  sl.registerLazySingleton<SettingsRepository>(
    () => PrefsSettingsRepository(prefs: sl()),
  );

  // Esplora settings repository
  sl.registerLazySingleton<EsploraSettingsRepository>(
    () => DriftEsploraSettingsRepository(sl()),
  );

  // Facade adapter as BitcoinNetworkPort for esplora feature
  sl.registerLazySingleton<esplora_network.BitcoinNetworkPort>(
    () => esplora_facade.FacadeBitcoinNetworkPort(sl()),
  );

  // Facade adapter as BitcoinNetworkPort for wallet feature
  sl.registerLazySingleton<wallet_network.BitcoinNetworkPort>(
    () => wallet_facade.FacadeBitcoinNetworkPort(sl()),
  );

  // Facade adapter as EsploraEndpointPort for wallet feature
  sl.registerLazySingleton<EsploraEndpointPort>(
    () => FacadeEsploraEndpointPort(sl()),
  );

  // Wallet adapters
  sl.registerLazySingleton<MnemonicRepositoryPort>(
    () => FssMnemonicRepository(sl()),
  );

  sl.registerLazySingleton<BarkWallet>(
    () => BarkWallet(database: sl(), secureStorage: sl()),
  );

  sl.registerLazySingleton<WalletPortRegistry>(
    () => WalletPortRegistry(barkwallet: sl()),
  );

  sl.registerLazySingleton<WalletsRepositoryPort>(
    () => DriftWalletsRepository(sl()),
  );
}

// Use cases (Application layer business logic)
Future<void> _initUseCases() async {
  // Services
  sl.registerLazySingleton(
    () => WalletService(
      walletPortRegistry: sl(),
      walletsRepository: sl(),
      mnemonicRepository: sl(),
      esploraEndpointPort: sl(),
    ),
  );

  // Settings use cases
  sl.registerLazySingleton(() => GetAllNetworks());
  sl.registerLazySingleton(() => ValidateNetwork());
  sl.registerLazySingleton(() => GetCurrentNetwork(sl()));
  sl.registerLazySingleton(() => SetCurrentNetwork(sl()));

  // Esplora settings use cases
  sl.registerLazySingleton(() => GetEsploraEndpointForNetwork(sl(), sl()));

  // Wallet use cases
  sl.registerLazySingleton(() => GetAllWallets(sl()));
  sl.registerLazySingleton(() => GetWalletBalance(sl()));
  sl.registerLazySingleton(
    () => CreateBarkWallet(walletService: sl(), bitcoinNetworkPort: sl()),
  );
  sl.registerLazySingleton(() => GeneratePaymentRequest(walletService: sl()));
  sl.registerLazySingleton(() => SyncWallet(sl()));
  sl.registerLazySingleton(() => GetWalletVtxos(sl()));
  sl.registerLazySingleton(() => GetWalletTransactions(sl()));
  sl.registerLazySingleton(() => GetWalletBackup(sl()));
}

// Facades (Driving adapters exposing use cases)
Future<void> _initDrivingAdapters() async {
  // Bitcoin network facade - exposes network operations to other features
  sl.registerLazySingleton<BitcoinNetworkFacade>(
    () => BitcoinNetworkFacade(
      getAllNetworks: sl(),
      validateNetwork: sl(),
      getCurrentNetwork: sl(),
      setCurrentNetwork: sl(),
    ),
  );

  // Esplora endpoint facade - exposes esplora endpoint operations to other features
  sl.registerLazySingleton<EsploraEndpointFacade>(
    () => EsploraEndpointFacade(sl()),
  );

  // Register BLoCs as factories so each screen gets a fresh instance
  sl.registerFactory(
    () => SettingsBloc(
      getCurrentNetwork: sl(),
      getAllNetworks: sl(),
      setCurrentNetwork: sl(),
    ),
  );

  sl.registerFactory(
    () => WalletBloc(
      getAllWallets: sl(),
      createBarkWallet: sl(),
      getWalletBalance: sl(),
      generatePaymentRequest: sl(),
      syncWallet: sl(),
      getWalletVtxos: sl(),
      getWalletTransactions: sl(),
      getWalletBackup: sl(),
    ),
  );
}

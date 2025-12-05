import 'package:equatable/equatable.dart';

/// View model for wallet backup
sealed class WalletBackupVM extends Equatable {
  const WalletBackupVM();
}

/// Bark wallet backup view model
class BarkWalletBackupVM extends WalletBackupVM {
  final String mnemonic;
  final String fingerprint;

  const BarkWalletBackupVM({
    required this.mnemonic,
    required this.fingerprint,
  });

  @override
  List<Object> get props => [mnemonic, fingerprint];
}

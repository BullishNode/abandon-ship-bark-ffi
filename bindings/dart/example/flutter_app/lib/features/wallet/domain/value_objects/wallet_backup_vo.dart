/// Base class for wallet backup data
sealed class WalletBackupVO {
  const WalletBackupVO();
}

/// Bark wallet backup containing mnemonic phrase
class BarkWalletBackupVO extends WalletBackupVO {
  final String mnemonic;
  final String fingerprint;

  const BarkWalletBackupVO({
    required this.mnemonic,
    required this.fingerprint,
  });
}

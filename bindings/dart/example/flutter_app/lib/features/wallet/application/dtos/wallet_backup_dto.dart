/// DTO for wallet backup data
sealed class WalletBackupDto {
  const WalletBackupDto();
}

/// Bark wallet backup DTO containing mnemonic
class BarkWalletBackupDto extends WalletBackupDto {
  final String mnemonic;
  final String fingerprint;

  const BarkWalletBackupDto({
    required this.mnemonic,
    required this.fingerprint,
  });
}

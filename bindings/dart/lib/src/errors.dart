import 'package:bark/src/generated/bark.dart';

/// Extension on BarkException to provide a common message getter
extension BarkExceptionMessage on BarkException {
  /// Get the error message from any BarkException variant
  String get message {
    return switch (this) {
      NetworkBarkException(:final errorMessage) => errorMessage,
      DatabaseBarkException(:final errorMessage) => errorMessage,
      InvalidMnemonicBarkException(:final errorMessage) => errorMessage,
      InvalidAddressBarkException(:final errorMessage) => errorMessage,
      InvalidInvoiceBarkException(:final errorMessage) => errorMessage,
      InvalidPsbtBarkException(:final errorMessage) => errorMessage,
      InvalidTransactionBarkException(:final errorMessage) => errorMessage,
      InsufficientFundsBarkException(:final errorMessage) => errorMessage,
      NotFoundBarkException(:final errorMessage) => errorMessage,
      ServerConnectionBarkException(:final errorMessage) => errorMessage,
      InternalBarkException(:final errorMessage) => errorMessage,
      OnchainWalletRequiredBarkException(:final errorMessage) => errorMessage,
      _ => 'An unknown Bark error occurred.',
    };
  }
}

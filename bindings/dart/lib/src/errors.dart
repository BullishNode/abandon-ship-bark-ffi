import 'package:bark/src/generated/bark.dart';

/// Extension on BarkException to provide a common message getter
extension BarkExceptionMessage on BarkException {
  /// Get the error message from any BarkException variant
  String get message {
    return switch (this) {
      NetworkBarkException(:final message) => message,
      DatabaseBarkException(:final message) => message,
      InvalidMnemonicBarkException(:final message) => message,
      InvalidAddressBarkException(:final message) => message,
      InvalidInvoiceBarkException(:final message) => message,
      InsufficientFundsBarkException(:final message) => message,
      NotFoundBarkException(:final message) => message,
      ServerConnectionBarkException(:final message) => message,
      InternalBarkException(:final message) => message,
      _ => 'An unknown Bark error occurred.',
    };
  }
}

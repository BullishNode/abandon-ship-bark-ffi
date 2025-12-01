library bark;

import "dart:async";
import "dart:convert";
import "dart:ffi";
import "dart:io" show Platform, File, Directory;
import "dart:isolate";
import "dart:typed_data";
import "package:ffi/ffi.dart";

class Balance {
  final int spendableSats;
  final int pendingInRoundSats;
  final int pendingExitSats;
  final int pendingLightningSendSats;
  final int pendingLightningReceiveTotalSats;
  final int pendingLightningReceiveClaimableSats;
  final int pendingBoardSats;
  Balance(
    this.spendableSats,
    this.pendingInRoundSats,
    this.pendingExitSats,
    this.pendingLightningSendSats,
    this.pendingLightningReceiveTotalSats,
    this.pendingLightningReceiveClaimableSats,
    this.pendingBoardSats,
  );
}

class FfiConverterBalance {
  static Balance lift(RustBuffer buf) {
    return FfiConverterBalance.read(buf.asUint8List()).value;
  }

  static LiftRetVal<Balance> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final spendableSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final spendableSats = spendableSats_lifted.value;
    new_offset += spendableSats_lifted.bytesRead;
    final pendingInRoundSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final pendingInRoundSats = pendingInRoundSats_lifted.value;
    new_offset += pendingInRoundSats_lifted.bytesRead;
    final pendingExitSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final pendingExitSats = pendingExitSats_lifted.value;
    new_offset += pendingExitSats_lifted.bytesRead;
    final pendingLightningSendSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final pendingLightningSendSats = pendingLightningSendSats_lifted.value;
    new_offset += pendingLightningSendSats_lifted.bytesRead;
    final pendingLightningReceiveTotalSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final pendingLightningReceiveTotalSats =
        pendingLightningReceiveTotalSats_lifted.value;
    new_offset += pendingLightningReceiveTotalSats_lifted.bytesRead;
    final pendingLightningReceiveClaimableSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final pendingLightningReceiveClaimableSats =
        pendingLightningReceiveClaimableSats_lifted.value;
    new_offset += pendingLightningReceiveClaimableSats_lifted.bytesRead;
    final pendingBoardSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final pendingBoardSats = pendingBoardSats_lifted.value;
    new_offset += pendingBoardSats_lifted.bytesRead;
    return LiftRetVal(
      Balance(
        spendableSats,
        pendingInRoundSats,
        pendingExitSats,
        pendingLightningSendSats,
        pendingLightningReceiveTotalSats,
        pendingLightningReceiveClaimableSats,
        pendingBoardSats,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(Balance value) {
    final total_length =
        FfiConverterUInt64.allocationSize(value.spendableSats) +
        FfiConverterUInt64.allocationSize(value.pendingInRoundSats) +
        FfiConverterUInt64.allocationSize(value.pendingExitSats) +
        FfiConverterUInt64.allocationSize(value.pendingLightningSendSats) +
        FfiConverterUInt64.allocationSize(
          value.pendingLightningReceiveTotalSats,
        ) +
        FfiConverterUInt64.allocationSize(
          value.pendingLightningReceiveClaimableSats,
        ) +
        FfiConverterUInt64.allocationSize(value.pendingBoardSats) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(Balance value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterUInt64.write(
      value.spendableSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.pendingInRoundSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.pendingExitSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.pendingLightningSendSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.pendingLightningReceiveTotalSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.pendingLightningReceiveClaimableSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.pendingBoardSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(Balance value) {
    return FfiConverterUInt64.allocationSize(value.spendableSats) +
        FfiConverterUInt64.allocationSize(value.pendingInRoundSats) +
        FfiConverterUInt64.allocationSize(value.pendingExitSats) +
        FfiConverterUInt64.allocationSize(value.pendingLightningSendSats) +
        FfiConverterUInt64.allocationSize(
          value.pendingLightningReceiveTotalSats,
        ) +
        FfiConverterUInt64.allocationSize(
          value.pendingLightningReceiveClaimableSats,
        ) +
        FfiConverterUInt64.allocationSize(value.pendingBoardSats) +
        0;
  }
}

class Config {
  final String serverAddress;
  final String? esploraAddress;
  final Network network;
  final int? vtxoRefreshExpiryThreshold;
  final int? vtxoExitMargin;
  final int? htlcRecvClaimDelta;
  Config(
    this.serverAddress,
    this.esploraAddress,
    this.network,
    this.vtxoRefreshExpiryThreshold,
    this.vtxoExitMargin,
    this.htlcRecvClaimDelta,
  );
}

class FfiConverterConfig {
  static Config lift(RustBuffer buf) {
    return FfiConverterConfig.read(buf.asUint8List()).value;
  }

  static LiftRetVal<Config> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final serverAddress_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final serverAddress = serverAddress_lifted.value;
    new_offset += serverAddress_lifted.bytesRead;
    final esploraAddress_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final esploraAddress = esploraAddress_lifted.value;
    new_offset += esploraAddress_lifted.bytesRead;
    final network_lifted = FfiConverterNetwork.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final network = network_lifted.value;
    new_offset += network_lifted.bytesRead;
    final vtxoRefreshExpiryThreshold_lifted = FfiConverterOptionalUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoRefreshExpiryThreshold = vtxoRefreshExpiryThreshold_lifted.value;
    new_offset += vtxoRefreshExpiryThreshold_lifted.bytesRead;
    final vtxoExitMargin_lifted = FfiConverterOptionalUInt16.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoExitMargin = vtxoExitMargin_lifted.value;
    new_offset += vtxoExitMargin_lifted.bytesRead;
    final htlcRecvClaimDelta_lifted = FfiConverterOptionalUInt16.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final htlcRecvClaimDelta = htlcRecvClaimDelta_lifted.value;
    new_offset += htlcRecvClaimDelta_lifted.bytesRead;
    return LiftRetVal(
      Config(
        serverAddress,
        esploraAddress,
        network,
        vtxoRefreshExpiryThreshold,
        vtxoExitMargin,
        htlcRecvClaimDelta,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(Config value) {
    final total_length =
        FfiConverterString.allocationSize(value.serverAddress) +
        FfiConverterOptionalString.allocationSize(value.esploraAddress) +
        FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterOptionalUInt32.allocationSize(
          value.vtxoRefreshExpiryThreshold,
        ) +
        FfiConverterOptionalUInt16.allocationSize(value.vtxoExitMargin) +
        FfiConverterOptionalUInt16.allocationSize(value.htlcRecvClaimDelta) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(Config value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.serverAddress,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalString.write(
      value.esploraAddress,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterNetwork.write(
      value.network,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalUInt32.write(
      value.vtxoRefreshExpiryThreshold,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalUInt16.write(
      value.vtxoExitMargin,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalUInt16.write(
      value.htlcRecvClaimDelta,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(Config value) {
    return FfiConverterString.allocationSize(value.serverAddress) +
        FfiConverterOptionalString.allocationSize(value.esploraAddress) +
        FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterOptionalUInt32.allocationSize(
          value.vtxoRefreshExpiryThreshold,
        ) +
        FfiConverterOptionalUInt16.allocationSize(value.vtxoExitMargin) +
        FfiConverterOptionalUInt16.allocationSize(value.htlcRecvClaimDelta) +
        0;
  }
}

class LightningInvoice {
  final String invoice;
  final int amountSats;
  LightningInvoice(this.invoice, this.amountSats);
}

class FfiConverterLightningInvoice {
  static LightningInvoice lift(RustBuffer buf) {
    return FfiConverterLightningInvoice.read(buf.asUint8List()).value;
  }

  static LiftRetVal<LightningInvoice> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final invoice_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final invoice = invoice_lifted.value;
    new_offset += invoice_lifted.bytesRead;
    final amountSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final amountSats = amountSats_lifted.value;
    new_offset += amountSats_lifted.bytesRead;
    return LiftRetVal(
      LightningInvoice(invoice, amountSats),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(LightningInvoice value) {
    final total_length =
        FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(LightningInvoice value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.invoice,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.amountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(LightningInvoice value) {
    return FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        0;
  }
}

class LightningPaymentResult {
  final String invoice;
  final String preimage;
  LightningPaymentResult(this.invoice, this.preimage);
}

class FfiConverterLightningPaymentResult {
  static LightningPaymentResult lift(RustBuffer buf) {
    return FfiConverterLightningPaymentResult.read(buf.asUint8List()).value;
  }

  static LiftRetVal<LightningPaymentResult> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final invoice_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final invoice = invoice_lifted.value;
    new_offset += invoice_lifted.bytesRead;
    final preimage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final preimage = preimage_lifted.value;
    new_offset += preimage_lifted.bytesRead;
    return LiftRetVal(
      LightningPaymentResult(invoice, preimage),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(LightningPaymentResult value) {
    final total_length =
        FfiConverterString.allocationSize(value.invoice) +
        FfiConverterString.allocationSize(value.preimage) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(LightningPaymentResult value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.invoice,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.preimage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(LightningPaymentResult value) {
    return FfiConverterString.allocationSize(value.invoice) +
        FfiConverterString.allocationSize(value.preimage) +
        0;
  }
}

class OffboardResult {
  final String roundId;
  OffboardResult(this.roundId);
}

class FfiConverterOffboardResult {
  static OffboardResult lift(RustBuffer buf) {
    return FfiConverterOffboardResult.read(buf.asUint8List()).value;
  }

  static LiftRetVal<OffboardResult> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final roundId_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final roundId = roundId_lifted.value;
    new_offset += roundId_lifted.bytesRead;
    return LiftRetVal(OffboardResult(roundId), new_offset - buf.offsetInBytes);
  }

  static RustBuffer lower(OffboardResult value) {
    final total_length = FfiConverterString.allocationSize(value.roundId) + 0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(OffboardResult value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.roundId,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(OffboardResult value) {
    return FfiConverterString.allocationSize(value.roundId) + 0;
  }
}

class Vtxo {
  final String id;
  final int amountSats;
  final int expiryHeight;
  final String kind;
  final String state;
  Vtxo(this.id, this.amountSats, this.expiryHeight, this.kind, this.state);
}

class FfiConverterVtxo {
  static Vtxo lift(RustBuffer buf) {
    return FfiConverterVtxo.read(buf.asUint8List()).value;
  }

  static LiftRetVal<Vtxo> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final id_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final id = id_lifted.value;
    new_offset += id_lifted.bytesRead;
    final amountSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final amountSats = amountSats_lifted.value;
    new_offset += amountSats_lifted.bytesRead;
    final expiryHeight_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final expiryHeight = expiryHeight_lifted.value;
    new_offset += expiryHeight_lifted.bytesRead;
    final kind_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final kind = kind_lifted.value;
    new_offset += kind_lifted.bytesRead;
    final state_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final state = state_lifted.value;
    new_offset += state_lifted.bytesRead;
    return LiftRetVal(
      Vtxo(id, amountSats, expiryHeight, kind, state),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(Vtxo value) {
    final total_length =
        FfiConverterString.allocationSize(value.id) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterUInt32.allocationSize(value.expiryHeight) +
        FfiConverterString.allocationSize(value.kind) +
        FfiConverterString.allocationSize(value.state) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(Vtxo value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.id,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.amountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.expiryHeight,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.kind,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.state,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(Vtxo value) {
    return FfiConverterString.allocationSize(value.id) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterUInt32.allocationSize(value.expiryHeight) +
        FfiConverterString.allocationSize(value.kind) +
        FfiConverterString.allocationSize(value.state) +
        0;
  }
}

class WalletProperties {
  final Network network;
  final String fingerprint;
  WalletProperties(this.network, this.fingerprint);
}

class FfiConverterWalletProperties {
  static WalletProperties lift(RustBuffer buf) {
    return FfiConverterWalletProperties.read(buf.asUint8List()).value;
  }

  static LiftRetVal<WalletProperties> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final network_lifted = FfiConverterNetwork.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final network = network_lifted.value;
    new_offset += network_lifted.bytesRead;
    final fingerprint_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final fingerprint = fingerprint_lifted.value;
    new_offset += fingerprint_lifted.bytesRead;
    return LiftRetVal(
      WalletProperties(network, fingerprint),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(WalletProperties value) {
    final total_length =
        FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterString.allocationSize(value.fingerprint) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(WalletProperties value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterNetwork.write(
      value.network,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.fingerprint,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(WalletProperties value) {
    return FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterString.allocationSize(value.fingerprint) +
        0;
  }
}

abstract class BarkException implements Exception {
  RustBuffer lower();
  int allocationSize();
  int write(Uint8List buf);
}

class FfiConverterBarkException {
  static BarkException lift(RustBuffer buffer) {
    return FfiConverterBarkException.read(buffer.asUint8List()).value;
  }

  static LiftRetVal<BarkException> read(Uint8List buf) {
    final index = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    final subview = Uint8List.view(buf.buffer, buf.offsetInBytes + 4);
    switch (index) {
      case 1:
        return NetworkBarkException.read(subview);
      case 2:
        return DatabaseBarkException.read(subview);
      case 3:
        return InvalidMnemonicBarkException.read(subview);
      case 4:
        return InvalidAddressBarkException.read(subview);
      case 5:
        return InvalidInvoiceBarkException.read(subview);
      case 6:
        return InsufficientFundsBarkException.read(subview);
      case 7:
        return NotFoundBarkException.read(subview);
      case 8:
        return ServerConnectionBarkException.read(subview);
      case 9:
        return InternalBarkException.read(subview);
      default:
        throw UniffiInternalError(
          UniffiInternalError.unexpectedEnumCase,
          "Unable to determine enum variant",
        );
    }
  }

  static RustBuffer lower(BarkException value) {
    return value.lower();
  }

  static int allocationSize(BarkException value) {
    return value.allocationSize();
  }

  static int write(BarkException value, Uint8List buf) {
    return value.write(buf);
  }
}

class NetworkBarkException extends BarkException {
  final String message;
  NetworkBarkException(String this.message);
  NetworkBarkException._(String this.message);
  static LiftRetVal<NetworkBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(NetworkBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 1);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "NetworkBarkException($message)";
  }
}

class DatabaseBarkException extends BarkException {
  final String message;
  DatabaseBarkException(String this.message);
  DatabaseBarkException._(String this.message);
  static LiftRetVal<DatabaseBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(DatabaseBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 2);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "DatabaseBarkException($message)";
  }
}

class InvalidMnemonicBarkException extends BarkException {
  final String message;
  InvalidMnemonicBarkException(String this.message);
  InvalidMnemonicBarkException._(String this.message);
  static LiftRetVal<InvalidMnemonicBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(InvalidMnemonicBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 3);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InvalidMnemonicBarkException($message)";
  }
}

class InvalidAddressBarkException extends BarkException {
  final String message;
  InvalidAddressBarkException(String this.message);
  InvalidAddressBarkException._(String this.message);
  static LiftRetVal<InvalidAddressBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(InvalidAddressBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 4);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InvalidAddressBarkException($message)";
  }
}

class InvalidInvoiceBarkException extends BarkException {
  final String message;
  InvalidInvoiceBarkException(String this.message);
  InvalidInvoiceBarkException._(String this.message);
  static LiftRetVal<InvalidInvoiceBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(InvalidInvoiceBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 5);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InvalidInvoiceBarkException($message)";
  }
}

class InsufficientFundsBarkException extends BarkException {
  final String message;
  InsufficientFundsBarkException(String this.message);
  InsufficientFundsBarkException._(String this.message);
  static LiftRetVal<InsufficientFundsBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(InsufficientFundsBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 6);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InsufficientFundsBarkException($message)";
  }
}

class NotFoundBarkException extends BarkException {
  final String message;
  NotFoundBarkException(String this.message);
  NotFoundBarkException._(String this.message);
  static LiftRetVal<NotFoundBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(NotFoundBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 7);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "NotFoundBarkException($message)";
  }
}

class ServerConnectionBarkException extends BarkException {
  final String message;
  ServerConnectionBarkException(String this.message);
  ServerConnectionBarkException._(String this.message);
  static LiftRetVal<ServerConnectionBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(ServerConnectionBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 8);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "ServerConnectionBarkException($message)";
  }
}

class InternalBarkException extends BarkException {
  final String message;
  InternalBarkException(String this.message);
  InternalBarkException._(String this.message);
  static LiftRetVal<InternalBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final message_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final message = message_lifted.value;
    new_offset += message_lifted.bytesRead;
    return LiftRetVal(InternalBarkException._(message), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(message) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 9);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      message,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InternalBarkException($message)";
  }
}

class BarkExceptionErrorHandler extends UniffiRustCallStatusErrorHandler {
  @override
  Exception lift(RustBuffer errorBuf) {
    return FfiConverterBarkException.lift(errorBuf);
  }
}

final BarkExceptionErrorHandler barkExceptionErrorHandler =
    BarkExceptionErrorHandler();

enum Network { bitcoin, testnet, signet, regtest }

class FfiConverterNetwork {
  static LiftRetVal<Network> read(Uint8List buf) {
    final index = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    switch (index) {
      case 1:
        return LiftRetVal(Network.bitcoin, 4);
      case 2:
        return LiftRetVal(Network.testnet, 4);
      case 3:
        return LiftRetVal(Network.signet, 4);
      case 4:
        return LiftRetVal(Network.regtest, 4);
      default:
        throw UniffiInternalError(
          UniffiInternalError.unexpectedEnumCase,
          "Unable to determine enum variant",
        );
    }
  }

  static Network lift(RustBuffer buffer) {
    return FfiConverterNetwork.read(buffer.asUint8List()).value;
  }

  static RustBuffer lower(Network input) {
    return toRustBuffer(createUint8ListFromInt(input.index + 1));
  }

  static int allocationSize(Network _value) {
    return 4;
  }

  static int write(Network value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.index + 1);
    return 4;
  }
}

abstract class WalletInterface {
  Balance balance();
  LightningInvoice bolt11Invoice(int amountSats);
  void maintenance();
  String newAddress();
  OffboardResult offboardAll(String bitcoinAddress);
  LightningPaymentResult payLightningAddress(
    String lightningAddress,
    int amountSats,
    String? comment,
  );
  LightningPaymentResult payLightningInvoice(String invoice, int? amountSats);
  WalletProperties properties();
  void sendArkoorPayment(String arkAddress, int amountSats);
  void sync_();
  void tryClaimAllLightningReceives(bool wait);
  List<Vtxo> vtxos();
}

final _WalletFinalizer = Finalizer<Pointer<Void>>((ptr) {
  rustCall((status) => uniffi_bark_ffi_fn_free_wallet(ptr, status));
});

class Wallet implements WalletInterface {
  late final Pointer<Void> _ptr;
  Wallet._(this._ptr) {
    _WalletFinalizer.attach(this, _ptr, detach: this);
  }
  Wallet.create(
    String mnemonic,
    Config config,
    String datadir,
    bool forceRescan,
  ) : _ptr = rustCall(
        (status) => uniffi_bark_ffi_fn_constructor_wallet_create(
          FfiConverterString.lower(mnemonic),
          FfiConverterConfig.lower(config),
          FfiConverterString.lower(datadir),
          FfiConverterBool.lower(forceRescan),
          status,
        ),
        barkExceptionErrorHandler,
      ) {
    _WalletFinalizer.attach(this, _ptr, detach: this);
  }
  Wallet.open(String mnemonic, Config config, String datadir)
    : _ptr = rustCall(
        (status) => uniffi_bark_ffi_fn_constructor_wallet_open(
          FfiConverterString.lower(mnemonic),
          FfiConverterConfig.lower(config),
          FfiConverterString.lower(datadir),
          status,
        ),
        barkExceptionErrorHandler,
      ) {
    _WalletFinalizer.attach(this, _ptr, detach: this);
  }
  factory Wallet.lift(Pointer<Void> ptr) {
    return Wallet._(ptr);
  }
  static Pointer<Void> lower(Wallet value) {
    return value.uniffiClonePointer();
  }

  Pointer<Void> uniffiClonePointer() {
    return rustCall((status) => uniffi_bark_ffi_fn_clone_wallet(_ptr, status));
  }

  static int allocationSize(Wallet value) {
    return 8;
  }

  static LiftRetVal<Wallet> read(Uint8List buf) {
    final handle = buf.buffer.asByteData(buf.offsetInBytes).getInt64(0);
    final pointer = Pointer<Void>.fromAddress(handle);
    return LiftRetVal(Wallet.lift(pointer), 8);
  }

  static int write(Wallet value, Uint8List buf) {
    final handle = lower(value);
    buf.buffer.asByteData(buf.offsetInBytes).setInt64(0, handle.address);
    return 8;
  }

  void dispose() {
    _WalletFinalizer.detach(this);
    rustCall((status) => uniffi_bark_ffi_fn_free_wallet(_ptr, status));
  }

  Balance balance() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_balance(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterBalance.lift,
      barkExceptionErrorHandler,
    );
  }

  LightningInvoice bolt11Invoice(int amountSats) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_bolt11_invoice(
        uniffiClonePointer(),
        FfiConverterUInt64.lower(amountSats),
        status,
      ),
      FfiConverterLightningInvoice.lift,
      barkExceptionErrorHandler,
    );
  }

  void maintenance() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_maintenance(
        uniffiClonePointer(),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  String newAddress() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_new_address(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterString.lift,
      barkExceptionErrorHandler,
    );
  }

  OffboardResult offboardAll(String bitcoinAddress) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_offboard_all(
        uniffiClonePointer(),
        FfiConverterString.lower(bitcoinAddress),
        status,
      ),
      FfiConverterOffboardResult.lift,
      barkExceptionErrorHandler,
    );
  }

  LightningPaymentResult payLightningAddress(
    String lightningAddress,
    int amountSats,
    String? comment,
  ) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pay_lightning_address(
        uniffiClonePointer(),
        FfiConverterString.lower(lightningAddress),
        FfiConverterUInt64.lower(amountSats),
        FfiConverterOptionalString.lower(comment),
        status,
      ),
      FfiConverterLightningPaymentResult.lift,
      barkExceptionErrorHandler,
    );
  }

  LightningPaymentResult payLightningInvoice(String invoice, int? amountSats) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pay_lightning_invoice(
        uniffiClonePointer(),
        FfiConverterString.lower(invoice),
        FfiConverterOptionalUInt64.lower(amountSats),
        status,
      ),
      FfiConverterLightningPaymentResult.lift,
      barkExceptionErrorHandler,
    );
  }

  WalletProperties properties() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_properties(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterWalletProperties.lift,
      barkExceptionErrorHandler,
    );
  }

  void sendArkoorPayment(String arkAddress, int amountSats) {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_send_arkoor_payment(
        uniffiClonePointer(),
        FfiConverterString.lower(arkAddress),
        FfiConverterUInt64.lower(amountSats),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  void sync_() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_sync(uniffiClonePointer(), status);
    }, barkExceptionErrorHandler);
  }

  void tryClaimAllLightningReceives(bool wait) {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_try_claim_all_lightning_receives(
        uniffiClonePointer(),
        FfiConverterBool.lower(wait),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  List<Vtxo> vtxos() {
    return rustCallWithLifter(
      (status) =>
          uniffi_bark_ffi_fn_method_wallet_vtxos(uniffiClonePointer(), status),
      FfiConverterSequenceVtxo.lift,
      barkExceptionErrorHandler,
    );
  }
}

class UniffiInternalError implements Exception {
  static const int bufferOverflow = 0;
  static const int incompleteData = 1;
  static const int unexpectedOptionalTag = 2;
  static const int unexpectedEnumCase = 3;
  static const int unexpectedNullPointer = 4;
  static const int unexpectedRustCallStatusCode = 5;
  static const int unexpectedRustCallError = 6;
  static const int unexpectedStaleHandle = 7;
  static const int rustPanic = 8;
  final int errorCode;
  final String? panicMessage;
  const UniffiInternalError(this.errorCode, this.panicMessage);
  static UniffiInternalError panicked(String message) {
    return UniffiInternalError(rustPanic, message);
  }

  @override
  String toString() {
    switch (errorCode) {
      case bufferOverflow:
        return "UniFfi::BufferOverflow";
      case incompleteData:
        return "UniFfi::IncompleteData";
      case unexpectedOptionalTag:
        return "UniFfi::UnexpectedOptionalTag";
      case unexpectedEnumCase:
        return "UniFfi::UnexpectedEnumCase";
      case unexpectedNullPointer:
        return "UniFfi::UnexpectedNullPointer";
      case unexpectedRustCallStatusCode:
        return "UniFfi::UnexpectedRustCallStatusCode";
      case unexpectedRustCallError:
        return "UniFfi::UnexpectedRustCallError";
      case unexpectedStaleHandle:
        return "UniFfi::UnexpectedStaleHandle";
      case rustPanic:
        return "UniFfi::rustPanic: $panicMessage";
      default:
        return "UniFfi::UnknownError: $errorCode";
    }
  }
}

const int CALL_SUCCESS = 0;
const int CALL_ERROR = 1;
const int CALL_UNEXPECTED_ERROR = 2;

final class RustCallStatus extends Struct {
  @Int8()
  external int code;
  external RustBuffer errorBuf;
}

void checkCallStatus(
  UniffiRustCallStatusErrorHandler errorHandler,
  Pointer<RustCallStatus> status,
) {
  if (status.ref.code == CALL_SUCCESS) {
    return;
  } else if (status.ref.code == CALL_ERROR) {
    throw errorHandler.lift(status.ref.errorBuf);
  } else if (status.ref.code == CALL_UNEXPECTED_ERROR) {
    if (status.ref.errorBuf.len > 0) {
      throw UniffiInternalError.panicked(
        FfiConverterString.lift(status.ref.errorBuf),
      );
    } else {
      throw UniffiInternalError.panicked("Rust panic");
    }
  } else {
    throw UniffiInternalError.panicked(
      "Unexpected RustCallStatus code: \${status.ref.code}",
    );
  }
}

T rustCall<T>(
  T Function(Pointer<RustCallStatus>) callback, [
  UniffiRustCallStatusErrorHandler? errorHandler,
]) {
  final status = calloc<RustCallStatus>();
  try {
    final result = callback(status);
    checkCallStatus(errorHandler ?? NullRustCallStatusErrorHandler(), status);
    return result;
  } finally {
    calloc.free(status);
  }
}

T rustCallWithLifter<T, F>(
  F Function(Pointer<RustCallStatus>) ffiCall,
  T Function(F) lifter, [
  UniffiRustCallStatusErrorHandler? errorHandler,
]) {
  final status = calloc<RustCallStatus>();
  try {
    final rawResult = ffiCall(status);
    checkCallStatus(errorHandler ?? NullRustCallStatusErrorHandler(), status);
    return lifter(rawResult);
  } finally {
    calloc.free(status);
  }
}

class NullRustCallStatusErrorHandler extends UniffiRustCallStatusErrorHandler {
  @override
  Exception lift(RustBuffer errorBuf) {
    errorBuf.free();
    return UniffiInternalError.panicked("Unexpected CALL_ERROR");
  }
}

abstract class UniffiRustCallStatusErrorHandler {
  Exception lift(RustBuffer errorBuf);
}

final class RustBuffer extends Struct {
  @Uint64()
  external int capacity;
  @Uint64()
  external int len;
  external Pointer<Uint8> data;
  static RustBuffer alloc(int size) {
    return rustCall((status) => ffi_bark_ffi_rustbuffer_alloc(size, status));
  }

  static RustBuffer fromBytes(ForeignBytes bytes) {
    return rustCall(
      (status) => ffi_bark_ffi_rustbuffer_from_bytes(bytes, status),
    );
  }

  void free() {
    rustCall((status) => ffi_bark_ffi_rustbuffer_free(this, status));
  }

  RustBuffer reserve(int additionalCapacity) {
    return rustCall(
      (status) =>
          ffi_bark_ffi_rustbuffer_reserve(this, additionalCapacity, status),
    );
  }

  Uint8List asUint8List() {
    final dataList = data.asTypedList(len);
    final byteData = ByteData.sublistView(dataList);
    return Uint8List.view(byteData.buffer);
  }

  @override
  String toString() {
    return "RustBuffer{capacity: \$capacity, len: \$len, data: \$data}";
  }
}

RustBuffer toRustBuffer(Uint8List data) {
  final length = data.length;
  final Pointer<Uint8> frameData = calloc<Uint8>(length);
  final pointerList = frameData.asTypedList(length);
  pointerList.setAll(0, data);
  final bytes = calloc<ForeignBytes>();
  bytes.ref.len = length;
  bytes.ref.data = frameData;
  return RustBuffer.fromBytes(bytes.ref);
}

final class ForeignBytes extends Struct {
  @Int32()
  external int len;
  external Pointer<Uint8> data;
  void free() {
    calloc.free(data);
  }
}

class LiftRetVal<T> {
  final T value;
  final int bytesRead;
  const LiftRetVal(this.value, this.bytesRead);
  LiftRetVal<T> copyWithOffset(int offset) {
    return LiftRetVal(value, bytesRead + offset);
  }
}

abstract class FfiConverter<D, F> {
  const FfiConverter();
  D lift(F value);
  F lower(D value);
  D read(ByteData buffer, int offset);
  void write(D value, ByteData buffer, int offset);
  int size(D value);
}

mixin FfiConverterPrimitive<T> on FfiConverter<T, T> {
  @override
  T lift(T value) => value;
  @override
  T lower(T value) => value;
}
Uint8List createUint8ListFromInt(int value) {
  int length = value.bitLength ~/ 8 + 1;
  if (length != 4 && length != 8) {
    length = (value < 0x100000000) ? 4 : 8;
  }
  Uint8List uint8List = Uint8List(length);
  for (int i = length - 1; i >= 0; i--) {
    uint8List[i] = value & 0xFF;
    value >>= 8;
  }
  return uint8List;
}

class FfiConverterOptionalUInt32 {
  static int? lift(RustBuffer buf) {
    return FfiConverterOptionalUInt32.read(buf.asUint8List()).value;
  }

  static LiftRetVal<int?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<int?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([int? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterUInt32.allocationSize(value) + 1;
  }

  static RustBuffer lower(int? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalUInt32.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalUInt32.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(int? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterUInt32.write(
          value,
          Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
        ) +
        1;
  }
}

class FfiConverterOptionalUInt64 {
  static int? lift(RustBuffer buf) {
    return FfiConverterOptionalUInt64.read(buf.asUint8List()).value;
  }

  static LiftRetVal<int?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<int?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([int? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterUInt64.allocationSize(value) + 1;
  }

  static RustBuffer lower(int? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalUInt64.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalUInt64.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(int? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterUInt64.write(
          value,
          Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
        ) +
        1;
  }
}

class FfiConverterOptionalUInt16 {
  static int? lift(RustBuffer buf) {
    return FfiConverterOptionalUInt16.read(buf.asUint8List()).value;
  }

  static LiftRetVal<int?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterUInt16.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<int?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([int? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterUInt16.allocationSize(value) + 1;
  }

  static RustBuffer lower(int? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalUInt16.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalUInt16.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(int? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterUInt16.write(
          value,
          Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
        ) +
        1;
  }
}

class FfiConverterUInt16 {
  static int lift(int value) => value;
  static LiftRetVal<int> read(Uint8List buf) {
    return LiftRetVal(buf.buffer.asByteData(buf.offsetInBytes).getUint16(0), 2);
  }

  static int lower(int value) {
    if (value < 0 || value > 65535) {
      throw ArgumentError("Value out of range for u16: " + value.toString());
    }
    return value;
  }

  static int allocationSize([int value = 0]) {
    return 2;
  }

  static int write(int value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setUint16(0, lower(value));
    return 2;
  }
}

class FfiConverterUInt64 {
  static int lift(int value) => value;
  static LiftRetVal<int> read(Uint8List buf) {
    return LiftRetVal(buf.buffer.asByteData(buf.offsetInBytes).getUint64(0), 8);
  }

  static int lower(int value) {
    if (value < 0) {
      throw ArgumentError("Value out of range for u64: " + value.toString());
    }
    return value;
  }

  static int allocationSize([int value = 0]) {
    return 8;
  }

  static int write(int value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setUint64(0, lower(value));
    return 8;
  }
}

class FfiConverterBool {
  static bool lift(int value) {
    return value == 1;
  }

  static int lower(bool value) {
    return value ? 1 : 0;
  }

  static LiftRetVal<bool> read(Uint8List buf) {
    return LiftRetVal(FfiConverterBool.lift(buf.first), 1);
  }

  static RustBuffer lowerIntoRustBuffer(bool value) {
    return toRustBuffer(Uint8List.fromList([FfiConverterBool.lower(value)]));
  }

  static int allocationSize([bool value = false]) {
    return 1;
  }

  static int write(bool value, Uint8List buf) {
    buf.setAll(0, [value ? 1 : 0]);
    return allocationSize();
  }
}

class FfiConverterSequenceVtxo {
  static List<Vtxo> lift(RustBuffer buf) {
    return FfiConverterSequenceVtxo.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<Vtxo>> read(Uint8List buf) {
    List<Vtxo> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterVtxo.read(Uint8List.view(buf.buffer, offset));
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<Vtxo> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterVtxo.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<Vtxo> value) {
    return value
            .map((l) => FfiConverterVtxo.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<Vtxo> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
  }
}

class FfiConverterOptionalString {
  static String? lift(RustBuffer buf) {
    return FfiConverterOptionalString.read(buf.asUint8List()).value;
  }

  static LiftRetVal<String?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterString.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<String?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([String? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterString.allocationSize(value) + 1;
  }

  static RustBuffer lower(String? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalString.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalString.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(String? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterString.write(
          value,
          Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
        ) +
        1;
  }
}

class FfiConverterString {
  static String lift(RustBuffer buf) {
    return utf8.decoder.convert(buf.asUint8List());
  }

  static RustBuffer lower(String value) {
    return toRustBuffer(Utf8Encoder().convert(value));
  }

  static LiftRetVal<String> read(Uint8List buf) {
    final end = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0) + 4;
    return LiftRetVal(utf8.decoder.convert(buf, 4, end), end);
  }

  static int allocationSize([String value = ""]) {
    return utf8.encoder.convert(value).length + 4;
  }

  static int write(String value, Uint8List buf) {
    final list = utf8.encoder.convert(value);
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, list.length);
    buf.setAll(4, list);
    return list.length + 4;
  }
}

class FfiConverterUInt32 {
  static int lift(int value) => value;
  static LiftRetVal<int> read(Uint8List buf) {
    return LiftRetVal(buf.buffer.asByteData(buf.offsetInBytes).getUint32(0), 4);
  }

  static int lower(int value) {
    if (value < 0 || value > 4294967295) {
      throw ArgumentError("Value out of range for u32: " + value.toString());
    }
    return value;
  }

  static int allocationSize([int value = 0]) {
    return 4;
  }

  static int write(int value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setUint32(0, lower(value));
    return 4;
  }
}

const int UNIFFI_RUST_FUTURE_POLL_READY = 0;
const int UNIFFI_RUST_FUTURE_POLL_MAYBE_READY = 1;
typedef UniffiRustFutureContinuationCallback = Void Function(Uint64, Int8);
Future<T> uniffiRustCallAsync<T, F>(
  Pointer<Void> Function() rustFutureFunc,
  void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
  pollFunc,
  F Function(Pointer<Void>, Pointer<RustCallStatus>) completeFunc,
  void Function(Pointer<Void>) freeFunc,
  T Function(F) liftFunc, [
  UniffiRustCallStatusErrorHandler? errorHandler,
]) async {
  final rustFuture = rustFutureFunc();
  final completer = Completer<int>();
  late final NativeCallable<UniffiRustFutureContinuationCallback> callback;
  void poll() {
    pollFunc(rustFuture, callback.nativeFunction, Pointer<Void>.fromAddress(0));
  }

  void onResponse(int _idx, int pollResult) {
    if (pollResult == UNIFFI_RUST_FUTURE_POLL_READY) {
      completer.complete(pollResult);
    } else {
      poll();
    }
  }

  callback = NativeCallable<UniffiRustFutureContinuationCallback>.listener(
    onResponse,
  );
  try {
    poll();
    await completer.future;
    callback.close();
    final status = calloc<RustCallStatus>();
    try {
      final result = completeFunc(rustFuture, status);
      return liftFunc(result);
    } finally {
      calloc.free(status);
    }
  } finally {
    freeFunc(rustFuture);
  }
}

class UniffiHandleMap<T> {
  final Map<int, T> _map = {};
  int _counter = 1;
  int insert(T obj) {
    final handle = _counter;
    _counter += 2;
    _map[handle] = obj;
    return handle;
  }

  T get(int handle) {
    final obj = _map[handle];
    if (obj == null) {
      throw UniffiInternalError(
        UniffiInternalError.unexpectedStaleHandle,
        "Handle not found",
      );
    }
    return obj;
  }

  void remove(int handle) {
    if (_map.remove(handle) == null) {
      throw UniffiInternalError(
        UniffiInternalError.unexpectedStaleHandle,
        "Handle not found",
      );
    }
  }
}

const _uniffiAssetId = "package:bark/uniffi:bark_ffi";
@Native<Pointer<Void> Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external Pointer<Void> uniffi_bark_ffi_fn_clone_wallet(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_free_wallet(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Pointer<Void> Function(
    RustBuffer,
    RustBuffer,
    RustBuffer,
    Int8,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external Pointer<Void> uniffi_bark_ffi_fn_constructor_wallet_create(
  RustBuffer mnemonic,
  RustBuffer config,
  RustBuffer datadir,
  int force_rescan,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Pointer<Void> Function(
    RustBuffer,
    RustBuffer,
    RustBuffer,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external Pointer<Void> uniffi_bark_ffi_fn_constructor_wallet_open(
  RustBuffer mnemonic,
  RustBuffer config,
  RustBuffer datadir,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_balance(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Uint64, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_bolt11_invoice(
  Pointer<Void> ptr,
  int amount_sats,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_maintenance(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_new_address(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_offboard_all(
  Pointer<Void> ptr,
  RustBuffer bitcoin_address,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    Uint64,
    RustBuffer,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_pay_lightning_address(
  Pointer<Void> ptr,
  RustBuffer lightning_address,
  int amount_sats,
  RustBuffer comment,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    RustBuffer,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_pay_lightning_invoice(
  Pointer<Void> ptr,
  RustBuffer invoice,
  RustBuffer amount_sats,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_properties(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(Pointer<Void>, RustBuffer, Uint64, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external void uniffi_bark_ffi_fn_method_wallet_send_arkoor_payment(
  Pointer<Void> ptr,
  RustBuffer ark_address,
  int amount_sats,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_sync(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Int8, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_try_claim_all_lightning_receives(
  Pointer<Void> ptr,
  int wait,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_vtxos(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Uint64, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer ffi_bark_ffi_rustbuffer_alloc(
  int size,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(ForeignBytes, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer ffi_bark_ffi_rustbuffer_from_bytes(
  ForeignBytes bytes,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(RustBuffer, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void ffi_bark_ffi_rustbuffer_free(
  RustBuffer buf,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(RustBuffer, Uint64, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer ffi_bark_ffi_rustbuffer_reserve(
  RustBuffer buf,
  int additional,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_u8(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_u8(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_u8(Pointer<Void> handle);

@Native<Uint8 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_u8(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_i8(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_i8(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_i8(Pointer<Void> handle);

@Native<Int8 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_i8(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_u16(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_u16(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_u16(Pointer<Void> handle);

@Native<Uint16 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_u16(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_i16(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_i16(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_i16(Pointer<Void> handle);

@Native<Int16 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_i16(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_u32(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_u32(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_u32(Pointer<Void> handle);

@Native<Uint32 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_u32(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_i32(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_i32(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_i32(Pointer<Void> handle);

@Native<Int32 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_i32(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_u64(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_u64(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_u64(Pointer<Void> handle);

@Native<Uint64 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_u64(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_i64(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_i64(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_i64(Pointer<Void> handle);

@Native<Int64 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int ffi_bark_ffi_rust_future_complete_i64(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_f32(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_f32(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_f32(Pointer<Void> handle);

@Native<Float Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external double ffi_bark_ffi_rust_future_complete_f32(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_f64(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_f64(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_f64(Pointer<Void> handle);

@Native<Double Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external double ffi_bark_ffi_rust_future_complete_f64(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_rust_buffer(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_rust_buffer(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_rust_buffer(Pointer<Void> handle);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer ffi_bark_ffi_rust_future_complete_rust_buffer(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<Void>,
    Pointer<NativeFunction<UniffiRustFutureContinuationCallback>>,
    Pointer<Void>,
  )
>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_poll_void(
  Pointer<Void> handle,
  Pointer<NativeFunction<UniffiRustFutureContinuationCallback>> callback,
  Pointer<Void> callback_data,
);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_cancel_void(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>)>(assetId: _uniffiAssetId)
external void ffi_bark_ffi_rust_future_free_void(Pointer<Void> handle);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void ffi_bark_ffi_rust_future_complete_void(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_balance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_bolt11_invoice();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_maintenance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_new_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_offboard_all();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pay_lightning_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pay_lightning_invoice();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_properties();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_send_arkoor_payment();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_sync();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_try_claim_all_lightning_receives();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_wallet_create();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_wallet_open();

@Native<Uint32 Function()>(assetId: _uniffiAssetId)
external int ffi_bark_ffi_uniffi_contract_version();

void _checkApiVersion() {
  final bindingsVersion = 30;
  final scaffoldingVersion = ffi_bark_ffi_uniffi_contract_version();
  if (bindingsVersion != scaffoldingVersion) {
    throw UniffiInternalError.panicked(
      "UniFFI contract version mismatch: bindings version \$bindingsVersion, scaffolding version \$scaffoldingVersion",
    );
  }
}

void _checkApiChecksums() {
  if (uniffi_bark_ffi_checksum_method_wallet_balance() != 11221) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_bolt11_invoice() != 64551) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_maintenance() != 9626) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_new_address() != 25174) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_offboard_all() != 61123) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pay_lightning_address() != 8340) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pay_lightning_invoice() != 3587) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_properties() != 34715) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_send_arkoor_payment() != 24856) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_sync() != 3312) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_try_claim_all_lightning_receives() !=
      53132) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_vtxos() != 16778) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_wallet_create() != 28953) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_wallet_open() != 34910) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
}

void ensureInitialized() {
  _checkApiVersion();
  _checkApiChecksums();
}

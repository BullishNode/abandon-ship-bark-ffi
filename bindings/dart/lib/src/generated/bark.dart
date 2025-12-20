library bark;

import "dart:async";
import "dart:convert";
import "dart:ffi";
import "dart:io" show Platform, File, Directory;
import "dart:isolate";
import "dart:typed_data";
import "package:ffi/ffi.dart";

class AddressWithIndex {
  final String address;
  final int index;
  AddressWithIndex(this.address, this.index);
}

class FfiConverterAddressWithIndex {
  static AddressWithIndex lift(RustBuffer buf) {
    return FfiConverterAddressWithIndex.read(buf.asUint8List()).value;
  }

  static LiftRetVal<AddressWithIndex> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final address_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final address = address_lifted.value;
    new_offset += address_lifted.bytesRead;
    final index_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final index = index_lifted.value;
    new_offset += index_lifted.bytesRead;
    return LiftRetVal(
      AddressWithIndex(address, index),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(AddressWithIndex value) {
    final total_length =
        FfiConverterString.allocationSize(value.address) +
        FfiConverterUInt32.allocationSize(value.index) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(AddressWithIndex value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.address,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.index,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(AddressWithIndex value) {
    return FfiConverterString.allocationSize(value.address) +
        FfiConverterUInt32.allocationSize(value.index) +
        0;
  }
}

class ArkInfo {
  final Network network;
  final String serverPubkey;
  final int roundIntervalSecs;
  final int nbRoundNonces;
  final int vtxoExitDelta;
  final int vtxoExpiryDelta;
  final int htlcSendExpiryDelta;
  final int htlcExpiryDelta;
  final int? maxVtxoAmountSats;
  final int requiredBoardConfirmations;
  final int maxUserInvoiceCltvDelta;
  final int minBoardAmountSats;
  final int offboardFeerateSatPerVb;
  final bool lnReceiveAntiDosRequired;
  ArkInfo(
    this.network,
    this.serverPubkey,
    this.roundIntervalSecs,
    this.nbRoundNonces,
    this.vtxoExitDelta,
    this.vtxoExpiryDelta,
    this.htlcSendExpiryDelta,
    this.htlcExpiryDelta,
    this.maxVtxoAmountSats,
    this.requiredBoardConfirmations,
    this.maxUserInvoiceCltvDelta,
    this.minBoardAmountSats,
    this.offboardFeerateSatPerVb,
    this.lnReceiveAntiDosRequired,
  );
}

class FfiConverterArkInfo {
  static ArkInfo lift(RustBuffer buf) {
    return FfiConverterArkInfo.read(buf.asUint8List()).value;
  }

  static LiftRetVal<ArkInfo> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final network_lifted = FfiConverterNetwork.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final network = network_lifted.value;
    new_offset += network_lifted.bytesRead;
    final serverPubkey_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final serverPubkey = serverPubkey_lifted.value;
    new_offset += serverPubkey_lifted.bytesRead;
    final roundIntervalSecs_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final roundIntervalSecs = roundIntervalSecs_lifted.value;
    new_offset += roundIntervalSecs_lifted.bytesRead;
    final nbRoundNonces_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final nbRoundNonces = nbRoundNonces_lifted.value;
    new_offset += nbRoundNonces_lifted.bytesRead;
    final vtxoExitDelta_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoExitDelta = vtxoExitDelta_lifted.value;
    new_offset += vtxoExitDelta_lifted.bytesRead;
    final vtxoExpiryDelta_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoExpiryDelta = vtxoExpiryDelta_lifted.value;
    new_offset += vtxoExpiryDelta_lifted.bytesRead;
    final htlcSendExpiryDelta_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final htlcSendExpiryDelta = htlcSendExpiryDelta_lifted.value;
    new_offset += htlcSendExpiryDelta_lifted.bytesRead;
    final htlcExpiryDelta_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final htlcExpiryDelta = htlcExpiryDelta_lifted.value;
    new_offset += htlcExpiryDelta_lifted.bytesRead;
    final maxVtxoAmountSats_lifted = FfiConverterOptionalUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final maxVtxoAmountSats = maxVtxoAmountSats_lifted.value;
    new_offset += maxVtxoAmountSats_lifted.bytesRead;
    final requiredBoardConfirmations_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final requiredBoardConfirmations = requiredBoardConfirmations_lifted.value;
    new_offset += requiredBoardConfirmations_lifted.bytesRead;
    final maxUserInvoiceCltvDelta_lifted = FfiConverterUInt16.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final maxUserInvoiceCltvDelta = maxUserInvoiceCltvDelta_lifted.value;
    new_offset += maxUserInvoiceCltvDelta_lifted.bytesRead;
    final minBoardAmountSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final minBoardAmountSats = minBoardAmountSats_lifted.value;
    new_offset += minBoardAmountSats_lifted.bytesRead;
    final offboardFeerateSatPerVb_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final offboardFeerateSatPerVb = offboardFeerateSatPerVb_lifted.value;
    new_offset += offboardFeerateSatPerVb_lifted.bytesRead;
    final lnReceiveAntiDosRequired_lifted = FfiConverterBool.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final lnReceiveAntiDosRequired = lnReceiveAntiDosRequired_lifted.value;
    new_offset += lnReceiveAntiDosRequired_lifted.bytesRead;
    return LiftRetVal(
      ArkInfo(
        network,
        serverPubkey,
        roundIntervalSecs,
        nbRoundNonces,
        vtxoExitDelta,
        vtxoExpiryDelta,
        htlcSendExpiryDelta,
        htlcExpiryDelta,
        maxVtxoAmountSats,
        requiredBoardConfirmations,
        maxUserInvoiceCltvDelta,
        minBoardAmountSats,
        offboardFeerateSatPerVb,
        lnReceiveAntiDosRequired,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(ArkInfo value) {
    final total_length =
        FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterString.allocationSize(value.serverPubkey) +
        FfiConverterUInt64.allocationSize(value.roundIntervalSecs) +
        FfiConverterUInt32.allocationSize(value.nbRoundNonces) +
        FfiConverterUInt32.allocationSize(value.vtxoExitDelta) +
        FfiConverterUInt32.allocationSize(value.vtxoExpiryDelta) +
        FfiConverterUInt32.allocationSize(value.htlcSendExpiryDelta) +
        FfiConverterUInt32.allocationSize(value.htlcExpiryDelta) +
        FfiConverterOptionalUInt64.allocationSize(value.maxVtxoAmountSats) +
        FfiConverterUInt32.allocationSize(value.requiredBoardConfirmations) +
        FfiConverterUInt16.allocationSize(value.maxUserInvoiceCltvDelta) +
        FfiConverterUInt64.allocationSize(value.minBoardAmountSats) +
        FfiConverterUInt64.allocationSize(value.offboardFeerateSatPerVb) +
        FfiConverterBool.allocationSize(value.lnReceiveAntiDosRequired) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(ArkInfo value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterNetwork.write(
      value.network,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.serverPubkey,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.roundIntervalSecs,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.nbRoundNonces,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.vtxoExitDelta,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.vtxoExpiryDelta,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.htlcSendExpiryDelta,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.htlcExpiryDelta,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalUInt64.write(
      value.maxVtxoAmountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.requiredBoardConfirmations,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt16.write(
      value.maxUserInvoiceCltvDelta,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.minBoardAmountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.offboardFeerateSatPerVb,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterBool.write(
      value.lnReceiveAntiDosRequired,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(ArkInfo value) {
    return FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterString.allocationSize(value.serverPubkey) +
        FfiConverterUInt64.allocationSize(value.roundIntervalSecs) +
        FfiConverterUInt32.allocationSize(value.nbRoundNonces) +
        FfiConverterUInt32.allocationSize(value.vtxoExitDelta) +
        FfiConverterUInt32.allocationSize(value.vtxoExpiryDelta) +
        FfiConverterUInt32.allocationSize(value.htlcSendExpiryDelta) +
        FfiConverterUInt32.allocationSize(value.htlcExpiryDelta) +
        FfiConverterOptionalUInt64.allocationSize(value.maxVtxoAmountSats) +
        FfiConverterUInt32.allocationSize(value.requiredBoardConfirmations) +
        FfiConverterUInt16.allocationSize(value.maxUserInvoiceCltvDelta) +
        FfiConverterUInt64.allocationSize(value.minBoardAmountSats) +
        FfiConverterUInt64.allocationSize(value.offboardFeerateSatPerVb) +
        FfiConverterBool.allocationSize(value.lnReceiveAntiDosRequired) +
        0;
  }
}

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
  final String? bitcoindAddress;
  final String? bitcoindCookiefile;
  final String? bitcoindUser;
  final String? bitcoindPass;
  final Network network;
  final int? vtxoRefreshExpiryThreshold;
  final int? vtxoExitMargin;
  final int? htlcRecvClaimDelta;
  final int? fallbackFeeRate;
  final int? roundTxRequiredConfirmations;
  Config(
    this.serverAddress,
    this.esploraAddress,
    this.bitcoindAddress,
    this.bitcoindCookiefile,
    this.bitcoindUser,
    this.bitcoindPass,
    this.network,
    this.vtxoRefreshExpiryThreshold,
    this.vtxoExitMargin,
    this.htlcRecvClaimDelta,
    this.fallbackFeeRate,
    this.roundTxRequiredConfirmations,
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
    final bitcoindAddress_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final bitcoindAddress = bitcoindAddress_lifted.value;
    new_offset += bitcoindAddress_lifted.bytesRead;
    final bitcoindCookiefile_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final bitcoindCookiefile = bitcoindCookiefile_lifted.value;
    new_offset += bitcoindCookiefile_lifted.bytesRead;
    final bitcoindUser_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final bitcoindUser = bitcoindUser_lifted.value;
    new_offset += bitcoindUser_lifted.bytesRead;
    final bitcoindPass_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final bitcoindPass = bitcoindPass_lifted.value;
    new_offset += bitcoindPass_lifted.bytesRead;
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
    final fallbackFeeRate_lifted = FfiConverterOptionalUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final fallbackFeeRate = fallbackFeeRate_lifted.value;
    new_offset += fallbackFeeRate_lifted.bytesRead;
    final roundTxRequiredConfirmations_lifted = FfiConverterOptionalUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final roundTxRequiredConfirmations =
        roundTxRequiredConfirmations_lifted.value;
    new_offset += roundTxRequiredConfirmations_lifted.bytesRead;
    return LiftRetVal(
      Config(
        serverAddress,
        esploraAddress,
        bitcoindAddress,
        bitcoindCookiefile,
        bitcoindUser,
        bitcoindPass,
        network,
        vtxoRefreshExpiryThreshold,
        vtxoExitMargin,
        htlcRecvClaimDelta,
        fallbackFeeRate,
        roundTxRequiredConfirmations,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(Config value) {
    final total_length =
        FfiConverterString.allocationSize(value.serverAddress) +
        FfiConverterOptionalString.allocationSize(value.esploraAddress) +
        FfiConverterOptionalString.allocationSize(value.bitcoindAddress) +
        FfiConverterOptionalString.allocationSize(value.bitcoindCookiefile) +
        FfiConverterOptionalString.allocationSize(value.bitcoindUser) +
        FfiConverterOptionalString.allocationSize(value.bitcoindPass) +
        FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterOptionalUInt32.allocationSize(
          value.vtxoRefreshExpiryThreshold,
        ) +
        FfiConverterOptionalUInt16.allocationSize(value.vtxoExitMargin) +
        FfiConverterOptionalUInt16.allocationSize(value.htlcRecvClaimDelta) +
        FfiConverterOptionalUInt64.allocationSize(value.fallbackFeeRate) +
        FfiConverterOptionalUInt32.allocationSize(
          value.roundTxRequiredConfirmations,
        ) +
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
    new_offset += FfiConverterOptionalString.write(
      value.bitcoindAddress,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalString.write(
      value.bitcoindCookiefile,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalString.write(
      value.bitcoindUser,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalString.write(
      value.bitcoindPass,
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
    new_offset += FfiConverterOptionalUInt64.write(
      value.fallbackFeeRate,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalUInt32.write(
      value.roundTxRequiredConfirmations,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(Config value) {
    return FfiConverterString.allocationSize(value.serverAddress) +
        FfiConverterOptionalString.allocationSize(value.esploraAddress) +
        FfiConverterOptionalString.allocationSize(value.bitcoindAddress) +
        FfiConverterOptionalString.allocationSize(value.bitcoindCookiefile) +
        FfiConverterOptionalString.allocationSize(value.bitcoindUser) +
        FfiConverterOptionalString.allocationSize(value.bitcoindPass) +
        FfiConverterNetwork.allocationSize(value.network) +
        FfiConverterOptionalUInt32.allocationSize(
          value.vtxoRefreshExpiryThreshold,
        ) +
        FfiConverterOptionalUInt16.allocationSize(value.vtxoExitMargin) +
        FfiConverterOptionalUInt16.allocationSize(value.htlcRecvClaimDelta) +
        FfiConverterOptionalUInt64.allocationSize(value.fallbackFeeRate) +
        FfiConverterOptionalUInt32.allocationSize(
          value.roundTxRequiredConfirmations,
        ) +
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

class LightningReceiveStatus {
  final String paymentHash;
  final String invoice;
  final int amountSats;
  final bool hasHtlcVtxos;
  final bool preimageRevealed;
  LightningReceiveStatus(
    this.paymentHash,
    this.invoice,
    this.amountSats,
    this.hasHtlcVtxos,
    this.preimageRevealed,
  );
}

class FfiConverterLightningReceiveStatus {
  static LightningReceiveStatus lift(RustBuffer buf) {
    return FfiConverterLightningReceiveStatus.read(buf.asUint8List()).value;
  }

  static LiftRetVal<LightningReceiveStatus> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final paymentHash_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final paymentHash = paymentHash_lifted.value;
    new_offset += paymentHash_lifted.bytesRead;
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
    final hasHtlcVtxos_lifted = FfiConverterBool.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final hasHtlcVtxos = hasHtlcVtxos_lifted.value;
    new_offset += hasHtlcVtxos_lifted.bytesRead;
    final preimageRevealed_lifted = FfiConverterBool.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final preimageRevealed = preimageRevealed_lifted.value;
    new_offset += preimageRevealed_lifted.bytesRead;
    return LiftRetVal(
      LightningReceiveStatus(
        paymentHash,
        invoice,
        amountSats,
        hasHtlcVtxos,
        preimageRevealed,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(LightningReceiveStatus value) {
    final total_length =
        FfiConverterString.allocationSize(value.paymentHash) +
        FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterBool.allocationSize(value.hasHtlcVtxos) +
        FfiConverterBool.allocationSize(value.preimageRevealed) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(LightningReceiveStatus value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.paymentHash,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.invoice,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.amountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterBool.write(
      value.hasHtlcVtxos,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterBool.write(
      value.preimageRevealed,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(LightningReceiveStatus value) {
    return FfiConverterString.allocationSize(value.paymentHash) +
        FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterBool.allocationSize(value.hasHtlcVtxos) +
        FfiConverterBool.allocationSize(value.preimageRevealed) +
        0;
  }
}

class LightningSendStatus {
  final String invoice;
  final int amountSats;
  final int htlcVtxoCount;
  LightningSendStatus(this.invoice, this.amountSats, this.htlcVtxoCount);
}

class FfiConverterLightningSendStatus {
  static LightningSendStatus lift(RustBuffer buf) {
    return FfiConverterLightningSendStatus.read(buf.asUint8List()).value;
  }

  static LiftRetVal<LightningSendStatus> read(Uint8List buf) {
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
    final htlcVtxoCount_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final htlcVtxoCount = htlcVtxoCount_lifted.value;
    new_offset += htlcVtxoCount_lifted.bytesRead;
    return LiftRetVal(
      LightningSendStatus(invoice, amountSats, htlcVtxoCount),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(LightningSendStatus value) {
    final total_length =
        FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterUInt32.allocationSize(value.htlcVtxoCount) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(LightningSendStatus value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.invoice,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.amountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.htlcVtxoCount,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(LightningSendStatus value) {
    return FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterUInt32.allocationSize(value.htlcVtxoCount) +
        0;
  }
}

class Movement {
  final int id;
  final String status;
  final String subsystemName;
  final String subsystemKind;
  final String metadataJson;
  final int intendedBalanceSats;
  final int effectiveBalanceSats;
  final int offchainFeeSats;
  final List<String> sentToAddresses;
  final List<String> receivedOnAddresses;
  final List<String> inputVtxoIds;
  final List<String> outputVtxoIds;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  Movement(
    this.id,
    this.status,
    this.subsystemName,
    this.subsystemKind,
    this.metadataJson,
    this.intendedBalanceSats,
    this.effectiveBalanceSats,
    this.offchainFeeSats,
    this.sentToAddresses,
    this.receivedOnAddresses,
    this.inputVtxoIds,
    this.outputVtxoIds,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  );
}

class FfiConverterMovement {
  static Movement lift(RustBuffer buf) {
    return FfiConverterMovement.read(buf.asUint8List()).value;
  }

  static LiftRetVal<Movement> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final id_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final id = id_lifted.value;
    new_offset += id_lifted.bytesRead;
    final status_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final status = status_lifted.value;
    new_offset += status_lifted.bytesRead;
    final subsystemName_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final subsystemName = subsystemName_lifted.value;
    new_offset += subsystemName_lifted.bytesRead;
    final subsystemKind_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final subsystemKind = subsystemKind_lifted.value;
    new_offset += subsystemKind_lifted.bytesRead;
    final metadataJson_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final metadataJson = metadataJson_lifted.value;
    new_offset += metadataJson_lifted.bytesRead;
    final intendedBalanceSats_lifted = FfiConverterInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final intendedBalanceSats = intendedBalanceSats_lifted.value;
    new_offset += intendedBalanceSats_lifted.bytesRead;
    final effectiveBalanceSats_lifted = FfiConverterInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final effectiveBalanceSats = effectiveBalanceSats_lifted.value;
    new_offset += effectiveBalanceSats_lifted.bytesRead;
    final offchainFeeSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final offchainFeeSats = offchainFeeSats_lifted.value;
    new_offset += offchainFeeSats_lifted.bytesRead;
    final sentToAddresses_lifted = FfiConverterSequenceString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final sentToAddresses = sentToAddresses_lifted.value;
    new_offset += sentToAddresses_lifted.bytesRead;
    final receivedOnAddresses_lifted = FfiConverterSequenceString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final receivedOnAddresses = receivedOnAddresses_lifted.value;
    new_offset += receivedOnAddresses_lifted.bytesRead;
    final inputVtxoIds_lifted = FfiConverterSequenceString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final inputVtxoIds = inputVtxoIds_lifted.value;
    new_offset += inputVtxoIds_lifted.bytesRead;
    final outputVtxoIds_lifted = FfiConverterSequenceString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final outputVtxoIds = outputVtxoIds_lifted.value;
    new_offset += outputVtxoIds_lifted.bytesRead;
    final createdAt_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final createdAt = createdAt_lifted.value;
    new_offset += createdAt_lifted.bytesRead;
    final updatedAt_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final updatedAt = updatedAt_lifted.value;
    new_offset += updatedAt_lifted.bytesRead;
    final completedAt_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final completedAt = completedAt_lifted.value;
    new_offset += completedAt_lifted.bytesRead;
    return LiftRetVal(
      Movement(
        id,
        status,
        subsystemName,
        subsystemKind,
        metadataJson,
        intendedBalanceSats,
        effectiveBalanceSats,
        offchainFeeSats,
        sentToAddresses,
        receivedOnAddresses,
        inputVtxoIds,
        outputVtxoIds,
        createdAt,
        updatedAt,
        completedAt,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(Movement value) {
    final total_length =
        FfiConverterUInt32.allocationSize(value.id) +
        FfiConverterString.allocationSize(value.status) +
        FfiConverterString.allocationSize(value.subsystemName) +
        FfiConverterString.allocationSize(value.subsystemKind) +
        FfiConverterString.allocationSize(value.metadataJson) +
        FfiConverterInt64.allocationSize(value.intendedBalanceSats) +
        FfiConverterInt64.allocationSize(value.effectiveBalanceSats) +
        FfiConverterUInt64.allocationSize(value.offchainFeeSats) +
        FfiConverterSequenceString.allocationSize(value.sentToAddresses) +
        FfiConverterSequenceString.allocationSize(value.receivedOnAddresses) +
        FfiConverterSequenceString.allocationSize(value.inputVtxoIds) +
        FfiConverterSequenceString.allocationSize(value.outputVtxoIds) +
        FfiConverterString.allocationSize(value.createdAt) +
        FfiConverterString.allocationSize(value.updatedAt) +
        FfiConverterOptionalString.allocationSize(value.completedAt) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(Movement value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterUInt32.write(
      value.id,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.status,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.subsystemName,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.subsystemKind,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.metadataJson,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterInt64.write(
      value.intendedBalanceSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterInt64.write(
      value.effectiveBalanceSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.offchainFeeSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterSequenceString.write(
      value.sentToAddresses,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterSequenceString.write(
      value.receivedOnAddresses,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterSequenceString.write(
      value.inputVtxoIds,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterSequenceString.write(
      value.outputVtxoIds,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.createdAt,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.updatedAt,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalString.write(
      value.completedAt,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(Movement value) {
    return FfiConverterUInt32.allocationSize(value.id) +
        FfiConverterString.allocationSize(value.status) +
        FfiConverterString.allocationSize(value.subsystemName) +
        FfiConverterString.allocationSize(value.subsystemKind) +
        FfiConverterString.allocationSize(value.metadataJson) +
        FfiConverterInt64.allocationSize(value.intendedBalanceSats) +
        FfiConverterInt64.allocationSize(value.effectiveBalanceSats) +
        FfiConverterUInt64.allocationSize(value.offchainFeeSats) +
        FfiConverterSequenceString.allocationSize(value.sentToAddresses) +
        FfiConverterSequenceString.allocationSize(value.receivedOnAddresses) +
        FfiConverterSequenceString.allocationSize(value.inputVtxoIds) +
        FfiConverterSequenceString.allocationSize(value.outputVtxoIds) +
        FfiConverterString.allocationSize(value.createdAt) +
        FfiConverterString.allocationSize(value.updatedAt) +
        FfiConverterOptionalString.allocationSize(value.completedAt) +
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
  final String errorMessage;
  NetworkBarkException(String this.errorMessage);
  NetworkBarkException._(String this.errorMessage);
  static LiftRetVal<NetworkBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(NetworkBarkException._(errorMessage), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 1);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "NetworkBarkException($errorMessage)";
  }
}

class DatabaseBarkException extends BarkException {
  final String errorMessage;
  DatabaseBarkException(String this.errorMessage);
  DatabaseBarkException._(String this.errorMessage);
  static LiftRetVal<DatabaseBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(DatabaseBarkException._(errorMessage), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 2);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "DatabaseBarkException($errorMessage)";
  }
}

class InvalidMnemonicBarkException extends BarkException {
  final String errorMessage;
  InvalidMnemonicBarkException(String this.errorMessage);
  InvalidMnemonicBarkException._(String this.errorMessage);
  static LiftRetVal<InvalidMnemonicBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(InvalidMnemonicBarkException._(errorMessage), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 3);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InvalidMnemonicBarkException($errorMessage)";
  }
}

class InvalidAddressBarkException extends BarkException {
  final String errorMessage;
  InvalidAddressBarkException(String this.errorMessage);
  InvalidAddressBarkException._(String this.errorMessage);
  static LiftRetVal<InvalidAddressBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(InvalidAddressBarkException._(errorMessage), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 4);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InvalidAddressBarkException($errorMessage)";
  }
}

class InvalidInvoiceBarkException extends BarkException {
  final String errorMessage;
  InvalidInvoiceBarkException(String this.errorMessage);
  InvalidInvoiceBarkException._(String this.errorMessage);
  static LiftRetVal<InvalidInvoiceBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(InvalidInvoiceBarkException._(errorMessage), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 5);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InvalidInvoiceBarkException($errorMessage)";
  }
}

class InsufficientFundsBarkException extends BarkException {
  final String errorMessage;
  InsufficientFundsBarkException(String this.errorMessage);
  InsufficientFundsBarkException._(String this.errorMessage);
  static LiftRetVal<InsufficientFundsBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(
      InsufficientFundsBarkException._(errorMessage),
      new_offset,
    );
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 6);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InsufficientFundsBarkException($errorMessage)";
  }
}

class NotFoundBarkException extends BarkException {
  final String errorMessage;
  NotFoundBarkException(String this.errorMessage);
  NotFoundBarkException._(String this.errorMessage);
  static LiftRetVal<NotFoundBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(NotFoundBarkException._(errorMessage), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 7);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "NotFoundBarkException($errorMessage)";
  }
}

class ServerConnectionBarkException extends BarkException {
  final String errorMessage;
  ServerConnectionBarkException(String this.errorMessage);
  ServerConnectionBarkException._(String this.errorMessage);
  static LiftRetVal<ServerConnectionBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(
      ServerConnectionBarkException._(errorMessage),
      new_offset,
    );
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 8);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "ServerConnectionBarkException($errorMessage)";
  }
}

class InternalBarkException extends BarkException {
  final String errorMessage;
  InternalBarkException(String this.errorMessage);
  InternalBarkException._(String this.errorMessage);
  static LiftRetVal<InternalBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(InternalBarkException._(errorMessage), new_offset);
  }

  @override
  RustBuffer lower() {
    final buf = Uint8List(allocationSize());
    write(buf);
    return toRustBuffer(buf);
  }

  @override
  int allocationSize() {
    return FfiConverterString.allocationSize(errorMessage) + 4;
  }

  @override
  int write(Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 9);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "InternalBarkException($errorMessage)";
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
  List<Vtxo> allVtxos();
  ArkInfo? arkInfo();
  Balance balance();
  LightningInvoice bolt11Invoice(int amountSats);
  int claimableLightningReceiveBalanceSats();
  Config config();
  List<Vtxo> getExpiringVtxos(int thresholdBlocks);
  Vtxo getVtxoById(String vtxoId);
  List<Vtxo> getVtxosToRefresh();
  void maintenance();
  String? maintenanceRefresh();
  List<Movement> movements();
  String newAddress();
  AddressWithIndex newAddressWithIndex();
  OffboardResult offboardAll(String bitcoinAddress);
  String offboardVtxos(List<String> vtxoIds, String bitcoinAddress);
  LightningPaymentResult payLightningAddress(
    String lightningAddress,
    int amountSats,
    String? comment,
  );
  LightningPaymentResult payLightningInvoice(String invoice, int? amountSats);
  String peakAddress(int index);
  List<LightningReceiveStatus> pendingLightningReceives();
  List<LightningSendStatus> pendingLightningSends();
  WalletProperties properties();
  String? refreshVtxos(List<String> vtxoIds);
  String sendArkoorPayment(String arkAddress, int amountSats);
  String sendRoundOnchainPayment(String address, int amountSats);
  List<Vtxo> spendableVtxos();
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

  List<Vtxo> allVtxos() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_all_vtxos(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceVtxo.lift,
      barkExceptionErrorHandler,
    );
  }

  ArkInfo? arkInfo() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_ark_info(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterOptionalArkInfo.lift,
      null,
    );
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

  int claimableLightningReceiveBalanceSats() {
    return rustCallWithLifter(
      (status) =>
          uniffi_bark_ffi_fn_method_wallet_claimable_lightning_receive_balance_sats(
            uniffiClonePointer(),
            status,
          ),
      FfiConverterUInt64.lift,
      barkExceptionErrorHandler,
    );
  }

  Config config() {
    return rustCallWithLifter(
      (status) =>
          uniffi_bark_ffi_fn_method_wallet_config(uniffiClonePointer(), status),
      FfiConverterConfig.lift,
      null,
    );
  }

  List<Vtxo> getExpiringVtxos(int thresholdBlocks) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_get_expiring_vtxos(
        uniffiClonePointer(),
        FfiConverterUInt32.lower(thresholdBlocks),
        status,
      ),
      FfiConverterSequenceVtxo.lift,
      barkExceptionErrorHandler,
    );
  }

  Vtxo getVtxoById(String vtxoId) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_get_vtxo_by_id(
        uniffiClonePointer(),
        FfiConverterString.lower(vtxoId),
        status,
      ),
      FfiConverterVtxo.lift,
      barkExceptionErrorHandler,
    );
  }

  List<Vtxo> getVtxosToRefresh() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_get_vtxos_to_refresh(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceVtxo.lift,
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

  String? maintenanceRefresh() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_maintenance_refresh(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterOptionalString.lift,
      barkExceptionErrorHandler,
    );
  }

  List<Movement> movements() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_movements(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceMovement.lift,
      barkExceptionErrorHandler,
    );
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

  AddressWithIndex newAddressWithIndex() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_new_address_with_index(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterAddressWithIndex.lift,
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

  String offboardVtxos(List<String> vtxoIds, String bitcoinAddress) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_offboard_vtxos(
        uniffiClonePointer(),
        FfiConverterSequenceString.lower(vtxoIds),
        FfiConverterString.lower(bitcoinAddress),
        status,
      ),
      FfiConverterString.lift,
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

  String peakAddress(int index) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_peak_address(
        uniffiClonePointer(),
        FfiConverterUInt32.lower(index),
        status,
      ),
      FfiConverterString.lift,
      barkExceptionErrorHandler,
    );
  }

  List<LightningReceiveStatus> pendingLightningReceives() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pending_lightning_receives(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceLightningReceiveStatus.lift,
      barkExceptionErrorHandler,
    );
  }

  List<LightningSendStatus> pendingLightningSends() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pending_lightning_sends(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceLightningSendStatus.lift,
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

  String? refreshVtxos(List<String> vtxoIds) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_refresh_vtxos(
        uniffiClonePointer(),
        FfiConverterSequenceString.lower(vtxoIds),
        status,
      ),
      FfiConverterOptionalString.lift,
      barkExceptionErrorHandler,
    );
  }

  String sendArkoorPayment(String arkAddress, int amountSats) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_send_arkoor_payment(
        uniffiClonePointer(),
        FfiConverterString.lower(arkAddress),
        FfiConverterUInt64.lower(amountSats),
        status,
      ),
      FfiConverterString.lift,
      barkExceptionErrorHandler,
    );
  }

  String sendRoundOnchainPayment(String address, int amountSats) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_send_round_onchain_payment(
        uniffiClonePointer(),
        FfiConverterString.lower(address),
        FfiConverterUInt64.lower(amountSats),
        status,
      ),
      FfiConverterString.lift,
      barkExceptionErrorHandler,
    );
  }

  List<Vtxo> spendableVtxos() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_spendable_vtxos(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceVtxo.lift,
      barkExceptionErrorHandler,
    );
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

class FfiConverterSequenceString {
  static List<String> lift(RustBuffer buf) {
    return FfiConverterSequenceString.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<String>> read(Uint8List buf) {
    List<String> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterString.read(Uint8List.view(buf.buffer, offset));
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<String> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterString.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<String> value) {
    return value
            .map((l) => FfiConverterString.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<String> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
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

class FfiConverterSequenceLightningSendStatus {
  static List<LightningSendStatus> lift(RustBuffer buf) {
    return FfiConverterSequenceLightningSendStatus.read(
      buf.asUint8List(),
    ).value;
  }

  static LiftRetVal<List<LightningSendStatus>> read(Uint8List buf) {
    List<LightningSendStatus> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterLightningSendStatus.read(
        Uint8List.view(buf.buffer, offset),
      );
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<LightningSendStatus> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterLightningSendStatus.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<LightningSendStatus> value) {
    return value
            .map((l) => FfiConverterLightningSendStatus.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<LightningSendStatus> value) {
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

class FfiConverterInt64 {
  static int lift(int value) => value;
  static LiftRetVal<int> read(Uint8List buf) {
    return LiftRetVal(buf.buffer.asByteData(buf.offsetInBytes).getInt64(0), 8);
  }

  static int lower(int value) {
    if (value < -9223372036854775808 || value > 9223372036854775807) {
      throw ArgumentError("Value out of range for i64: " + value.toString());
    }
    return value;
  }

  static int allocationSize([int value = 0]) {
    return 8;
  }

  static int write(int value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt64(0, lower(value));
    return 8;
  }
}

class FfiConverterSequenceMovement {
  static List<Movement> lift(RustBuffer buf) {
    return FfiConverterSequenceMovement.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<Movement>> read(Uint8List buf) {
    List<Movement> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterMovement.read(Uint8List.view(buf.buffer, offset));
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<Movement> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterMovement.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<Movement> value) {
    return value
            .map((l) => FfiConverterMovement.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<Movement> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
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

class FfiConverterOptionalArkInfo {
  static ArkInfo? lift(RustBuffer buf) {
    return FfiConverterOptionalArkInfo.read(buf.asUint8List()).value;
  }

  static LiftRetVal<ArkInfo?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterArkInfo.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<ArkInfo?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([ArkInfo? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterArkInfo.allocationSize(value) + 1;
  }

  static RustBuffer lower(ArkInfo? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalArkInfo.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalArkInfo.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(ArkInfo? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterArkInfo.write(
          value,
          Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
        ) +
        1;
  }
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

class FfiConverterSequenceLightningReceiveStatus {
  static List<LightningReceiveStatus> lift(RustBuffer buf) {
    return FfiConverterSequenceLightningReceiveStatus.read(
      buf.asUint8List(),
    ).value;
  }

  static LiftRetVal<List<LightningReceiveStatus>> read(Uint8List buf) {
    List<LightningReceiveStatus> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterLightningReceiveStatus.read(
        Uint8List.view(buf.buffer, offset),
      );
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<LightningReceiveStatus> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterLightningReceiveStatus.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<LightningReceiveStatus> value) {
    return value
            .map((l) => FfiConverterLightningReceiveStatus.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<LightningReceiveStatus> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
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
String generateMnemonic() {
  return rustCallWithLifter(
    (status) => uniffi_bark_ffi_fn_func_generate_mnemonic(status),
    FfiConverterString.lift,
    barkExceptionErrorHandler,
  );
}

bool validateArkAddress(String address) {
  return rustCallWithLifter(
    (status) => uniffi_bark_ffi_fn_func_validate_ark_address(
      FfiConverterString.lower(address),
      status,
    ),
    FfiConverterBool.lift,
    barkExceptionErrorHandler,
  );
}

bool validateMnemonic(String mnemonic) {
  return rustCallWithLifter(
    (status) => uniffi_bark_ffi_fn_func_validate_mnemonic(
      FfiConverterString.lower(mnemonic),
      status,
    ),
    FfiConverterBool.lift,
    barkExceptionErrorHandler,
  );
}

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
external RustBuffer uniffi_bark_ffi_fn_method_wallet_all_vtxos(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_ark_info(
  Pointer<Void> ptr,
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

@Native<Uint64 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int
uniffi_bark_ffi_fn_method_wallet_claimable_lightning_receive_balance_sats(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_config(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Uint32, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_get_expiring_vtxos(
  Pointer<Void> ptr,
  int threshold_blocks,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_get_vtxo_by_id(
  Pointer<Void> ptr,
  RustBuffer vtxo_id,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_get_vtxos_to_refresh(
  Pointer<Void> ptr,
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
external RustBuffer uniffi_bark_ffi_fn_method_wallet_maintenance_refresh(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_movements(
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

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_new_address_with_index(
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
    RustBuffer,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_offboard_vtxos(
  Pointer<Void> ptr,
  RustBuffer vtxo_ids,
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

@Native<RustBuffer Function(Pointer<Void>, Uint32, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_peak_address(
  Pointer<Void> ptr,
  int index,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_pending_lightning_receives(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_pending_lightning_sends(
  Pointer<Void> ptr,
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
  RustBuffer Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_refresh_vtxos(
  Pointer<Void> ptr,
  RustBuffer vtxo_ids,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    Uint64,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_send_arkoor_payment(
  Pointer<Void> ptr,
  RustBuffer ark_address,
  int amount_sats,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    Uint64,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_send_round_onchain_payment(
  Pointer<Void> ptr,
  RustBuffer address,
  int amount_sats,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_spendable_vtxos(
  Pointer<Void> ptr,
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

@Native<RustBuffer Function(Pointer<RustCallStatus>)>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_func_generate_mnemonic(
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Int8 Function(RustBuffer, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int uniffi_bark_ffi_fn_func_validate_ark_address(
  RustBuffer address,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Int8 Function(RustBuffer, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int uniffi_bark_ffi_fn_func_validate_mnemonic(
  RustBuffer mnemonic,
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
external int uniffi_bark_ffi_checksum_func_generate_mnemonic();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_func_validate_ark_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_func_validate_mnemonic();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_all_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_ark_info();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_balance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_bolt11_invoice();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_claimable_lightning_receive_balance_sats();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_config();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_expiring_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_vtxo_by_id();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_vtxos_to_refresh();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_maintenance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_maintenance_refresh();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_movements();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_new_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_new_address_with_index();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_offboard_all();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_offboard_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pay_lightning_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pay_lightning_invoice();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_peak_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_pending_lightning_receives();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pending_lightning_sends();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_properties();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_refresh_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_send_arkoor_payment();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_send_round_onchain_payment();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_spendable_vtxos();

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
  if (uniffi_bark_ffi_checksum_func_generate_mnemonic() != 49933) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_func_validate_ark_address() != 49932) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_func_validate_mnemonic() != 2707) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_all_vtxos() != 48937) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_ark_info() != 36948) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_balance() != 11221) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_bolt11_invoice() != 64551) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_claimable_lightning_receive_balance_sats() !=
      64974) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_config() != 57616) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_expiring_vtxos() != 19482) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_vtxo_by_id() != 41126) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_vtxos_to_refresh() != 55019) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_maintenance() != 9626) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_maintenance_refresh() != 29994) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_movements() != 23904) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_new_address() != 25174) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_new_address_with_index() !=
      52446) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_offboard_all() != 61123) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_offboard_vtxos() != 19001) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pay_lightning_address() != 8340) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pay_lightning_invoice() != 3587) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_peak_address() != 23469) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pending_lightning_receives() !=
      7863) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pending_lightning_sends() !=
      5489) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_properties() != 34715) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_refresh_vtxos() != 720) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_send_arkoor_payment() != 8472) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_send_round_onchain_payment() !=
      21156) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_spendable_vtxos() != 48976) {
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

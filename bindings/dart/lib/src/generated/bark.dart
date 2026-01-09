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
  final int claimableLightningReceiveSats;
  final int pendingBoardSats;
  Balance(
    this.spendableSats,
    this.pendingInRoundSats,
    this.pendingExitSats,
    this.pendingLightningSendSats,
    this.claimableLightningReceiveSats,
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
    final claimableLightningReceiveSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final claimableLightningReceiveSats =
        claimableLightningReceiveSats_lifted.value;
    new_offset += claimableLightningReceiveSats_lifted.bytesRead;
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
        claimableLightningReceiveSats,
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
        FfiConverterUInt64.allocationSize(value.claimableLightningReceiveSats) +
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
      value.claimableLightningReceiveSats,
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
        FfiConverterUInt64.allocationSize(value.claimableLightningReceiveSats) +
        FfiConverterUInt64.allocationSize(value.pendingBoardSats) +
        0;
  }
}

class BlockRef {
  final int height;
  final String hash;
  BlockRef(this.height, this.hash);
}

class FfiConverterBlockRef {
  static BlockRef lift(RustBuffer buf) {
    return FfiConverterBlockRef.read(buf.asUint8List()).value;
  }

  static LiftRetVal<BlockRef> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final height_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final height = height_lifted.value;
    new_offset += height_lifted.bytesRead;
    final hash_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final hash = hash_lifted.value;
    new_offset += hash_lifted.bytesRead;
    return LiftRetVal(BlockRef(height, hash), new_offset - buf.offsetInBytes);
  }

  static RustBuffer lower(BlockRef value) {
    final total_length =
        FfiConverterUInt32.allocationSize(value.height) +
        FfiConverterString.allocationSize(value.hash) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(BlockRef value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterUInt32.write(
      value.height,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.hash,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(BlockRef value) {
    return FfiConverterUInt32.allocationSize(value.height) +
        FfiConverterString.allocationSize(value.hash) +
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

class CpfpParams {
  final String txHex;
  final String feesType;
  final int effectiveFeeRateSatPerVb;
  final int? currentPackageFeeSats;
  CpfpParams(
    this.txHex,
    this.feesType,
    this.effectiveFeeRateSatPerVb,
    this.currentPackageFeeSats,
  );
}

class FfiConverterCpfpParams {
  static CpfpParams lift(RustBuffer buf) {
    return FfiConverterCpfpParams.read(buf.asUint8List()).value;
  }

  static LiftRetVal<CpfpParams> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final txHex_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final txHex = txHex_lifted.value;
    new_offset += txHex_lifted.bytesRead;
    final feesType_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final feesType = feesType_lifted.value;
    new_offset += feesType_lifted.bytesRead;
    final effectiveFeeRateSatPerVb_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final effectiveFeeRateSatPerVb = effectiveFeeRateSatPerVb_lifted.value;
    new_offset += effectiveFeeRateSatPerVb_lifted.bytesRead;
    final currentPackageFeeSats_lifted = FfiConverterOptionalUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final currentPackageFeeSats = currentPackageFeeSats_lifted.value;
    new_offset += currentPackageFeeSats_lifted.bytesRead;
    return LiftRetVal(
      CpfpParams(
        txHex,
        feesType,
        effectiveFeeRateSatPerVb,
        currentPackageFeeSats,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(CpfpParams value) {
    final total_length =
        FfiConverterString.allocationSize(value.txHex) +
        FfiConverterString.allocationSize(value.feesType) +
        FfiConverterUInt64.allocationSize(value.effectiveFeeRateSatPerVb) +
        FfiConverterOptionalUInt64.allocationSize(value.currentPackageFeeSats) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(CpfpParams value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.txHex,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.feesType,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.effectiveFeeRateSatPerVb,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalUInt64.write(
      value.currentPackageFeeSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(CpfpParams value) {
    return FfiConverterString.allocationSize(value.txHex) +
        FfiConverterString.allocationSize(value.feesType) +
        FfiConverterUInt64.allocationSize(value.effectiveFeeRateSatPerVb) +
        FfiConverterOptionalUInt64.allocationSize(value.currentPackageFeeSats) +
        0;
  }
}

class Destination {
  final String address;
  final int amountSats;
  Destination(this.address, this.amountSats);
}

class FfiConverterDestination {
  static Destination lift(RustBuffer buf) {
    return FfiConverterDestination.read(buf.asUint8List()).value;
  }

  static LiftRetVal<Destination> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final address_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final address = address_lifted.value;
    new_offset += address_lifted.bytesRead;
    final amountSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final amountSats = amountSats_lifted.value;
    new_offset += amountSats_lifted.bytesRead;
    return LiftRetVal(
      Destination(address, amountSats),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(Destination value) {
    final total_length =
        FfiConverterString.allocationSize(value.address) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(Destination value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.address,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.amountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(Destination value) {
    return FfiConverterString.allocationSize(value.address) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        0;
  }
}

class ExitClaimTransaction {
  final String psbtBase64;
  final int feeSats;
  ExitClaimTransaction(this.psbtBase64, this.feeSats);
}

class FfiConverterExitClaimTransaction {
  static ExitClaimTransaction lift(RustBuffer buf) {
    return FfiConverterExitClaimTransaction.read(buf.asUint8List()).value;
  }

  static LiftRetVal<ExitClaimTransaction> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final psbtBase64_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final psbtBase64 = psbtBase64_lifted.value;
    new_offset += psbtBase64_lifted.bytesRead;
    final feeSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final feeSats = feeSats_lifted.value;
    new_offset += feeSats_lifted.bytesRead;
    return LiftRetVal(
      ExitClaimTransaction(psbtBase64, feeSats),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(ExitClaimTransaction value) {
    final total_length =
        FfiConverterString.allocationSize(value.psbtBase64) +
        FfiConverterUInt64.allocationSize(value.feeSats) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(ExitClaimTransaction value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.psbtBase64,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.feeSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(ExitClaimTransaction value) {
    return FfiConverterString.allocationSize(value.psbtBase64) +
        FfiConverterUInt64.allocationSize(value.feeSats) +
        0;
  }
}

class ExitProgressStatus {
  final String vtxoId;
  final String state;
  final String? error;
  ExitProgressStatus(this.vtxoId, this.state, this.error);
}

class FfiConverterExitProgressStatus {
  static ExitProgressStatus lift(RustBuffer buf) {
    return FfiConverterExitProgressStatus.read(buf.asUint8List()).value;
  }

  static LiftRetVal<ExitProgressStatus> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final vtxoId_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoId = vtxoId_lifted.value;
    new_offset += vtxoId_lifted.bytesRead;
    final state_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final state = state_lifted.value;
    new_offset += state_lifted.bytesRead;
    final error_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final error = error_lifted.value;
    new_offset += error_lifted.bytesRead;
    return LiftRetVal(
      ExitProgressStatus(vtxoId, state, error),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(ExitProgressStatus value) {
    final total_length =
        FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterString.allocationSize(value.state) +
        FfiConverterOptionalString.allocationSize(value.error) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(ExitProgressStatus value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.vtxoId,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.state,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalString.write(
      value.error,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(ExitProgressStatus value) {
    return FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterString.allocationSize(value.state) +
        FfiConverterOptionalString.allocationSize(value.error) +
        0;
  }
}

class ExitTransactionStatus {
  final String vtxoId;
  final String state;
  final List<String>? history;
  final int transactionCount;
  ExitTransactionStatus(
    this.vtxoId,
    this.state,
    this.history,
    this.transactionCount,
  );
}

class FfiConverterExitTransactionStatus {
  static ExitTransactionStatus lift(RustBuffer buf) {
    return FfiConverterExitTransactionStatus.read(buf.asUint8List()).value;
  }

  static LiftRetVal<ExitTransactionStatus> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final vtxoId_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoId = vtxoId_lifted.value;
    new_offset += vtxoId_lifted.bytesRead;
    final state_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final state = state_lifted.value;
    new_offset += state_lifted.bytesRead;
    final history_lifted = FfiConverterOptionalSequenceString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final history = history_lifted.value;
    new_offset += history_lifted.bytesRead;
    final transactionCount_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final transactionCount = transactionCount_lifted.value;
    new_offset += transactionCount_lifted.bytesRead;
    return LiftRetVal(
      ExitTransactionStatus(vtxoId, state, history, transactionCount),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(ExitTransactionStatus value) {
    final total_length =
        FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterString.allocationSize(value.state) +
        FfiConverterOptionalSequenceString.allocationSize(value.history) +
        FfiConverterUInt32.allocationSize(value.transactionCount) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(ExitTransactionStatus value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.vtxoId,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.state,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterOptionalSequenceString.write(
      value.history,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.transactionCount,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(ExitTransactionStatus value) {
    return FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterString.allocationSize(value.state) +
        FfiConverterOptionalSequenceString.allocationSize(value.history) +
        FfiConverterUInt32.allocationSize(value.transactionCount) +
        0;
  }
}

class ExitVtxo {
  final String vtxoId;
  final int amountSats;
  final String state;
  final bool isClaimable;
  ExitVtxo(this.vtxoId, this.amountSats, this.state, this.isClaimable);
}

class FfiConverterExitVtxo {
  static ExitVtxo lift(RustBuffer buf) {
    return FfiConverterExitVtxo.read(buf.asUint8List()).value;
  }

  static LiftRetVal<ExitVtxo> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final vtxoId_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoId = vtxoId_lifted.value;
    new_offset += vtxoId_lifted.bytesRead;
    final amountSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final amountSats = amountSats_lifted.value;
    new_offset += amountSats_lifted.bytesRead;
    final state_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final state = state_lifted.value;
    new_offset += state_lifted.bytesRead;
    final isClaimable_lifted = FfiConverterBool.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final isClaimable = isClaimable_lifted.value;
    new_offset += isClaimable_lifted.bytesRead;
    return LiftRetVal(
      ExitVtxo(vtxoId, amountSats, state, isClaimable),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(ExitVtxo value) {
    final total_length =
        FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterString.allocationSize(value.state) +
        FfiConverterBool.allocationSize(value.isClaimable) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(ExitVtxo value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.vtxoId,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.amountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.state,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterBool.write(
      value.isClaimable,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(ExitVtxo value) {
    return FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterString.allocationSize(value.state) +
        FfiConverterBool.allocationSize(value.isClaimable) +
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

class LightningReceive {
  final String paymentHash;
  final String invoice;
  final int amountSats;
  final bool hasHtlcVtxos;
  final bool preimageRevealed;
  LightningReceive(
    this.paymentHash,
    this.invoice,
    this.amountSats,
    this.hasHtlcVtxos,
    this.preimageRevealed,
  );
}

class FfiConverterLightningReceive {
  static LightningReceive lift(RustBuffer buf) {
    return FfiConverterLightningReceive.read(buf.asUint8List()).value;
  }

  static LiftRetVal<LightningReceive> read(Uint8List buf) {
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
      LightningReceive(
        paymentHash,
        invoice,
        amountSats,
        hasHtlcVtxos,
        preimageRevealed,
      ),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(LightningReceive value) {
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

  static int write(LightningReceive value, Uint8List buf) {
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

  static int allocationSize(LightningReceive value) {
    return FfiConverterString.allocationSize(value.paymentHash) +
        FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterBool.allocationSize(value.hasHtlcVtxos) +
        FfiConverterBool.allocationSize(value.preimageRevealed) +
        0;
  }
}

class LightningSend {
  final String invoice;
  final int amountSats;
  final int htlcVtxoCount;
  final String? preimage;
  LightningSend(
    this.invoice,
    this.amountSats,
    this.htlcVtxoCount,
    this.preimage,
  );
}

class FfiConverterLightningSend {
  static LightningSend lift(RustBuffer buf) {
    return FfiConverterLightningSend.read(buf.asUint8List()).value;
  }

  static LiftRetVal<LightningSend> read(Uint8List buf) {
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
    final preimage_lifted = FfiConverterOptionalString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final preimage = preimage_lifted.value;
    new_offset += preimage_lifted.bytesRead;
    return LiftRetVal(
      LightningSend(invoice, amountSats, htlcVtxoCount, preimage),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(LightningSend value) {
    final total_length =
        FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterUInt32.allocationSize(value.htlcVtxoCount) +
        FfiConverterOptionalString.allocationSize(value.preimage) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(LightningSend value, Uint8List buf) {
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
    new_offset += FfiConverterOptionalString.write(
      value.preimage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(LightningSend value) {
    return FfiConverterString.allocationSize(value.invoice) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterUInt32.allocationSize(value.htlcVtxoCount) +
        FfiConverterOptionalString.allocationSize(value.preimage) +
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
  final List<String> exitedVtxoIds;
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
    this.exitedVtxoIds,
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
    final exitedVtxoIds_lifted = FfiConverterSequenceString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final exitedVtxoIds = exitedVtxoIds_lifted.value;
    new_offset += exitedVtxoIds_lifted.bytesRead;
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
        exitedVtxoIds,
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
        FfiConverterSequenceString.allocationSize(value.exitedVtxoIds) +
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
    new_offset += FfiConverterSequenceString.write(
      value.exitedVtxoIds,
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
        FfiConverterSequenceString.allocationSize(value.exitedVtxoIds) +
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

class OnchainBalance {
  final int confirmedSats;
  final int pendingSats;
  final int totalSats;
  OnchainBalance(this.confirmedSats, this.pendingSats, this.totalSats);
}

class FfiConverterOnchainBalance {
  static OnchainBalance lift(RustBuffer buf) {
    return FfiConverterOnchainBalance.read(buf.asUint8List()).value;
  }

  static LiftRetVal<OnchainBalance> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final confirmedSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final confirmedSats = confirmedSats_lifted.value;
    new_offset += confirmedSats_lifted.bytesRead;
    final pendingSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final pendingSats = pendingSats_lifted.value;
    new_offset += pendingSats_lifted.bytesRead;
    final totalSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final totalSats = totalSats_lifted.value;
    new_offset += totalSats_lifted.bytesRead;
    return LiftRetVal(
      OnchainBalance(confirmedSats, pendingSats, totalSats),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(OnchainBalance value) {
    final total_length =
        FfiConverterUInt64.allocationSize(value.confirmedSats) +
        FfiConverterUInt64.allocationSize(value.pendingSats) +
        FfiConverterUInt64.allocationSize(value.totalSats) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(OnchainBalance value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterUInt64.write(
      value.confirmedSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.pendingSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.totalSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(OnchainBalance value) {
    return FfiConverterUInt64.allocationSize(value.confirmedSats) +
        FfiConverterUInt64.allocationSize(value.pendingSats) +
        FfiConverterUInt64.allocationSize(value.totalSats) +
        0;
  }
}

class OutPoint {
  final String txid;
  final int vout;
  OutPoint(this.txid, this.vout);
}

class FfiConverterOutPoint {
  static OutPoint lift(RustBuffer buf) {
    return FfiConverterOutPoint.read(buf.asUint8List()).value;
  }

  static LiftRetVal<OutPoint> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final txid_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final txid = txid_lifted.value;
    new_offset += txid_lifted.bytesRead;
    final vout_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vout = vout_lifted.value;
    new_offset += vout_lifted.bytesRead;
    return LiftRetVal(OutPoint(txid, vout), new_offset - buf.offsetInBytes);
  }

  static RustBuffer lower(OutPoint value) {
    final total_length =
        FfiConverterString.allocationSize(value.txid) +
        FfiConverterUInt32.allocationSize(value.vout) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(OutPoint value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.txid,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt32.write(
      value.vout,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(OutPoint value) {
    return FfiConverterString.allocationSize(value.txid) +
        FfiConverterUInt32.allocationSize(value.vout) +
        0;
  }
}

class PendingBoard {
  final String vtxoId;
  final int amountSats;
  final String txid;
  PendingBoard(this.vtxoId, this.amountSats, this.txid);
}

class FfiConverterPendingBoard {
  static PendingBoard lift(RustBuffer buf) {
    return FfiConverterPendingBoard.read(buf.asUint8List()).value;
  }

  static LiftRetVal<PendingBoard> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final vtxoId_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final vtxoId = vtxoId_lifted.value;
    new_offset += vtxoId_lifted.bytesRead;
    final amountSats_lifted = FfiConverterUInt64.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final amountSats = amountSats_lifted.value;
    new_offset += amountSats_lifted.bytesRead;
    final txid_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final txid = txid_lifted.value;
    new_offset += txid_lifted.bytesRead;
    return LiftRetVal(
      PendingBoard(vtxoId, amountSats, txid),
      new_offset - buf.offsetInBytes,
    );
  }

  static RustBuffer lower(PendingBoard value) {
    final total_length =
        FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterString.allocationSize(value.txid) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(PendingBoard value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterString.write(
      value.vtxoId,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterUInt64.write(
      value.amountSats,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterString.write(
      value.txid,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(PendingBoard value) {
    return FfiConverterString.allocationSize(value.vtxoId) +
        FfiConverterUInt64.allocationSize(value.amountSats) +
        FfiConverterString.allocationSize(value.txid) +
        0;
  }
}

class RoundState {
  final int id;
  final bool ongoing;
  RoundState(this.id, this.ongoing);
}

class FfiConverterRoundState {
  static RoundState lift(RustBuffer buf) {
    return FfiConverterRoundState.read(buf.asUint8List()).value;
  }

  static LiftRetVal<RoundState> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final id_lifted = FfiConverterUInt32.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final id = id_lifted.value;
    new_offset += id_lifted.bytesRead;
    final ongoing_lifted = FfiConverterBool.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final ongoing = ongoing_lifted.value;
    new_offset += ongoing_lifted.bytesRead;
    return LiftRetVal(RoundState(id, ongoing), new_offset - buf.offsetInBytes);
  }

  static RustBuffer lower(RoundState value) {
    final total_length =
        FfiConverterUInt32.allocationSize(value.id) +
        FfiConverterBool.allocationSize(value.ongoing) +
        0;
    final buf = Uint8List(total_length);
    write(value, buf);
    return toRustBuffer(buf);
  }

  static int write(RoundState value, Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    new_offset += FfiConverterUInt32.write(
      value.id,
      Uint8List.view(buf.buffer, new_offset),
    );
    new_offset += FfiConverterBool.write(
      value.ongoing,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset - buf.offsetInBytes;
  }

  static int allocationSize(RoundState value) {
    return FfiConverterUInt32.allocationSize(value.id) +
        FfiConverterBool.allocationSize(value.ongoing) +
        0;
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
        return InvalidPsbtBarkException.read(subview);
      case 7:
        return InvalidTransactionBarkException.read(subview);
      case 8:
        return InsufficientFundsBarkException.read(subview);
      case 9:
        return NotFoundBarkException.read(subview);
      case 10:
        return ServerConnectionBarkException.read(subview);
      case 11:
        return InternalBarkException.read(subview);
      case 12:
        return OnchainWalletRequiredBarkException.read(subview);
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

class InvalidPsbtBarkException extends BarkException {
  final String errorMessage;
  InvalidPsbtBarkException(String this.errorMessage);
  InvalidPsbtBarkException._(String this.errorMessage);
  static LiftRetVal<InvalidPsbtBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(InvalidPsbtBarkException._(errorMessage), new_offset);
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
    return "InvalidPsbtBarkException($errorMessage)";
  }
}

class InvalidTransactionBarkException extends BarkException {
  final String errorMessage;
  InvalidTransactionBarkException(String this.errorMessage);
  InvalidTransactionBarkException._(String this.errorMessage);
  static LiftRetVal<InvalidTransactionBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(
      InvalidTransactionBarkException._(errorMessage),
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
    return "InvalidTransactionBarkException($errorMessage)";
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
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 10);
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
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 11);
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

class OnchainWalletRequiredBarkException extends BarkException {
  final String errorMessage;
  OnchainWalletRequiredBarkException(String this.errorMessage);
  OnchainWalletRequiredBarkException._(String this.errorMessage);
  static LiftRetVal<OnchainWalletRequiredBarkException> read(Uint8List buf) {
    int new_offset = buf.offsetInBytes;
    final errorMessage_lifted = FfiConverterString.read(
      Uint8List.view(buf.buffer, new_offset),
    );
    final errorMessage = errorMessage_lifted.value;
    new_offset += errorMessage_lifted.bytesRead;
    return LiftRetVal(
      OnchainWalletRequiredBarkException._(errorMessage),
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
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, 12);
    int new_offset = buf.offsetInBytes + 4;
    new_offset += FfiConverterString.write(
      errorMessage,
      Uint8List.view(buf.buffer, new_offset),
    );
    return new_offset;
  }

  @override
  String toString() {
    return "OnchainWalletRequiredBarkException($errorMessage)";
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

abstract class OnchainWalletInterface {
  OnchainBalance balance();
  String newAddress();
  String send(String address, int amountSats, int feeRateSatPerVb);
  int sync_();
}

final _OnchainWalletFinalizer = Finalizer<Pointer<Void>>((ptr) {
  rustCall((status) => uniffi_bark_ffi_fn_free_onchainwallet(ptr, status));
});

class OnchainWallet implements OnchainWalletInterface {
  late final Pointer<Void> _ptr;
  OnchainWallet._(this._ptr) {
    _OnchainWalletFinalizer.attach(this, _ptr, detach: this);
  }
  OnchainWallet.custom(dynamic callbacks)
    : _ptr = rustCall(
        (status) => uniffi_bark_ffi_fn_constructor_onchainwallet_custom(
          FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks.lower(
            callbacks,
          ).address,
          status,
        ),
        barkExceptionErrorHandler,
      ) {
    _OnchainWalletFinalizer.attach(this, _ptr, detach: this);
  }
  OnchainWallet.default_(String mnemonic, Config config, String datadir)
    : _ptr = rustCall(
        (status) => uniffi_bark_ffi_fn_constructor_onchainwallet_default(
          FfiConverterString.lower(mnemonic),
          FfiConverterConfig.lower(config),
          FfiConverterString.lower(datadir),
          status,
        ),
        barkExceptionErrorHandler,
      ) {
    _OnchainWalletFinalizer.attach(this, _ptr, detach: this);
  }
  factory OnchainWallet.lift(Pointer<Void> ptr) {
    return OnchainWallet._(ptr);
  }
  static Pointer<Void> lower(OnchainWallet value) {
    return value.uniffiClonePointer();
  }

  Pointer<Void> uniffiClonePointer() {
    return rustCall(
      (status) => uniffi_bark_ffi_fn_clone_onchainwallet(_ptr, status),
    );
  }

  static int allocationSize(OnchainWallet value) {
    return 8;
  }

  static LiftRetVal<OnchainWallet> read(Uint8List buf) {
    final handle = buf.buffer.asByteData(buf.offsetInBytes).getInt64(0);
    final pointer = Pointer<Void>.fromAddress(handle);
    return LiftRetVal(OnchainWallet.lift(pointer), 8);
  }

  static int write(OnchainWallet value, Uint8List buf) {
    final handle = lower(value);
    buf.buffer.asByteData(buf.offsetInBytes).setInt64(0, handle.address);
    return 8;
  }

  void dispose() {
    _OnchainWalletFinalizer.detach(this);
    rustCall((status) => uniffi_bark_ffi_fn_free_onchainwallet(_ptr, status));
  }

  OnchainBalance balance() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_onchainwallet_balance(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterOnchainBalance.lift,
      barkExceptionErrorHandler,
    );
  }

  String newAddress() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_onchainwallet_new_address(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterString.lift,
      barkExceptionErrorHandler,
    );
  }

  String send(String address, int amountSats, int feeRateSatPerVb) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_onchainwallet_send(
        uniffiClonePointer(),
        FfiConverterString.lower(address),
        FfiConverterUInt64.lower(amountSats),
        FfiConverterUInt64.lower(feeRateSatPerVb),
        status,
      ),
      FfiConverterString.lift,
      barkExceptionErrorHandler,
    );
  }

  int sync_() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_onchainwallet_sync(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterUInt64.lift,
      barkExceptionErrorHandler,
    );
  }
}

abstract class WalletInterface {
  int? allExitsClaimableAtHeight();
  List<Vtxo> allVtxos();
  ArkInfo? arkInfo();
  Balance balance();
  PendingBoard boardAll(OnchainWallet onchainWallet);
  PendingBoard boardAmount(OnchainWallet onchainWallet, int amountSats);
  LightningInvoice bolt11Invoice(int amountSats);
  String broadcastTx(String txHex);
  void cancelAllPendingRounds();
  void cancelPendingRound(int roundId);
  String? checkLightningPayment(String paymentHash, bool wait);
  int claimableLightningReceiveBalanceSats();
  Config config();
  ExitClaimTransaction drainExits(
    List<String> vtxoIds,
    String address,
    int? feeRateSatPerVb,
  );
  ExitTransactionStatus? getExitStatus(
    String vtxoId,
    bool includeHistory,
    bool includeTransactions,
  );
  List<ExitVtxo> getExitVtxos();
  List<Vtxo> getExpiringVtxos(int thresholdBlocks);
  int? getFirstExpiringVtxoBlockheight();
  int? getNextRequiredRefreshBlockheight();
  Vtxo getVtxoById(String vtxoId);
  List<Vtxo> getVtxosToRefresh();
  bool hasPendingExits();
  List<Movement> history();
  LightningReceive? lightningReceiveStatus(String paymentHash);
  List<ExitVtxo> listClaimableExits();
  void maintenance();
  String? maintenanceRefresh();
  void maintenanceWithOnchain(OnchainWallet onchainWallet);
  int? maybeScheduleMaintenanceRefresh();
  String newAddress();
  AddressWithIndex newAddressWithIndex();
  OffboardResult offboardAll(String bitcoinAddress);
  String offboardVtxos(List<String> vtxoIds, String bitcoinAddress);
  LightningSend payLightningAddress(
    String lightningAddress,
    int amountSats,
    String? comment,
  );
  LightningSend payLightningInvoice(String invoice, int? amountSats);
  LightningSend payLightningOffer(String offer, int? amountSats);
  String peakAddress(int index);
  int pendingExitsTotalSats();
  List<LightningReceive> pendingLightningReceives();
  List<LightningSend> pendingLightningSends();
  List<RoundState> pendingRoundStates();
  List<ExitProgressStatus> progressExits(
    OnchainWallet onchainWallet,
    int? feeRateSatPerVb,
  );
  void progressPendingRounds();
  WalletProperties properties();
  void refreshServer();
  String? refreshVtxos(List<String> vtxoIds);
  String sendArkoorPayment(String arkAddress, int amountSats);
  String sendRoundOnchainPayment(String address, int amountSats);
  String signExitClaimInputs(String psbtBase64);
  List<Vtxo> spendableVtxos();
  void startExitForEntireWallet();
  void startExitForVtxos(List<String> vtxoIds);
  void sync_();
  void syncExits(OnchainWallet onchainWallet);
  void syncPendingBoards();
  void tryClaimAllLightningReceives(bool wait);
  void tryClaimLightningReceive(String paymentHash, bool wait);
  bool validateArkoorAddress(String address);
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
  Wallet.createWithOnchain(
    String mnemonic,
    Config config,
    String datadir,
    OnchainWallet onchainWallet,
    bool forceRescan,
  ) : _ptr = rustCall(
        (status) => uniffi_bark_ffi_fn_constructor_wallet_create_with_onchain(
          FfiConverterString.lower(mnemonic),
          FfiConverterConfig.lower(config),
          FfiConverterString.lower(datadir),
          OnchainWallet.lower(onchainWallet),
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
  Wallet.openWithOnchain(
    String mnemonic,
    Config config,
    String datadir,
    OnchainWallet onchainWallet,
  ) : _ptr = rustCall(
        (status) => uniffi_bark_ffi_fn_constructor_wallet_open_with_onchain(
          FfiConverterString.lower(mnemonic),
          FfiConverterConfig.lower(config),
          FfiConverterString.lower(datadir),
          OnchainWallet.lower(onchainWallet),
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

  int? allExitsClaimableAtHeight() {
    return rustCallWithLifter(
      (status) =>
          uniffi_bark_ffi_fn_method_wallet_all_exits_claimable_at_height(
            uniffiClonePointer(),
            status,
          ),
      FfiConverterOptionalUInt32.lift,
      barkExceptionErrorHandler,
    );
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

  PendingBoard boardAll(OnchainWallet onchainWallet) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_board_all(
        uniffiClonePointer(),
        OnchainWallet.lower(onchainWallet),
        status,
      ),
      FfiConverterPendingBoard.lift,
      barkExceptionErrorHandler,
    );
  }

  PendingBoard boardAmount(OnchainWallet onchainWallet, int amountSats) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_board_amount(
        uniffiClonePointer(),
        OnchainWallet.lower(onchainWallet),
        FfiConverterUInt64.lower(amountSats),
        status,
      ),
      FfiConverterPendingBoard.lift,
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

  String broadcastTx(String txHex) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_broadcast_tx(
        uniffiClonePointer(),
        FfiConverterString.lower(txHex),
        status,
      ),
      FfiConverterString.lift,
      barkExceptionErrorHandler,
    );
  }

  void cancelAllPendingRounds() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_cancel_all_pending_rounds(
        uniffiClonePointer(),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  void cancelPendingRound(int roundId) {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_cancel_pending_round(
        uniffiClonePointer(),
        FfiConverterUInt32.lower(roundId),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  String? checkLightningPayment(String paymentHash, bool wait) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_check_lightning_payment(
        uniffiClonePointer(),
        FfiConverterString.lower(paymentHash),
        FfiConverterBool.lower(wait),
        status,
      ),
      FfiConverterOptionalString.lift,
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

  ExitClaimTransaction drainExits(
    List<String> vtxoIds,
    String address,
    int? feeRateSatPerVb,
  ) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_drain_exits(
        uniffiClonePointer(),
        FfiConverterSequenceString.lower(vtxoIds),
        FfiConverterString.lower(address),
        FfiConverterOptionalUInt64.lower(feeRateSatPerVb),
        status,
      ),
      FfiConverterExitClaimTransaction.lift,
      barkExceptionErrorHandler,
    );
  }

  ExitTransactionStatus? getExitStatus(
    String vtxoId,
    bool includeHistory,
    bool includeTransactions,
  ) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_get_exit_status(
        uniffiClonePointer(),
        FfiConverterString.lower(vtxoId),
        FfiConverterBool.lower(includeHistory),
        FfiConverterBool.lower(includeTransactions),
        status,
      ),
      FfiConverterOptionalExitTransactionStatus.lift,
      barkExceptionErrorHandler,
    );
  }

  List<ExitVtxo> getExitVtxos() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_get_exit_vtxos(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceExitVtxo.lift,
      barkExceptionErrorHandler,
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

  int? getFirstExpiringVtxoBlockheight() {
    return rustCallWithLifter(
      (status) =>
          uniffi_bark_ffi_fn_method_wallet_get_first_expiring_vtxo_blockheight(
            uniffiClonePointer(),
            status,
          ),
      FfiConverterOptionalUInt32.lift,
      barkExceptionErrorHandler,
    );
  }

  int? getNextRequiredRefreshBlockheight() {
    return rustCallWithLifter(
      (status) =>
          uniffi_bark_ffi_fn_method_wallet_get_next_required_refresh_blockheight(
            uniffiClonePointer(),
            status,
          ),
      FfiConverterOptionalUInt32.lift,
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

  bool hasPendingExits() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_has_pending_exits(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterBool.lift,
      barkExceptionErrorHandler,
    );
  }

  List<Movement> history() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_history(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceMovement.lift,
      barkExceptionErrorHandler,
    );
  }

  LightningReceive? lightningReceiveStatus(String paymentHash) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_lightning_receive_status(
        uniffiClonePointer(),
        FfiConverterString.lower(paymentHash),
        status,
      ),
      FfiConverterOptionalLightningReceive.lift,
      barkExceptionErrorHandler,
    );
  }

  List<ExitVtxo> listClaimableExits() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_list_claimable_exits(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceExitVtxo.lift,
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

  void maintenanceWithOnchain(OnchainWallet onchainWallet) {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_maintenance_with_onchain(
        uniffiClonePointer(),
        OnchainWallet.lower(onchainWallet),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  int? maybeScheduleMaintenanceRefresh() {
    return rustCallWithLifter(
      (status) =>
          uniffi_bark_ffi_fn_method_wallet_maybe_schedule_maintenance_refresh(
            uniffiClonePointer(),
            status,
          ),
      FfiConverterOptionalUInt32.lift,
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

  LightningSend payLightningAddress(
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
      FfiConverterLightningSend.lift,
      barkExceptionErrorHandler,
    );
  }

  LightningSend payLightningInvoice(String invoice, int? amountSats) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pay_lightning_invoice(
        uniffiClonePointer(),
        FfiConverterString.lower(invoice),
        FfiConverterOptionalUInt64.lower(amountSats),
        status,
      ),
      FfiConverterLightningSend.lift,
      barkExceptionErrorHandler,
    );
  }

  LightningSend payLightningOffer(String offer, int? amountSats) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pay_lightning_offer(
        uniffiClonePointer(),
        FfiConverterString.lower(offer),
        FfiConverterOptionalUInt64.lower(amountSats),
        status,
      ),
      FfiConverterLightningSend.lift,
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

  int pendingExitsTotalSats() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pending_exits_total_sats(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterUInt64.lift,
      barkExceptionErrorHandler,
    );
  }

  List<LightningReceive> pendingLightningReceives() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pending_lightning_receives(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceLightningReceive.lift,
      barkExceptionErrorHandler,
    );
  }

  List<LightningSend> pendingLightningSends() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pending_lightning_sends(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceLightningSend.lift,
      barkExceptionErrorHandler,
    );
  }

  List<RoundState> pendingRoundStates() {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_pending_round_states(
        uniffiClonePointer(),
        status,
      ),
      FfiConverterSequenceRoundState.lift,
      barkExceptionErrorHandler,
    );
  }

  List<ExitProgressStatus> progressExits(
    OnchainWallet onchainWallet,
    int? feeRateSatPerVb,
  ) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_progress_exits(
        uniffiClonePointer(),
        OnchainWallet.lower(onchainWallet),
        FfiConverterOptionalUInt64.lower(feeRateSatPerVb),
        status,
      ),
      FfiConverterSequenceExitProgressStatus.lift,
      barkExceptionErrorHandler,
    );
  }

  void progressPendingRounds() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_progress_pending_rounds(
        uniffiClonePointer(),
        status,
      );
    }, barkExceptionErrorHandler);
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

  void refreshServer() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_refresh_server(
        uniffiClonePointer(),
        status,
      );
    }, barkExceptionErrorHandler);
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

  String signExitClaimInputs(String psbtBase64) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_sign_exit_claim_inputs(
        uniffiClonePointer(),
        FfiConverterString.lower(psbtBase64),
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

  void startExitForEntireWallet() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_start_exit_for_entire_wallet(
        uniffiClonePointer(),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  void startExitForVtxos(List<String> vtxoIds) {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_start_exit_for_vtxos(
        uniffiClonePointer(),
        FfiConverterSequenceString.lower(vtxoIds),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  void sync_() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_sync(uniffiClonePointer(), status);
    }, barkExceptionErrorHandler);
  }

  void syncExits(OnchainWallet onchainWallet) {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_sync_exits(
        uniffiClonePointer(),
        OnchainWallet.lower(onchainWallet),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  void syncPendingBoards() {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_sync_pending_boards(
        uniffiClonePointer(),
        status,
      );
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

  void tryClaimLightningReceive(String paymentHash, bool wait) {
    return rustCall((status) {
      uniffi_bark_ffi_fn_method_wallet_try_claim_lightning_receive(
        uniffiClonePointer(),
        FfiConverterString.lower(paymentHash),
        FfiConverterBool.lower(wait),
        status,
      );
    }, barkExceptionErrorHandler);
  }

  bool validateArkoorAddress(String address) {
    return rustCallWithLifter(
      (status) => uniffi_bark_ffi_fn_method_wallet_validate_arkoor_address(
        uniffiClonePointer(),
        FfiConverterString.lower(address),
        status,
      ),
      FfiConverterBool.lift,
      barkExceptionErrorHandler,
    );
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

class FfiConverterOptionalLightningReceive {
  static LightningReceive? lift(RustBuffer buf) {
    return FfiConverterOptionalLightningReceive.read(buf.asUint8List()).value;
  }

  static LiftRetVal<LightningReceive?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterLightningReceive.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<LightningReceive?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([LightningReceive? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterLightningReceive.allocationSize(value) + 1;
  }

  static RustBuffer lower(LightningReceive? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalLightningReceive.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalLightningReceive.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(LightningReceive? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterLightningReceive.write(
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

class FfiConverterSequenceExitVtxo {
  static List<ExitVtxo> lift(RustBuffer buf) {
    return FfiConverterSequenceExitVtxo.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<ExitVtxo>> read(Uint8List buf) {
    List<ExitVtxo> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterExitVtxo.read(Uint8List.view(buf.buffer, offset));
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<ExitVtxo> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterExitVtxo.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<ExitVtxo> value) {
    return value
            .map((l) => FfiConverterExitVtxo.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<ExitVtxo> value) {
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

class FfiConverterOptionalExitTransactionStatus {
  static ExitTransactionStatus? lift(RustBuffer buf) {
    return FfiConverterOptionalExitTransactionStatus.read(
      buf.asUint8List(),
    ).value;
  }

  static LiftRetVal<ExitTransactionStatus?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterExitTransactionStatus.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<ExitTransactionStatus?>(
      result.value,
      result.bytesRead + 1,
    );
  }

  static int allocationSize([ExitTransactionStatus? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterExitTransactionStatus.allocationSize(value) + 1;
  }

  static RustBuffer lower(ExitTransactionStatus? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalExitTransactionStatus.allocationSize(
      value,
    );
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalExitTransactionStatus.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(ExitTransactionStatus? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterExitTransactionStatus.write(
          value,
          Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
        ) +
        1;
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

class FfiConverterOptionalBlockRef {
  static BlockRef? lift(RustBuffer buf) {
    return FfiConverterOptionalBlockRef.read(buf.asUint8List()).value;
  }

  static LiftRetVal<BlockRef?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterBlockRef.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<BlockRef?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([BlockRef? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterBlockRef.allocationSize(value) + 1;
  }

  static RustBuffer lower(BlockRef? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalBlockRef.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalBlockRef.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(BlockRef? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterBlockRef.write(
          value,
          Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
        ) +
        1;
  }
}

abstract class CustomOnchainWalletCallbacks {
  int getBalance();
  String prepareTx(List<Destination> destinations, int feeRateSatPerVb);
  String prepareDrainTx(String address, int feeRateSatPerVb);
  String finishTx(String psbtBase64);
  String? getWalletTx(String txid);
  BlockRef? getWalletTxConfirmedBlock(String txid);
  String? getSpendingTx(OutPoint outpoint);
  String makeSignedP2aCpfp(CpfpParams params);
  void storeSignedP2aCpfp(String txHex);
}

class FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks {
  static final _handleMap = UniffiHandleMap<CustomOnchainWalletCallbacks>();
  static bool _vtableInitialized = false;
  static CustomOnchainWalletCallbacks lift(Pointer<Void> handle) {
    return _handleMap.get(handle.address);
  }

  static Pointer<Void> lower(CustomOnchainWalletCallbacks value) {
    _ensureVTableInitialized();
    final handle = _handleMap.insert(value);
    return Pointer<Void>.fromAddress(handle);
  }

  static void _ensureVTableInitialized() {
    if (!_vtableInitialized) {
      initCustomOnchainWalletCallbacksVTable();
      _vtableInitialized = true;
    }
  }

  static LiftRetVal<CustomOnchainWalletCallbacks> read(Uint8List buf) {
    final handle = buf.buffer.asByteData(buf.offsetInBytes).getInt64(0);
    final pointer = Pointer<Void>.fromAddress(handle);
    return LiftRetVal(lift(pointer), 8);
  }

  static int write(CustomOnchainWalletCallbacks value, Uint8List buf) {
    final handle = lower(value);
    buf.buffer.asByteData(buf.offsetInBytes).setInt64(0, handle.address);
    return 8;
  }

  static int allocationSize(CustomOnchainWalletCallbacks value) {
    return 8;
  }
}

typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod0 =
    Void Function(Uint64, Pointer<Uint64>, Pointer<RustCallStatus>);
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod0Dart =
    void Function(int, Pointer<Uint64>, Pointer<RustCallStatus>);
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod1 =
    Void Function(
      Uint64,
      RustBuffer,
      Uint64,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod1Dart =
    void Function(
      int,
      RustBuffer,
      int,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod2 =
    Void Function(
      Uint64,
      RustBuffer,
      Uint64,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod2Dart =
    void Function(
      int,
      RustBuffer,
      int,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod3 =
    Void Function(
      Uint64,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod3Dart =
    void Function(
      int,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod4 =
    Void Function(
      Uint64,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod4Dart =
    void Function(
      int,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod5 =
    Void Function(
      Uint64,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod5Dart =
    void Function(
      int,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod6 =
    Void Function(
      Uint64,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod6Dart =
    void Function(
      int,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod7 =
    Void Function(
      Uint64,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod7Dart =
    void Function(
      int,
      RustBuffer,
      Pointer<RustBuffer>,
      Pointer<RustCallStatus>,
    );
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod8 =
    Void Function(Uint64, RustBuffer, Pointer<Void>, Pointer<RustCallStatus>);
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod8Dart =
    void Function(int, RustBuffer, Pointer<Void>, Pointer<RustCallStatus>);
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksFree =
    Void Function(Uint64);
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksFreeDart =
    void Function(int);
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksClone =
    Uint64 Function(Uint64);
typedef UniffiCallbackInterfaceCustomOnchainWalletCallbacksCloneDart =
    int Function(int);

final class UniffiVTableCallbackInterfaceCustomOnchainWalletCallbacks
    extends Struct {
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksFree>
  >
  uniffiFree;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksClone>
  >
  uniffiClone;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod0>
  >
  getBalance;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod1>
  >
  prepareTx;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod2>
  >
  prepareDrainTx;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod3>
  >
  finishTx;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod4>
  >
  getWalletTx;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod5>
  >
  getWalletTxConfirmedBlock;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod6>
  >
  getSpendingTx;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod7>
  >
  makeSignedP2aCpfp;
  external Pointer<
    NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod8>
  >
  storeSignedP2aCpfp;
}

void customOnchainWalletCallbacksGetBalance(
  int uniffiHandle,
  Pointer<Uint64> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final result = obj.getBalance();
    outReturn.value = FfiConverterUInt64.lower(result);
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod0>
>
customOnchainWalletCallbacksGetBalancePointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod0
    >(customOnchainWalletCallbacksGetBalance);
void customOnchainWalletCallbacksPrepareTx(
  int uniffiHandle,
  RustBuffer destinations,
  int feeRateSatPerVb,
  Pointer<RustBuffer> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterSequenceDestination.lift(destinations);
    final arg1 = FfiConverterUInt64.lift(feeRateSatPerVb);
    final result = obj.prepareTx(arg0, arg1);
    outReturn.ref = FfiConverterString.lower(result);
    status.code = CALL_SUCCESS;
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod1>
>
customOnchainWalletCallbacksPrepareTxPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod1
    >(customOnchainWalletCallbacksPrepareTx);
void customOnchainWalletCallbacksPrepareDrainTx(
  int uniffiHandle,
  RustBuffer address,
  int feeRateSatPerVb,
  Pointer<RustBuffer> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterString.lift(address);
    final arg1 = FfiConverterUInt64.lift(feeRateSatPerVb);
    final result = obj.prepareDrainTx(arg0, arg1);
    outReturn.ref = FfiConverterString.lower(result);
    status.code = CALL_SUCCESS;
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod2>
>
customOnchainWalletCallbacksPrepareDrainTxPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod2
    >(customOnchainWalletCallbacksPrepareDrainTx);
void customOnchainWalletCallbacksFinishTx(
  int uniffiHandle,
  RustBuffer psbtBase64,
  Pointer<RustBuffer> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterString.lift(psbtBase64);
    final result = obj.finishTx(arg0);
    outReturn.ref = FfiConverterString.lower(result);
    status.code = CALL_SUCCESS;
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod3>
>
customOnchainWalletCallbacksFinishTxPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod3
    >(customOnchainWalletCallbacksFinishTx);
void customOnchainWalletCallbacksGetWalletTx(
  int uniffiHandle,
  RustBuffer txid,
  Pointer<RustBuffer> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterString.lift(txid);
    final result = obj.getWalletTx(arg0);
    if (result == null) {
      outReturn.ref = toRustBuffer(Uint8List.fromList([0]));
    } else {
      final lowered = FfiConverterOptionalString.lower(result);
      outReturn.ref = toRustBuffer(lowered.asUint8List());
    }
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod4>
>
customOnchainWalletCallbacksGetWalletTxPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod4
    >(customOnchainWalletCallbacksGetWalletTx);
void customOnchainWalletCallbacksGetWalletTxConfirmedBlock(
  int uniffiHandle,
  RustBuffer txid,
  Pointer<RustBuffer> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterString.lift(txid);
    final result = obj.getWalletTxConfirmedBlock(arg0);
    if (result == null) {
      outReturn.ref = toRustBuffer(Uint8List.fromList([0]));
    } else {
      final lowered = FfiConverterOptionalBlockRef.lower(result);
      final buffer = Uint8List(1 + lowered.len);
      buffer[0] = 1;
      buffer.setAll(1, lowered.asUint8List());
      outReturn.ref = toRustBuffer(buffer);
    }
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod5>
>
customOnchainWalletCallbacksGetWalletTxConfirmedBlockPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod5
    >(customOnchainWalletCallbacksGetWalletTxConfirmedBlock);
void customOnchainWalletCallbacksGetSpendingTx(
  int uniffiHandle,
  RustBuffer outpoint,
  Pointer<RustBuffer> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterOutPoint.lift(outpoint);
    final result = obj.getSpendingTx(arg0);
    if (result == null) {
      outReturn.ref = toRustBuffer(Uint8List.fromList([0]));
    } else {
      final lowered = FfiConverterOptionalString.lower(result);
      outReturn.ref = toRustBuffer(lowered.asUint8List());
    }
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod6>
>
customOnchainWalletCallbacksGetSpendingTxPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod6
    >(customOnchainWalletCallbacksGetSpendingTx);
void customOnchainWalletCallbacksMakeSignedP2aCpfp(
  int uniffiHandle,
  RustBuffer params,
  Pointer<RustBuffer> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterCpfpParams.lift(params);
    final result = obj.makeSignedP2aCpfp(arg0);
    outReturn.ref = FfiConverterString.lower(result);
    status.code = CALL_SUCCESS;
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod7>
>
customOnchainWalletCallbacksMakeSignedP2aCpfpPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod7
    >(customOnchainWalletCallbacksMakeSignedP2aCpfp);
void customOnchainWalletCallbacksStoreSignedP2aCpfp(
  int uniffiHandle,
  RustBuffer txHex,
  Pointer<Void> outReturn,
  Pointer<RustCallStatus> callStatus,
) {
  final status = callStatus.ref;
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(uniffiHandle);
    final arg0 = FfiConverterString.lift(txHex);
    obj.storeSignedP2aCpfp(arg0);
    status.code = CALL_SUCCESS;
  } catch (e) {
    status.code = CALL_UNEXPECTED_ERROR;
    status.errorBuf = FfiConverterString.lower(e.toString());
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod8>
>
customOnchainWalletCallbacksStoreSignedP2aCpfpPointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksMethod8
    >(customOnchainWalletCallbacksStoreSignedP2aCpfp);
void customOnchainWalletCallbacksFreeCallback(int handle) {
  try {
    FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks._handleMap.remove(
      handle,
    );
  } catch (e) {}
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksFree>
>
customOnchainWalletCallbacksFreePointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksFree
    >(customOnchainWalletCallbacksFreeCallback);
int customOnchainWalletCallbacksCloneCallback(int handle) {
  try {
    final obj = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .get(handle);
    final newHandle = FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
        ._handleMap
        .insert(obj);
    return newHandle;
  } catch (e) {
    return 0;
  }
}

final Pointer<
  NativeFunction<UniffiCallbackInterfaceCustomOnchainWalletCallbacksClone>
>
customOnchainWalletCallbacksClonePointer =
    Pointer.fromFunction<
      UniffiCallbackInterfaceCustomOnchainWalletCallbacksClone
    >(customOnchainWalletCallbacksCloneCallback, 0);
late final Pointer<UniffiVTableCallbackInterfaceCustomOnchainWalletCallbacks>
customOnchainWalletCallbacksVTable;
void initCustomOnchainWalletCallbacksVTable() {
  if (FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks
      ._vtableInitialized) {
    return;
  }
  customOnchainWalletCallbacksVTable =
      calloc<UniffiVTableCallbackInterfaceCustomOnchainWalletCallbacks>();
  customOnchainWalletCallbacksVTable.ref.uniffiFree =
      customOnchainWalletCallbacksFreePointer;
  customOnchainWalletCallbacksVTable.ref.uniffiClone =
      customOnchainWalletCallbacksClonePointer;
  customOnchainWalletCallbacksVTable.ref.getBalance =
      customOnchainWalletCallbacksGetBalancePointer;
  customOnchainWalletCallbacksVTable.ref.prepareTx =
      customOnchainWalletCallbacksPrepareTxPointer;
  customOnchainWalletCallbacksVTable.ref.prepareDrainTx =
      customOnchainWalletCallbacksPrepareDrainTxPointer;
  customOnchainWalletCallbacksVTable.ref.finishTx =
      customOnchainWalletCallbacksFinishTxPointer;
  customOnchainWalletCallbacksVTable.ref.getWalletTx =
      customOnchainWalletCallbacksGetWalletTxPointer;
  customOnchainWalletCallbacksVTable.ref.getWalletTxConfirmedBlock =
      customOnchainWalletCallbacksGetWalletTxConfirmedBlockPointer;
  customOnchainWalletCallbacksVTable.ref.getSpendingTx =
      customOnchainWalletCallbacksGetSpendingTxPointer;
  customOnchainWalletCallbacksVTable.ref.makeSignedP2aCpfp =
      customOnchainWalletCallbacksMakeSignedP2aCpfpPointer;
  customOnchainWalletCallbacksVTable.ref.storeSignedP2aCpfp =
      customOnchainWalletCallbacksStoreSignedP2aCpfpPointer;
  rustCall((status) {
    uniffi_bark_ffi_fn_init_callback_vtable_customonchainwalletcallbacks(
      customOnchainWalletCallbacksVTable,
    );
    checkCallStatus(NullRustCallStatusErrorHandler(), status);
  });
  FfiConverterCallbackInterfaceCustomOnchainWalletCallbacks._vtableInitialized =
      true;
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

class FfiConverterSequenceLightningReceive {
  static List<LightningReceive> lift(RustBuffer buf) {
    return FfiConverterSequenceLightningReceive.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<LightningReceive>> read(Uint8List buf) {
    List<LightningReceive> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterLightningReceive.read(
        Uint8List.view(buf.buffer, offset),
      );
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<LightningReceive> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterLightningReceive.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<LightningReceive> value) {
    return value
            .map((l) => FfiConverterLightningReceive.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<LightningReceive> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
  }
}

class FfiConverterSequenceExitProgressStatus {
  static List<ExitProgressStatus> lift(RustBuffer buf) {
    return FfiConverterSequenceExitProgressStatus.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<ExitProgressStatus>> read(Uint8List buf) {
    List<ExitProgressStatus> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterExitProgressStatus.read(
        Uint8List.view(buf.buffer, offset),
      );
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<ExitProgressStatus> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterExitProgressStatus.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<ExitProgressStatus> value) {
    return value
            .map((l) => FfiConverterExitProgressStatus.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<ExitProgressStatus> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
  }
}

class FfiConverterOptionalSequenceString {
  static List<String>? lift(RustBuffer buf) {
    return FfiConverterOptionalSequenceString.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<String>?> read(Uint8List buf) {
    if (ByteData.view(buf.buffer, buf.offsetInBytes).getInt8(0) == 0) {
      return LiftRetVal(null, 1);
    }
    final result = FfiConverterSequenceString.read(
      Uint8List.view(buf.buffer, buf.offsetInBytes + 1),
    );
    return LiftRetVal<List<String>?>(result.value, result.bytesRead + 1);
  }

  static int allocationSize([List<String>? value]) {
    if (value == null) {
      return 1;
    }
    return FfiConverterSequenceString.allocationSize(value) + 1;
  }

  static RustBuffer lower(List<String>? value) {
    if (value == null) {
      return toRustBuffer(Uint8List.fromList([0]));
    }
    final length = FfiConverterOptionalSequenceString.allocationSize(value);
    final Pointer<Uint8> frameData = calloc<Uint8>(length);
    final buf = frameData.asTypedList(length);
    FfiConverterOptionalSequenceString.write(value, buf);
    final bytes = calloc<ForeignBytes>();
    bytes.ref.len = length;
    bytes.ref.data = frameData;
    return RustBuffer.fromBytes(bytes.ref);
  }

  static int write(List<String>? value, Uint8List buf) {
    if (value == null) {
      buf[0] = 0;
      return 1;
    }
    buf[0] = 1;
    return FfiConverterSequenceString.write(
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

class FfiConverterSequenceLightningSend {
  static List<LightningSend> lift(RustBuffer buf) {
    return FfiConverterSequenceLightningSend.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<LightningSend>> read(Uint8List buf) {
    List<LightningSend> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterLightningSend.read(
        Uint8List.view(buf.buffer, offset),
      );
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<LightningSend> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterLightningSend.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<LightningSend> value) {
    return value
            .map((l) => FfiConverterLightningSend.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<LightningSend> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
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

class FfiConverterSequenceRoundState {
  static List<RoundState> lift(RustBuffer buf) {
    return FfiConverterSequenceRoundState.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<RoundState>> read(Uint8List buf) {
    List<RoundState> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterRoundState.read(
        Uint8List.view(buf.buffer, offset),
      );
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<RoundState> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterRoundState.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<RoundState> value) {
    return value
            .map((l) => FfiConverterRoundState.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<RoundState> value) {
    final buf = Uint8List(allocationSize(value));
    write(value, buf);
    return toRustBuffer(buf);
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

class FfiConverterSequenceDestination {
  static List<Destination> lift(RustBuffer buf) {
    return FfiConverterSequenceDestination.read(buf.asUint8List()).value;
  }

  static LiftRetVal<List<Destination>> read(Uint8List buf) {
    List<Destination> res = [];
    final length = buf.buffer.asByteData(buf.offsetInBytes).getInt32(0);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < length; i++) {
      final ret = FfiConverterDestination.read(
        Uint8List.view(buf.buffer, offset),
      );
      offset += ret.bytesRead;
      res.add(ret.value);
    }
    return LiftRetVal(res, offset - buf.offsetInBytes);
  }

  static int write(List<Destination> value, Uint8List buf) {
    buf.buffer.asByteData(buf.offsetInBytes).setInt32(0, value.length);
    int offset = buf.offsetInBytes + 4;
    for (var i = 0; i < value.length; i++) {
      offset += FfiConverterDestination.write(
        value[i],
        Uint8List.view(buf.buffer, offset),
      );
    }
    return offset - buf.offsetInBytes;
  }

  static int allocationSize(List<Destination> value) {
    return value
            .map((l) => FfiConverterDestination.allocationSize(l))
            .fold(0, (a, b) => a + b) +
        4;
  }

  static RustBuffer lower(List<Destination> value) {
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
String extractTxFromPsbt(String psbtBase64) {
  return rustCallWithLifter(
    (status) => uniffi_bark_ffi_fn_func_extract_tx_from_psbt(
      FfiConverterString.lower(psbtBase64),
      status,
    ),
    FfiConverterString.lift,
    barkExceptionErrorHandler,
  );
}

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
external Pointer<Void> uniffi_bark_ffi_fn_clone_onchainwallet(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_free_onchainwallet(
  Pointer<Void> handle,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Pointer<Void> Function(Uint64, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external Pointer<Void> uniffi_bark_ffi_fn_constructor_onchainwallet_custom(
  int callbacks,
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
external Pointer<Void> uniffi_bark_ffi_fn_constructor_onchainwallet_default(
  RustBuffer mnemonic,
  RustBuffer config,
  RustBuffer datadir,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_onchainwallet_balance(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_onchainwallet_new_address(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    Uint64,
    Uint64,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_onchainwallet_send(
  Pointer<Void> ptr,
  RustBuffer address,
  int amount_sats,
  int fee_rate_sat_per_vb,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Uint64 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int uniffi_bark_ffi_fn_method_onchainwallet_sync(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

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
    Pointer<Void>,
    Int8,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external Pointer<Void>
uniffi_bark_ffi_fn_constructor_wallet_create_with_onchain(
  RustBuffer mnemonic,
  RustBuffer config,
  RustBuffer datadir,
  Pointer<Void> onchain_wallet,
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

@Native<
  Pointer<Void> Function(
    RustBuffer,
    RustBuffer,
    RustBuffer,
    Pointer<Void>,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external Pointer<Void> uniffi_bark_ffi_fn_constructor_wallet_open_with_onchain(
  RustBuffer mnemonic,
  RustBuffer config,
  RustBuffer datadir,
  Pointer<Void> onchain_wallet,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer
uniffi_bark_ffi_fn_method_wallet_all_exits_claimable_at_height(
  Pointer<Void> ptr,
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

@Native<
  RustBuffer Function(Pointer<Void>, Pointer<Void>, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_board_all(
  Pointer<Void> ptr,
  Pointer<Void> onchain_wallet,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    Pointer<Void>,
    Uint64,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_board_amount(
  Pointer<Void> ptr,
  Pointer<Void> onchain_wallet,
  int amount_sats,
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

@Native<
  RustBuffer Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_broadcast_tx(
  Pointer<Void> ptr,
  RustBuffer tx_hex,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_cancel_all_pending_rounds(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Uint32, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_cancel_pending_round(
  Pointer<Void> ptr,
  int round_id,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(Pointer<Void>, RustBuffer, Int8, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_check_lightning_payment(
  Pointer<Void> ptr,
  RustBuffer payment_hash,
  int wait,
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

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    RustBuffer,
    RustBuffer,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_drain_exits(
  Pointer<Void> ptr,
  RustBuffer vtxo_ids,
  RustBuffer address,
  RustBuffer fee_rate_sat_per_vb,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    Int8,
    Int8,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_get_exit_status(
  Pointer<Void> ptr,
  RustBuffer vtxo_id,
  int include_history,
  int include_transactions,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_get_exit_vtxos(
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

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer
uniffi_bark_ffi_fn_method_wallet_get_first_expiring_vtxo_blockheight(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer
uniffi_bark_ffi_fn_method_wallet_get_next_required_refresh_blockheight(
  Pointer<Void> ptr,
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

@Native<Int8 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int uniffi_bark_ffi_fn_method_wallet_has_pending_exits(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_history(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_lightning_receive_status(
  Pointer<Void> ptr,
  RustBuffer payment_hash,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_list_claimable_exits(
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

@Native<Void Function(Pointer<Void>, Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_maintenance_with_onchain(
  Pointer<Void> ptr,
  Pointer<Void> onchain_wallet,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer
uniffi_bark_ffi_fn_method_wallet_maybe_schedule_maintenance_refresh(
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

@Native<
  RustBuffer Function(
    Pointer<Void>,
    RustBuffer,
    RustBuffer,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_pay_lightning_offer(
  Pointer<Void> ptr,
  RustBuffer offer,
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

@Native<Uint64 Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int uniffi_bark_ffi_fn_method_wallet_pending_exits_total_sats(
  Pointer<Void> ptr,
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
external RustBuffer uniffi_bark_ffi_fn_method_wallet_pending_round_states(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  RustBuffer Function(
    Pointer<Void>,
    Pointer<Void>,
    RustBuffer,
    Pointer<RustCallStatus>,
  )
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_progress_exits(
  Pointer<Void> ptr,
  Pointer<Void> onchain_wallet,
  RustBuffer fee_rate_sat_per_vb,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_progress_pending_rounds(
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

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_refresh_server(
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

@Native<
  RustBuffer Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_sign_exit_claim_inputs(
  Pointer<Void> ptr,
  RustBuffer psbt_base64,
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
external void uniffi_bark_ffi_fn_method_wallet_start_exit_for_entire_wallet(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_start_exit_for_vtxos(
  Pointer<Void> ptr,
  RustBuffer vtxo_ids,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_sync(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_sync_exits(
  Pointer<Void> ptr,
  Pointer<Void> onchain_wallet,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Void Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external void uniffi_bark_ffi_fn_method_wallet_sync_pending_boards(
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

@Native<
  Void Function(Pointer<Void>, RustBuffer, Int8, Pointer<RustCallStatus>)
>(assetId: _uniffiAssetId)
external void uniffi_bark_ffi_fn_method_wallet_try_claim_lightning_receive(
  Pointer<Void> ptr,
  RustBuffer payment_hash,
  int wait,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<Int8 Function(Pointer<Void>, RustBuffer, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external int uniffi_bark_ffi_fn_method_wallet_validate_arkoor_address(
  Pointer<Void> ptr,
  RustBuffer address,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<RustBuffer Function(Pointer<Void>, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_method_wallet_vtxos(
  Pointer<Void> ptr,
  Pointer<RustCallStatus> uniffiStatus,
);

@Native<
  Void Function(
    Pointer<UniffiVTableCallbackInterfaceCustomOnchainWalletCallbacks>,
  )
>(assetId: _uniffiAssetId)
external void
uniffi_bark_ffi_fn_init_callback_vtable_customonchainwalletcallbacks(
  Pointer<UniffiVTableCallbackInterfaceCustomOnchainWalletCallbacks> vtable,
);

@Native<RustBuffer Function(RustBuffer, Pointer<RustCallStatus>)>(
  assetId: _uniffiAssetId,
)
external RustBuffer uniffi_bark_ffi_fn_func_extract_tx_from_psbt(
  RustBuffer psbt_base64,
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
external int uniffi_bark_ffi_checksum_func_extract_tx_from_psbt();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_func_generate_mnemonic();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_func_validate_ark_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_func_validate_mnemonic();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_onchainwallet_balance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_onchainwallet_new_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_onchainwallet_send();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_onchainwallet_sync();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_all_exits_claimable_at_height();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_all_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_ark_info();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_balance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_board_all();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_board_amount();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_bolt11_invoice();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_broadcast_tx();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_cancel_all_pending_rounds();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_cancel_pending_round();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_check_lightning_payment();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_claimable_lightning_receive_balance_sats();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_config();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_drain_exits();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_exit_status();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_exit_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_expiring_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_get_first_expiring_vtxo_blockheight();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_get_next_required_refresh_blockheight();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_vtxo_by_id();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_get_vtxos_to_refresh();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_has_pending_exits();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_history();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_lightning_receive_status();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_list_claimable_exits();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_maintenance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_maintenance_refresh();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_maintenance_with_onchain();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_maybe_schedule_maintenance_refresh();

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
external int uniffi_bark_ffi_checksum_method_wallet_pay_lightning_offer();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_peak_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pending_exits_total_sats();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_pending_lightning_receives();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pending_lightning_sends();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_pending_round_states();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_progress_exits();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_progress_pending_rounds();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_properties();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_refresh_server();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_refresh_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_send_arkoor_payment();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_send_round_onchain_payment();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_sign_exit_claim_inputs();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_spendable_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_start_exit_for_entire_wallet();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_start_exit_for_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_sync();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_sync_exits();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_sync_pending_boards();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_try_claim_all_lightning_receives();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_wallet_try_claim_lightning_receive();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_validate_arkoor_address();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_method_wallet_vtxos();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_onchainwallet_custom();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_onchainwallet_default();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_wallet_create();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_wallet_create_with_onchain();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_wallet_open();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int uniffi_bark_ffi_checksum_constructor_wallet_open_with_onchain();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_balance();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_prepare_tx();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_prepare_drain_tx();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_finish_tx();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_wallet_tx();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_wallet_tx_confirmed_block();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_spending_tx();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_make_signed_p2a_cpfp();

@Native<Uint16 Function()>(assetId: _uniffiAssetId)
external int
uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_store_signed_p2a_cpfp();

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
  if (uniffi_bark_ffi_checksum_func_extract_tx_from_psbt() != 6799) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_func_generate_mnemonic() != 49933) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_func_validate_ark_address() != 49932) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_func_validate_mnemonic() != 2707) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_onchainwallet_balance() != 22016) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_onchainwallet_new_address() != 41946) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_onchainwallet_send() != 33716) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_onchainwallet_sync() != 30454) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_all_exits_claimable_at_height() !=
      24892) {
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
  if (uniffi_bark_ffi_checksum_method_wallet_board_all() != 41101) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_board_amount() != 42163) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_bolt11_invoice() != 64551) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_broadcast_tx() != 32920) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_cancel_all_pending_rounds() !=
      8095) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_cancel_pending_round() != 3417) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_check_lightning_payment() !=
      13160) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_claimable_lightning_receive_balance_sats() !=
      64974) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_config() != 57616) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_drain_exits() != 16953) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_exit_status() != 27512) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_exit_vtxos() != 24545) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_expiring_vtxos() != 19482) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_first_expiring_vtxo_blockheight() !=
      41108) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_next_required_refresh_blockheight() !=
      29762) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_vtxo_by_id() != 41126) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_get_vtxos_to_refresh() != 55019) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_has_pending_exits() != 40981) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_history() != 21880) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_lightning_receive_status() !=
      26106) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_list_claimable_exits() != 62145) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_maintenance() != 9626) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_maintenance_refresh() != 29994) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_maintenance_with_onchain() !=
      335) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_maybe_schedule_maintenance_refresh() !=
      32397) {
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
  if (uniffi_bark_ffi_checksum_method_wallet_pay_lightning_address() != 39952) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pay_lightning_invoice() != 31286) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pay_lightning_offer() != 37035) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_peak_address() != 23469) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pending_exits_total_sats() !=
      47419) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pending_lightning_receives() !=
      14491) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pending_lightning_sends() !=
      51186) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_pending_round_states() != 19530) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_progress_exits() != 43190) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_progress_pending_rounds() !=
      17062) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_properties() != 34715) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_refresh_server() != 705) {
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
  if (uniffi_bark_ffi_checksum_method_wallet_sign_exit_claim_inputs() !=
      31570) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_spendable_vtxos() != 48976) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_start_exit_for_entire_wallet() !=
      50435) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_start_exit_for_vtxos() != 12580) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_sync() != 3312) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_sync_exits() != 5469) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_sync_pending_boards() != 8863) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_try_claim_all_lightning_receives() !=
      53132) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_try_claim_lightning_receive() !=
      60644) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_validate_arkoor_address() !=
      16628) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_wallet_vtxos() != 16778) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_onchainwallet_custom() != 33851) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_onchainwallet_default() != 27781) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_wallet_create() != 28953) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_wallet_create_with_onchain() !=
      8743) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_wallet_open() != 34910) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_constructor_wallet_open_with_onchain() != 2455) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_balance() !=
      17287) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_prepare_tx() !=
      44054) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_prepare_drain_tx() !=
      7162) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_finish_tx() !=
      60386) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_wallet_tx() !=
      24800) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_wallet_tx_confirmed_block() !=
      908) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_get_spending_tx() !=
      62027) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_make_signed_p2a_cpfp() !=
      51567) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
  if (uniffi_bark_ffi_checksum_method_customonchainwalletcallbacks_store_signed_p2a_cpfp() !=
      35734) {
    throw UniffiInternalError.panicked("UniFFI API checksum mismatch");
  }
}

void ensureInitialized() {
  _checkApiVersion();
  _checkApiChecksums();
}

// Expose only the clean public API
export 'src/wallet.dart';
export 'src/onchain_wallet.dart';
export 'src/errors.dart';
export 'src/utils.dart';
export 'src/generated/bark.dart'
    show
        AddressWithIndex,
        ArkInfo,
        Balance,
        BarkException,
        BlockRef,
        Config,
        CpfpParams,
        CustomOnchainWalletCallbacks,
        Destination,
        LightningInvoice,
        LightningPaymentResult,
        LightningReceiveStatus,
        LightningSendStatus,
        Movement,
        Network,
        OffboardResult,
        OnchainBalance,
        OutPoint,
        PendingBoard,
        Vtxo,
        WalletProperties;

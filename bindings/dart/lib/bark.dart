// Expose only the clean public API
export 'src/wallet.dart';
export 'src/errors.dart';
export 'src/generated/bark_ffi.dart'
    show
        Balance,
        BarkException,
        Config,
        LightningInvoice,
        LightningPaymentResult,
        Network,
        OffboardResult,
        Vtxo,
        WalletProperties;

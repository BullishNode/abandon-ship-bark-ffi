import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';
import 'package:flutter_app/core/frameworks/get_it/injection_container.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/bloc/wallet_bloc.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/bloc/wallet_event.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/bloc/wallet_state.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/view_models/wallet_summary_vm.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveScreen extends StatelessWidget {
  final List<WalletSummaryVM> wallets;

  const ReceiveScreen({super.key, required this.wallets});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletBloc>(),
      child: ReceiveView(wallets: wallets),
    );
  }
}

class ReceiveView extends StatefulWidget {
  final List<WalletSummaryVM> wallets;

  const ReceiveView({super.key, required this.wallets});

  @override
  State<ReceiveView> createState() => _ReceiveViewState();
}

class _ReceiveViewState extends State<ReceiveView> {
  int? selectedWalletId;
  bool hasRequestedPaymentRequest = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.wallets.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.black : AppColors.white,
          elevation: 0,
          title: const Text('Receive'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'No wallet found',
            style: TextStyle(
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
          ),
        ),
      );
    }

    final currentWalletId = selectedWalletId ?? widget.wallets.first.id;
    final currentWallet = widget.wallets.firstWhere(
      (w) => w.id == currentWalletId,
      orElse: () => widget.wallets.first,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.black : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        elevation: 0,
        title: const Text('Receive'),
        centerTitle: true,
      ),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Auto-generate payment request when screen loads
          if (!hasRequestedPaymentRequest) {
            Future.microtask(() {
              setState(() => hasRequestedPaymentRequest = true);
              if (context.mounted) {
                context.read<WalletBloc>().add(
                  GeneratePaymentRequest(currentWalletId),
                );
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wallet selector (if multiple wallets)
                if (widget.wallets.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.gray900 : AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.gray800 : AppColors.gray200,
                      ),
                    ),
                    child: DropdownButton<int>(
                      value: currentWalletId,
                      underline: const SizedBox(),
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                      dropdownColor: isDark
                          ? AppColors.gray900
                          : AppColors.white,
                      items: widget.wallets.map((wallet) {
                        return DropdownMenuItem<int>(
                          value: wallet.id,
                          child: Text(
                            '${wallet.name} (${wallet.network})',
                            style: TextStyle(
                              color: isDark ? AppColors.white : AppColors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (walletId) {
                        if (walletId != null) {
                          setState(() {
                            selectedWalletId = walletId;
                            hasRequestedPaymentRequest = false;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Single wallet info
                  Text(
                    currentWallet.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentWallet.network.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.gray400 : AppColors.gray600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],

                // QR Code or Loading
                Center(
                  child: _buildQRSection(
                    context,
                    state,
                    currentWalletId,
                    isDark,
                  ),
                ),

                const SizedBox(height: 32),

                // PaymentRequest display and copy
                _buildPaymentRequestSection(
                  context,
                  state,
                  currentWalletId,
                  isDark,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQRSection(
    BuildContext context,
    WalletState state,
    int currentWalletId,
    bool isDark,
  ) {
    if (state is GeneratingPaymentRequest &&
        state.walletId == currentWalletId) {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray900 : AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (state is PaymentRequestGenerated &&
        state.walletId == currentWalletId) {
      return _buildQRCode(context, state.paymentRequest, isDark);
    } else {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray900 : AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Generating payment request...',
            style: TextStyle(
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildPaymentRequestSection(
    BuildContext context,
    WalletState state,
    int currentWalletId,
    bool isDark,
  ) {
    if (state is! PaymentRequestGenerated ||
        state.walletId != currentWalletId) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray900 : AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.gray800 : AppColors.gray200,
            ),
          ),
          child: Column(
            children: [
              Text(
                state.paymentRequest,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: isDark ? AppColors.white : AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _copyToClipboard(context, state.paymentRequest),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Payment Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.white : AppColors.black,
                    foregroundColor: isDark ? AppColors.black : AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            setState(() => hasRequestedPaymentRequest = false);
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Generate New Payment Request'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.gray900 : AppColors.gray100,
            foregroundColor: isDark ? AppColors.white : AppColors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode(
    BuildContext context,
    String paymentRequest,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: paymentRequest,
        version: QrVersions.auto,
        size: 248,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String paymentRequest) {
    Clipboard.setData(ClipboardData(text: paymentRequest));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment request copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

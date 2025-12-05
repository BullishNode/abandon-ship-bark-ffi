import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';
import 'package:flutter_app/core/frameworks/get_it/injection_container.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_bloc.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_event.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_state.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/wallet_summary_vm.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SendScreen extends StatelessWidget {
  final List<WalletSummaryVM> wallets;

  const SendScreen({super.key, required this.wallets});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletBloc>(),
      child: SendView(wallets: wallets),
    );
  }
}

class SendView extends StatefulWidget {
  final List<WalletSummaryVM> wallets;

  const SendView({super.key, required this.wallets});

  @override
  State<SendView> createState() => _SendViewState();
}

class _SendViewState extends State<SendView> {
  final _formKey = GlobalKey<FormState>();
  final _arkAddressController = TextEditingController();
  final _amountController = TextEditingController();
  int? selectedWalletId;

  @override
  void dispose() {
    _arkAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.wallets.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.white,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.black : AppColors.white,
          elevation: 0,
          title: const Text('Send Payment'),
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
        title: const Text('Send Arkoor Payment'),
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
          } else if (state is PaymentSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment sent successfully! TX: ${state.txid}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Navigate back after successful payment
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                context.pop();
              }
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is SendingPayment;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
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

                  // Ark Address field
                  TextFormField(
                    controller: _arkAddressController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Ark Address',
                      hintText: 'Enter recipient Ark address',
                      filled: true,
                      fillColor: isDark ? AppColors.gray900 : AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.gray800 : AppColors.gray200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.white : AppColors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an Ark address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Amount field
                  TextFormField(
                    controller: _amountController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Amount (sats)',
                      hintText: 'Enter amount in satoshis',
                      filled: true,
                      fillColor: isDark ? AppColors.gray900 : AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.gray800 : AppColors.gray200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.white : AppColors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = int.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context.read<WalletBloc>().add(
                                      SendArkoorPayment(
                                        walletId: currentWalletId,
                                        arkAddress: _arkAddressController.text,
                                        amountSats:
                                            int.parse(_amountController.text),
                                      ),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.white : AppColors.black,
                        foregroundColor: isDark ? AppColors.black : AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Send Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Arkoor payments are instant off-chain transfers to other Ark users.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.gray300 : AppColors.gray700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

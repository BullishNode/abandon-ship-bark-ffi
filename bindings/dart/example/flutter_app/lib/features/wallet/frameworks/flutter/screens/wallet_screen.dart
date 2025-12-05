import 'package:flutter/material.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';
import 'package:flutter_app/core/frameworks/flutter/widgets/tabs/chip_tabs.dart';
import 'package:flutter_app/core/frameworks/get_it/injection_container.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_bloc.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_event.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_state.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/transaction_vm.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/vtxo_vm.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/wallet_balance_vm.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/widgets/create_wallet_dialog.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/widgets/no_wallet_card.dart';
import 'package:flutter_app/features/wallet/frameworks/go_router/wallet_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WalletBloc>()..add(const LoadWallets()),
      child: const WalletView(),
    );
  }
}

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is WalletCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Wallet "${state.name}" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is WalletLoading || state is CreatingWallet) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasWallets = state is WalletsLoaded && state.wallets.isNotEmpty;
        // Calculate total balance across all wallets
        WalletBalanceVM? totalBalance;
        if (state is WalletsLoaded && state.balances.isNotEmpty) {
          int totalSpendable = 0;
          int totalPendingInRound = 0;
          int totalPendingExit = 0;
          int totalPendingLightningSend = 0;
          int totalPendingLightningReceiveTotal = 0;
          int totalPendingLightningReceiveClaimable = 0;
          int totalPendingBoard = 0;

          for (final balance in state.balances.values) {
            totalSpendable += balance.spendableSats;
            totalPendingInRound += balance.pendingInRoundSats;
            totalPendingExit += balance.pendingExitSats;
            totalPendingLightningSend += balance.pendingLightningSendSats;
            totalPendingLightningReceiveTotal +=
                balance.pendingLightningReceiveTotalSats;
            totalPendingLightningReceiveClaimable +=
                balance.pendingLightningReceiveClaimableSats;
            totalPendingBoard += balance.pendingBoardSats;
          }

          totalBalance = WalletBalanceVM(
            walletId: 0, // Not specific to any wallet
            spendableSats: totalSpendable,
            pendingInRoundSats: totalPendingInRound,
            pendingExitSats: totalPendingExit,
            pendingLightningSendSats: totalPendingLightningSend,
            pendingLightningReceiveTotalSats: totalPendingLightningReceiveTotal,
            pendingLightningReceiveClaimableSats:
                totalPendingLightningReceiveClaimable,
            pendingBoardSats: totalPendingBoard,
          );
        }

        return Container(
          color: isDark ? AppColors.black : AppColors.white,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  if (state is WalletsLoaded) {
                    context.read<WalletBloc>().add(const SyncWallet());
                    // Wait a bit for sync to complete
                    await Future.delayed(const Duration(milliseconds: 500));
                  }
                },
                backgroundColor: isDark ? AppColors.gray900 : AppColors.white,
                color: isDark ? AppColors.white : AppColors.black,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total Value Hero Section
                            Container(
                              width: double.infinity,
                              color: isDark ? AppColors.black : AppColors.white,
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                32,
                                24,
                                32,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    hasWallets && state.wallets.isNotEmpty
                                        ? state.wallets.first.name
                                        : 'Total Value',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.gray400
                                          : AppColors.gray600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    totalBalance != null
                                        ? '₿ ${totalBalance.totalSats}'
                                        : '₿ 0',
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.bitcoin,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ActionChip(
                                    label: Text(
                                      'sats',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.gray400
                                            : AppColors.gray600,
                                      ),
                                    ),
                                    backgroundColor: isDark
                                        ? AppColors.gray800
                                        : AppColors.gray100,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onPressed: () {
                                      // TODO: Toggle denomination (sats/BTC)
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Backup Card
                            if (hasWallets && state.wallets.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.gray900
                                        : AppColors.white,
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.gray800
                                          : AppColors.gray200,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.shield_outlined,
                                        color: Colors.orange,
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      'Backup Seed Phrase',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.white
                                            : AppColors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Secure your wallet',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.gray400
                                            : AppColors.gray600,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: isDark
                                          ? AppColors.gray600
                                          : AppColors.gray400,
                                    ),
                                    onTap: () => context.pushNamed(
                                      WalletRoute.backup.name,
                                      extra: state.wallets.first.id,
                                    ),
                                  ),
                                ),
                              ),

                            // Tabs
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                              child: ChipTabs(
                                controller: _tabController,
                                labels: const ['Coins', 'Transactions'],
                                backgroundColor: isDark
                                    ? AppColors.slate800
                                    : AppColors.slate200,
                                indicatorColor: isDark
                                    ? AppColors.slate700
                                    : Colors.white,
                                labelColor: isDark
                                    ? Colors.white
                                    : AppColors.slate900,
                                unselectedLabelColor: AppColors.slate500,
                                borderColor: isDark
                                    ? AppColors.slate700
                                    : AppColors.slate300,
                                padding: const EdgeInsets.all(3),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Content
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, _) {
                                  return IndexedStack(
                                    index: _tabController.index,
                                    children: [
                                      // Coins tab
                                      hasWallets
                                          ? _buildCoinsTab(context, state)
                                          : NoWalletCard(
                                              onNewPressed: () =>
                                                  _showCreateWalletDialog(
                                                    context,
                                                  ),
                                            ),
                                      // Transactions tab
                                      hasWallets
                                          ? _buildTransactionsTab(
                                              context,
                                              state,
                                            )
                                          : NoWalletCard(
                                              onNewPressed: () =>
                                                  _showCreateWalletDialog(
                                                    context,
                                                  ),
                                            ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            // Bottom padding to account for fixed buttons
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Fixed Quick Actions at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.black : AppColors.white,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: hasWallets
                              ? () => context.pushNamed(
                                  WalletRoute.send.name,
                                  extra: state.wallets,
                                )
                              : null,
                          icon: const Icon(Icons.arrow_upward, size: 20),
                          label: const Text('Send'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.white
                                : AppColors.black,
                            foregroundColor: isDark
                                ? AppColors.black
                                : AppColors.white,
                            disabledBackgroundColor: isDark
                                ? AppColors.gray800
                                : AppColors.gray200,
                            disabledForegroundColor: AppColors.gray500,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: hasWallets
                              ? () => context.pushNamed(
                                  WalletRoute.receive.name,
                                  extra: (state).wallets,
                                )
                              : null,
                          icon: const Icon(Icons.arrow_downward, size: 20),
                          label: const Text('Receive'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.gray900
                                : AppColors.gray100,
                            foregroundColor: isDark
                                ? AppColors.white
                                : AppColors.black,
                            disabledBackgroundColor: isDark
                                ? AppColors.gray800
                                : AppColors.gray200,
                            disabledForegroundColor: AppColors.gray500,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinsTab(BuildContext context, WalletsLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect all VTXOs from all wallets
    final allVtxos = <VtxoVM>[];
    for (final wallet in state.wallets) {
      final walletVtxos = state.vtxos[wallet.id] ?? [];
      allVtxos.addAll(walletVtxos);
    }

    if (allVtxos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No coins yet. Receive some bitcoin to get started.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allVtxos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final vtxo = allVtxos[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.black : AppColors.white,
            border: Border.all(
              color: isDark ? AppColors.gray900 : AppColors.gray200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // VTXO icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.gray900 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.circle,
                  size: 20,
                  color: _getVtxoStateColor(vtxo.state),
                ),
              ),
              const SizedBox(width: 12),
              // VTXO details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatVtxoId(vtxo.id),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.black,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires at block ${vtxo.expiryHeight} • ${vtxo.state}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '₿ ${vtxo.amountSats}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bitcoin,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatVtxoId(String id) {
    // Format: txid:index -> shortened_txid...:index
    final parts = id.split(':');
    if (parts.length == 2) {
      final txid = parts[0];
      final index = parts[1];
      final shortened = txid.length > 8 ? txid.substring(0, 8) : txid;
      return '$shortened...:$index';
    }
    // Fallback if format is different
    return id.length > 12 ? '${id.substring(0, 12)}...' : id;
  }

  Color _getVtxoStateColor(String state) {
    switch (state) {
      case 'Spendable':
        return Colors.green;
      case 'Spent':
        return Colors.grey;
      case 'Locked':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionsTab(BuildContext context, WalletsLoaded state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collect all transactions from all wallets
    final allTransactions = <TransactionVM>[];
    for (final wallet in state.wallets) {
      final walletTransactions = state.transactions[wallet.id] ?? [];
      allTransactions.addAll(walletTransactions);
    }

    // Sort by creation date (newest first)
    allTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (allTransactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No transactions yet. Start by receiving or sending bitcoin.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = allTransactions[index];
        final isPositive = transaction.effectiveBalanceSats > 0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.black : AppColors.white,
            border: Border.all(
              color: isDark ? AppColors.gray900 : AppColors.gray200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Transaction icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.gray900 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 20,
                  color: isPositive ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${transaction.subsystemName} (${transaction.subsystemKind})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${transaction.status}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.gray400 : AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '${isPositive ? '+' : ''}₿ ${transaction.effectiveBalanceSats}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<WalletBloc>(),
        child: const CreateWalletDialog(),
      ),
    );
  }
}

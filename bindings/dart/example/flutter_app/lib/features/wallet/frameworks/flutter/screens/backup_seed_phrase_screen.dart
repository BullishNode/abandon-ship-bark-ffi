import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';
import 'package:flutter_app/core/frameworks/get_it/injection_container.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_bloc.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_event.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/bloc/wallet_state.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/wallet_backup_vm.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BackupSeedPhraseScreen extends StatefulWidget {
  final int walletId;

  const BackupSeedPhraseScreen({super.key, required this.walletId});

  @override
  State<BackupSeedPhraseScreen> createState() => _BackupSeedPhraseScreenState();
}

class _BackupSeedPhraseScreenState extends State<BackupSeedPhraseScreen> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Seed Phrase'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: BlocProvider(
          create: (_) => sl<WalletBloc>()..add(GetBackup(widget.walletId)),
          child: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) {
              if (state is LoadingBackup) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is WalletError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: isDark ? AppColors.gray400 : AppColors.gray600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is BackupLoaded) {
                final backup = state.backup;
                if (backup is! BarkWalletBackupVM) {
                  return Center(
                    child: Text(
                      'Unsupported wallet type',
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.black,
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Warning card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.gray900.withValues(alpha: 0.5)
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keep your seed phrase safe',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.white
                                          : AppColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Never share your seed phrase with anyone. Anyone with access to it can access your funds.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.gray400
                                          : AppColors.gray600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seed phrase display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.gray900 : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.gray800
                                : AppColors.gray200,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (!_isRevealed)
                              Column(
                                children: [
                                  Icon(
                                    Icons.visibility_off,
                                    size: 48,
                                    color: isDark
                                        ? AppColors.gray600
                                        : AppColors.gray400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to reveal seed phrase',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.gray400
                                          : AppColors.gray600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isRevealed = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 20,
                                    ),
                                    label: const Text('Reveal Seed Phrase'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark
                                          ? AppColors.white
                                          : AppColors.black,
                                      foregroundColor: isDark
                                          ? AppColors.black
                                          : AppColors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: backup.mnemonic
                                        .split(' ')
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          final index = entry.key + 1;
                                          final word = entry.value;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? AppColors.gray800
                                                  : AppColors.gray100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '$index.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? AppColors.gray500
                                                        : AppColors.gray500,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  word,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'monospace',
                                                    color: isDark
                                                        ? AppColors.white
                                                        : AppColors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: backup.mnemonic,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Seed phrase copied to clipboard',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy, size: 18),
                                        label: const Text('Copy'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDark
                                              ? AppColors.white
                                              : AppColors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _isRevealed = false;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.visibility_off,
                                          size: 18,
                                        ),
                                        label: const Text('Hide'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDark
                                              ? AppColors.white
                                              : AppColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Additional tips
                      Text(
                        'Backup Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        isDark,
                        Icons.create,
                        'Write it down on paper and store it in a safe place',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        isDark,
                        Icons.do_not_disturb_on,
                        'Never store it digitally (screenshots, notes apps, etc.)',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        isDark,
                        Icons.verified_user,
                        'Keep it private - never share it with anyone',
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(bool isDark, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.gray500 : AppColors.gray500,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.gray400 : AppColors.gray600,
            ),
          ),
        ),
      ],
    );
  }
}

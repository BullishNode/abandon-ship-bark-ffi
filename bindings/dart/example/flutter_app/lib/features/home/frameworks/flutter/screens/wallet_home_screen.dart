import 'package:flutter/material.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/screens/wallet_screen.dart';

/// Wrapper for wallet screen in home navigation
/// This keeps the home feature as the entry point while delegating to wallet feature
class WalletHomeScreen extends StatelessWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletScreen();
  }
}

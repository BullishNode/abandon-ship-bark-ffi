import 'package:flutter_app/core/frameworks/go_router/app_route_module.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/screens/backup_seed_phrase_screen.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/screens/receive_screen.dart';
import 'package:flutter_app/features/wallet/driving_adapters/presenters/view_models/wallet_summary_vm.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/screens/send_screen.dart';
import 'package:go_router/go_router.dart';

enum WalletRoute {
  backup(path: '/backup', name: 'backup'),
  receive(path: '/receive', name: 'receive'),
  send(path: '/send', name: 'send');

  final String path;
  final String name;

  const WalletRoute({required this.path, required this.name});
}

class WalletRouteModule implements AppRouteModule {
  @override
  List<RouteBase> routes() => [
    GoRoute(
      path: WalletRoute.backup.path,
      name: WalletRoute.backup.name,
      builder: (context, state) =>
          BackupSeedPhraseScreen(walletId: state.extra as int),
    ),
    GoRoute(
      path: WalletRoute.receive.path,
      name: WalletRoute.receive.name,
      builder: (context, state) =>
          ReceiveScreen(wallets: state.extra as List<WalletSummaryVM>),
    ),
    GoRoute(
      path: WalletRoute.send.path,
      name: WalletRoute.send.name,
      builder: (context, state) =>
          SendScreen(wallets: state.extra as List<WalletSummaryVM>),
    ),
  ];
}

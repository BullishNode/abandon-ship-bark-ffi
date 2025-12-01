import 'package:flutter_app/core/frameworks/go_router/app_route_module.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/bloc/wallet_state.dart';
import 'package:flutter_app/features/wallet/frameworks/flutter/screens/receive_screen.dart';
import 'package:go_router/go_router.dart';

enum WalletRoute {
  receive(path: '/receive', name: 'receive');

  final String path;
  final String name;

  const WalletRoute({required this.path, required this.name});
}

class WalletRouteModule implements AppRouteModule {
  @override
  List<RouteBase> routes() => [
    GoRoute(
      path: WalletRoute.receive.path,
      name: WalletRoute.receive.name,
      builder: (context, state) =>
          ReceiveScreen(wallets: state.extra as List<WalletSummary>),
    ),
  ];
}

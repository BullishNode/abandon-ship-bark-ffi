import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/frameworks/go_router/home_routes.dart';
import 'package:flutter_app/features/wallet/frameworks/go_router/wallet_routes.dart';
import 'package:flutter_app/core/frameworks/go_router/app_route_module.dart';
import 'package:go_router/go_router.dart';

final List<AppRouteModule> _modules = [HomeRouteModule(), WalletRouteModule()];

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');

  GoRouter buildRouter() {
    final routes = <RouteBase>[..._modules.expand((m) => m.routes())];
    //final observers = _modules.expand((m) => m.observers()).toList();

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: HomeRoute.wallet.path,
      routes: routes,
      //observers: observers,
      //errorBuilder: (c, s) => const NotFoundScreen(),
      // TODO: central redirect/guards here
    );
  }
}

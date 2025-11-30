import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/frameworks/flutter/screens/settings_home_screen.dart';
import 'package:flutter_app/features/home/frameworks/flutter/screens/wallet_home_screen.dart';
import 'package:flutter_app/core/frameworks/flutter/widgets/scaffolds/scaffold_with_bottom_navigation.dart';
import 'package:flutter_app/core/frameworks/go_router/app_route_module.dart';
import 'package:go_router/go_router.dart';

enum HomeRoute {
  wallet(path: '/wallet', name: 'wallet'),
  settings(path: '/settings', name: 'settings');

  final String path;
  final String name;

  const HomeRoute({required this.path, required this.name});
}

class HomeRouteModule implements AppRouteModule {
  static final GlobalKey<NavigatorState> walletShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'walletShell');
  static final GlobalKey<NavigatorState> settingsShellKey =
      GlobalKey<NavigatorState>(debugLabel: 'settingsShell');

  @override
  List<RouteBase> routes() => [
    StatefulShellRoute.indexedStack(
      branches: [
        StatefulShellBranch(
          navigatorKey: walletShellKey,
          routes: [
            GoRoute(
              path: HomeRoute.wallet.path,
              name: HomeRoute.wallet.name,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: WalletHomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: settingsShellKey,
          routes: [
            GoRoute(
              path: HomeRoute.settings.path,
              name: HomeRoute.settings.name,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: SettingsHomeScreen()),
            ),
          ],
        ),
      ],
      pageBuilder: (context, state, navigationShell) {
        return NoTransitionPage(
          child: ScaffoldWithBottomNavigation(
            navigationShell: navigationShell,
            navigationItems: [
              NavigationItem(
                icon: '👛',
                label: 'Wallet',
                description: 'Your coins, transactions and more.',
              ),
              NavigationItem(
                icon: '⚙️',
                label: 'Settings',
                description: 'App settings and preferences',
              ),
            ],
          ),
        );
      },
    ),
  ];
}

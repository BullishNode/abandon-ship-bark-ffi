import 'package:flutter/material.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/color_palette.dart';
import 'package:go_router/go_router.dart';

class NavigationItem {
  NavigationItem({
    required this.icon,
    required this.label,
    required this.description,
  });
  final String icon;
  final String label;
  final String description;
}

class ScaffoldWithBottomNavigation extends StatelessWidget {
  const ScaffoldWithBottomNavigation({
    required this.navigationShell,
    required this.navigationItems,
    Key? key,
  }) : super(key: key ?? const ValueKey('ScaffoldWithNavigation'));

  final StatefulNavigationShell navigationShell;
  final List<NavigationItem> navigationItems;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = navigationItems[navigationShell.currentIndex];
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.white : AppColors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(item.icon, style: TextStyle(fontSize: 24)),
            ),
          ),
        ),
        titleSpacing: 8.0,
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.black,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.gray900 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 22,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
        items: navigationItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Text(item.icon),
                label: item.label,
              ),
            )
            .toList(),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

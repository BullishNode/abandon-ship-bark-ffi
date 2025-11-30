import 'package:flutter/material.dart';
import 'package:flutter_app/core/frameworks/flutter/themes/app_theme.dart';
import 'package:flutter_app/core/frameworks/go_router/app_router.dart';

class BarkApp extends StatelessWidget {
  const BarkApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bark App',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: AppRouter().buildRouter(),
    );
  }
}

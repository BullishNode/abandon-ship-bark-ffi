import 'package:go_router/go_router.dart';

abstract class AppRouteModule {
  List<RouteBase> routes();
  //List<NavigatorObserver> observers() => const [];
}

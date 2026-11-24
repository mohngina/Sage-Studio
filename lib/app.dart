import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/auth_service.dart';
import 'features/navigation/site_header.dart';

class SageStudioApp extends StatefulWidget {
  const SageStudioApp({super.key});

  @override
  State<SageStudioApp> createState() => _SageStudioAppState();
}

class _SageStudioAppState extends State<SageStudioApp> with WidgetsBindingObserver {
  String _currentRoute = '/';

  void _navigateTo(String route) {
    if (_currentRoute == route) return;
    setState(() {
      _currentRoute = route;
    });
    SystemNavigator.routeInformationUpdated(uri: Uri.parse(route));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initial = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (initial.isNotEmpty && initial != '/') {
      _currentRoute = initial;
    }
    // Auth events (OAuth return, password-recovery links) can request a route.
    AuthService.instance.pendingNavigation.addListener(_onPendingNavigation);
    _onPendingNavigation();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final next = routeInformation.uri.toString();
    if (next.isNotEmpty && next != _currentRoute && mounted) {
      setState(() => _currentRoute = next);
    }
    return true;
  }

  void _onPendingNavigation() {
    final route = AuthService.instance.pendingNavigation.value;
    if (route == null) return;
    AuthService.instance.pendingNavigation.value = null;
    _navigateTo(route);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.pendingNavigation.removeListener(_onPendingNavigation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sage Studio — Editorial Luxury Ceramic Practice',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: SiteHeader(
          activeRoute: _currentRoute,
          onNavigate: _navigateTo,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey(_currentRoute),
            child: AppRouter.buildPage(_currentRoute, _navigateTo),
          ),
        ),
      ),
    );
  }
}

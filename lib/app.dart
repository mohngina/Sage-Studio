import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/services/auth_service.dart';
import 'features/navigation/site_header.dart';

class SageStudioApp extends StatefulWidget {
  const SageStudioApp({super.key});

  @override
  State<SageStudioApp> createState() => _SageStudioAppState();
}

class _SageStudioAppState extends State<SageStudioApp> {
  String _currentRoute = '/';

  void _navigateTo(String route) {
    setState(() {
      _currentRoute = route;
    });
  }

  @override
  void initState() {
    super.initState();
    // Auth events (OAuth return, password-recovery links) can request a route.
    AuthService.instance.pendingNavigation.addListener(_onPendingNavigation);
    _onPendingNavigation();
  }

  void _onPendingNavigation() {
    final route = AuthService.instance.pendingNavigation.value;
    if (route == null) return;
    AuthService.instance.pendingNavigation.value = null;
    _navigateTo(route);
  }

  @override
  void dispose() {
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

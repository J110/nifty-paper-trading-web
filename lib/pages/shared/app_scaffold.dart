import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.show_chart, color: Colors.amber),
            label: 'Signals',
          ),
          NavigationDestination(
            icon: Icon(Icons.circle, color: AppTheme.versionColors['v5.4.2']),
            label: 'v5.4.2',
          ),
          NavigationDestination(
            icon: Icon(Icons.circle, color: AppTheme.versionColors['v5.4.3']),
            label: 'v5.4.3',
          ),
          NavigationDestination(
            icon: Icon(Icons.circle, color: AppTheme.versionColors['v5.4.4']),
            label: 'v5.4.4',
          ),
          NavigationDestination(
            icon: Icon(Icons.circle, color: AppTheme.versionColors['v6.2']),
            label: 'v6.2',
          ),
        ],
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/v542')) return 1;
    if (location.startsWith('/v543')) return 2;
    if (location.startsWith('/v544')) return 3;
    if (location.startsWith('/v62')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/signals');
        break;
      case 1:
        context.go('/v542');
        break;
      case 2:
        context.go('/v543');
        break;
      case 3:
        context.go('/v544');
        break;
      case 4:
        context.go('/v62');
        break;
    }
  }
}

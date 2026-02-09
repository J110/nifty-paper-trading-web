import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'config/theme.dart';
import 'pages/shared/app_scaffold.dart';
import 'pages/market_signals/market_signals_page.dart';
import 'pages/trades/trades_page.dart';

void main() {
  runApp(const ProviderScope(child: NiftyPaperTradingApp()));
}

class NiftyPaperTradingApp extends StatelessWidget {
  const NiftyPaperTradingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nifty Paper Trading',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/signals',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(
          path: '/signals',
          builder: (_, __) => const MarketSignalsPage(),
        ),
        GoRoute(
          path: '/v542',
          builder: (_, __) => const TradesPage(version: 'v5.4.2'),
        ),
        GoRoute(
          path: '/v543',
          builder: (_, __) => const TradesPage(version: 'v5.4.3'),
        ),
        GoRoute(
          path: '/v544',
          builder: (_, __) => const TradesPage(version: 'v5.4.4'),
        ),
      ],
    ),
  ],
);

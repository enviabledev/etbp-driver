import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:etbp_driver/screens/splash/splash_screen.dart';
import 'package:etbp_driver/screens/auth/login_screen.dart';
import 'package:etbp_driver/screens/home/home_screen.dart';
import 'package:etbp_driver/screens/trips/trips_screen.dart';
import 'package:etbp_driver/screens/trips/trip_detail_screen.dart';
import 'package:etbp_driver/screens/manifest/manifest_screen.dart';
import 'package:etbp_driver/screens/profile/profile_screen.dart';
import 'package:etbp_driver/screens/manifest/qr_scanner_screen.dart';
import 'package:etbp_driver/screens/trips/inspection_screen.dart';
import 'package:etbp_driver/screens/trips/incident_report_screen.dart';
import 'package:etbp_driver/screens/trips/trip_summary_screen.dart';
import 'package:etbp_driver/screens/trips/navigation_screen.dart';
import 'package:etbp_driver/screens/messaging/chat_screen.dart';
import 'package:etbp_driver/screens/messaging/conversations_screen.dart';
import 'package:etbp_driver/widgets/common/offline_banner.dart';

final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => _Shell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/trips', builder: (_, __) => const TripsScreen()),
          GoRoute(path: '/messages', builder: (_, __) => const ConversationsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/trips/:id', builder: (_, state) => TripDetailScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/trips/:id/manifest', builder: (_, state) => ManifestScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/trips/:id/scan', builder: (_, state) => QrScannerScreen(tripId: state.pathParameters['id']!, manifest: const [])),
      GoRoute(path: '/trips/:id/inspection', builder: (_, state) => InspectionScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/trips/:id/incident', builder: (_, state) => IncidentReportScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/trips/:id/summary', builder: (_, state) => TripSummaryScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/trips/:id/navigation', builder: (_, state) => NavigationScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/chat/:id', builder: (_, state) => ChatScreen(conversationId: state.pathParameters['id']!)),
    ],
  );
});

class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        const OfflineBanner(),
        Expanded(child: child),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index(GoRouterState.of(context).uri.path),
        onTap: (i) => [() => context.go('/home'), () => context.go('/trips'), () => context.go('/messages'), () => context.go('/profile')][i](),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_outlined), activeIcon: Icon(Icons.directions_bus), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
  int _index(String path) {
    if (path.startsWith('/trips')) return 1;
    if (path.startsWith('/messages')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0;
  }
}

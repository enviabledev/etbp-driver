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
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/trips/:id', builder: (_, state) => TripDetailScreen(tripId: state.pathParameters['id']!)),
      GoRoute(path: '/trips/:id/manifest', builder: (_, state) => ManifestScreen(tripId: state.pathParameters['id']!)),
    ],
  );
});

class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index(GoRouterState.of(context).uri.path),
        onTap: (i) => [() => context.go('/home'), () => context.go('/trips'), () => context.go('/profile')][i](),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_outlined), activeIcon: Icon(Icons.directions_bus), label: 'My Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
  int _index(String path) {
    if (path.startsWith('/trips')) return 1;
    if (path.startsWith('/profile')) return 2;
    return 0;
  }
}

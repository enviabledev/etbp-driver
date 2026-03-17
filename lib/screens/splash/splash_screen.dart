import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }
  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final ok = await ref.read(authStateProvider.notifier).checkAuth();
    if (mounted) context.go(ok ? '/home' : '/login');
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.primary,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.directions_bus, size: 64, color: Colors.white),
      const SizedBox(height: 16),
      Text('Driver', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9))),
    ])),
  );
}

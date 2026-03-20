import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});
  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  bool _justReconnected = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted) {
        if (!online && !_isOffline) {
          setState(() { _isOffline = true; _justReconnected = false; });
        } else if (online && _isOffline) {
          setState(() { _isOffline = false; _justReconnected = true; });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _justReconnected = false);
          });
        }
      }
    });
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (mounted && !online) setState(() => _isOffline = true);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_justReconnected) {
      return Container(
        width: double.infinity,
        color: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: const Text('Back online', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      );
    }
    if (!_isOffline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.amber[700],
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: const Text("You're offline — changes will sync when connected", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

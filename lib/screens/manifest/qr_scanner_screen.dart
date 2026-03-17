import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:etbp_driver/config/theme.dart';
import 'package:etbp_driver/core/auth/auth_provider.dart';
import 'package:etbp_driver/core/api/endpoints.dart';
import 'package:etbp_driver/models/manifest_entry.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String tripId;
  final List<ManifestEntry> manifest;
  const QrScannerScreen({super.key, required this.tripId, required this.manifest});
  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  String? _lastScanned;
  _ScanResult? _result;
  bool _processing = false;
  int _checkedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkedCount = widget.manifest.where((m) => m.checkedIn).length;
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || _processing || code == _lastScanned) return;

    _lastScanned = code;
    setState(() => _processing = true);

    // Parse booking ref from QR (format: "ETBP-REFCODE" or just "REFCODE")
    final bookingRef = code.replaceFirst(RegExp(r'^ETBP-', caseSensitive: false), '').trim();

    // Find in manifest
    final entry = widget.manifest.where((m) =>
      m.bookingRef.toUpperCase() == bookingRef.toUpperCase() ||
      m.bookingRef.toUpperCase().contains(bookingRef.toUpperCase())
    ).firstOrNull;

    if (entry == null) {
      setState(() {
        _result = _ScanResult(type: _ResultType.notFound, message: 'Booking not found on this trip', detail: bookingRef);
        _processing = false;
      });
      _autoDismissResult();
      return;
    }

    if (entry.checkedIn) {
      setState(() {
        _result = _ScanResult(type: _ResultType.alreadyCheckedIn, message: 'Already checked in', detail: entry.passengerName);
        _processing = false;
      });
      _autoDismissResult();
      return;
    }

    // Call API to check in
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(Endpoints.driverCheckin(widget.tripId, entry.bookingId));
      HapticFeedback.mediumImpact();
      setState(() {
        _checkedCount++;
        _result = _ScanResult(
          type: _ResultType.success,
          message: res.data['passenger_name'] ?? entry.passengerName,
          detail: 'Seat ${res.data['seat_number'] ?? entry.seatNumber ?? '?'}',
        );
        _processing = false;
      });
    } catch (e) {
      setState(() {
        _result = _ScanResult(type: _ResultType.error, message: e.toString());
        _processing = false;
      });
    }
    _autoDismissResult();
  }

  void _autoDismissResult() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _result = null; _lastScanned = null; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, foregroundColor: Colors.white,
        title: const Text('Scan Boarding Pass'),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('$_checkedCount/${widget.manifest.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),

          // Overlay
          Center(child: Container(
            width: 250, height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          )),

          // Result overlay
          if (_result != null) Positioned(
            bottom: 100, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _result!.color, borderRadius: BorderRadius.circular(16),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_result!.icon, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text(_result!.message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                if (_result!.detail != null) Text(_result!.detail!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ResultType { success, alreadyCheckedIn, notFound, error }

class _ScanResult {
  final _ResultType type;
  final String message;
  final String? detail;
  _ScanResult({required this.type, required this.message, this.detail});

  Color get color => switch (type) {
    _ResultType.success => AppTheme.success,
    _ResultType.alreadyCheckedIn => AppTheme.warning,
    _ResultType.notFound => AppTheme.error,
    _ResultType.error => AppTheme.error,
  };

  IconData get icon => switch (type) {
    _ResultType.success => Icons.check_circle,
    _ResultType.alreadyCheckedIn => Icons.info,
    _ResultType.notFound => Icons.cancel,
    _ResultType.error => Icons.error,
  };
}

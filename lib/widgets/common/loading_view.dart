import 'package:flutter/material.dart';
import 'package:etbp_driver/config/theme.dart';

class LoadingView extends StatelessWidget {
  final String? text;
  const LoadingView({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: AppTheme.primary),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(text!, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ]),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ]),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyView({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: AppTheme.textSecondary),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        if (subtitle != null) Text(subtitle!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }
}

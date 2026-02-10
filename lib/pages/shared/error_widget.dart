import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  bool get _isColdStart =>
      message.contains('waking up') || message.contains('starting up');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isColdStart ? Icons.cloud_queue : Icons.error_outline,
              size: 48,
              color: _isColdStart
                  ? const Color(0xFF58A6FF)
                  : Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(_isColdStart ? 'Try Again' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isColdStart
                      ? const Color(0xFF1F6FEB)
                      : const Color(0xFF21262D),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

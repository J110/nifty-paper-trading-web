import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/signal.dart';
import '../models/chart_data.dart';

final currentSignalsProvider =
    FutureProvider.autoDispose<SignalResponse>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getCurrentSignals();
});

/// Auto-refresh every 5 minutes
final signalsAutoRefreshProvider =
    StreamProvider.autoDispose<SignalResponse>((ref) async* {
  final api = ref.read(apiServiceProvider);
  while (true) {
    try {
      yield await api.getCurrentSignals();
    } catch (e) {
      // Yield last known state or rethrow
      rethrow;
    }
    await Future.delayed(const Duration(minutes: 5));
  }
});

/// Nifty price chart data
final niftyChartProvider =
    FutureProvider.autoDispose<List<OhlcCandle>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getNiftyChart(period: '3m', interval: '1d');
});

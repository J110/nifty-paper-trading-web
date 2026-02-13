import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/signal.dart';
import '../models/chart_data.dart';
import '../models/activity.dart';

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

/// Predicted vs actual drawdown comparison — parameterised by period
final drawdownComparisonProvider =
    FutureProvider.autoDispose.family<List<DrawdownPoint>, String>((ref, period) async {
  final api = ref.read(apiServiceProvider);
  return api.getDrawdownComparison(period: period);
});

/// Nifty price chart data — parameterised by period
final niftyChartProvider =
    FutureProvider.autoDispose.family<List<OhlcCandle>, String>((ref, period) async {
  final api = ref.read(apiServiceProvider);
  final interval = period == '1d' ? '5m' : '1d';
  return api.getNiftyChart(period: period, interval: interval);
});

/// Today's trading activity log
final todayActivityProvider =
    FutureProvider.autoDispose<TodayActivity>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getTodayActivity();
});

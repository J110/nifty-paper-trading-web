import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/signal.dart';
import '../models/trade.dart';
import '../models/delay_analysis.dart';
import '../models/returns.dart';
import '../models/chart_data.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ── Signals ──
  Future<SignalResponse> getCurrentSignals() async {
    final resp = await _dio.get(ApiConfig.signalsCurrent);
    return SignalResponse.fromJson(resp.data);
  }

  Future<List<Map<String, dynamic>>> getSignalHistory({int days = 30}) async {
    final resp =
        await _dio.get(ApiConfig.signalsHistory, queryParameters: {'days': days});
    return List<Map<String, dynamic>>.from(resp.data['history'] ?? []);
  }

  // ── Trades ──
  Future<TradesResponse> getTrades(String version, {String status = 'all'}) async {
    final resp = await _dio.get(
      ApiConfig.trades(version),
      queryParameters: {'status': status},
    );
    return TradesResponse.fromJson(resp.data);
  }

  // ── Delay Analysis ──
  Future<DelayAnalysisResponse> getDelayAnalysis(String version) async {
    final resp = await _dio.get(ApiConfig.delayAnalysis(version));
    return DelayAnalysisResponse.fromJson(resp.data);
  }

  // ── Returns ──
  Future<ReturnsResponse> getReturns(String version,
      {String period = 'weekly'}) async {
    final resp = await _dio.get(
      ApiConfig.returns(version),
      queryParameters: {'period': period},
    );
    return ReturnsResponse.fromJson(resp.data);
  }

  // ── Chart Data ──
  Future<List<OhlcCandle>> getNiftyChart(
      {String period = '1y', String interval = '1d'}) async {
    final resp = await _dio.get(
      ApiConfig.chartNifty,
      queryParameters: {'period': period, 'interval': interval},
    );
    return (resp.data as List).map((e) => OhlcCandle.fromJson(e)).toList();
  }

  Future<List<EquityPoint>> getEquityCurve(String version) async {
    final resp = await _dio.get(ApiConfig.chartEquity(version));
    final data = resp.data['equity_curve'] as List? ?? [];
    return data.map((e) => EquityPoint.fromJson(e)).toList();
  }
}

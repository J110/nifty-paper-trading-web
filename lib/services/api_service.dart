import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/signal.dart';
import '../models/trade.dart';
import '../models/delay_analysis.dart';
import '../models/returns.dart';
import '../models/chart_data.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Friendly error message for common Dio failures
String friendlyError(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Server is waking up (free tier cold start). This takes ~30s on first load. Please tap Retry.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Check your internet connection or try again in a moment.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode ?? 0;
        if (code == 502 || code == 503) {
          return 'Server is starting up. Please wait a moment and tap Retry.';
        }
        return 'Server error ($code). Please try again.';
      default:
        return 'Connection failed. Tap Retry to try again.';
    }
  }
  return 'Something went wrong. Tap Retry to try again.';
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      // Render free tier cold start can take 30-60s
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ));

    // Retry interceptor: auto-retry on timeout/5xx up to 2 times
    _dio.interceptors.add(_RetryInterceptor(_dio));
  }

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

/// Dio interceptor that retries failed requests on timeout or 5xx errors.
class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 3);

  _RetryInterceptor(this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

    final shouldRetry = retryCount < _maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.sendTimeout ||
            err.type == DioExceptionType.connectionError ||
            (err.response?.statusCode != null &&
                err.response!.statusCode! >= 500));

    if (shouldRetry) {
      await Future.delayed(_retryDelay * (retryCount + 1));

      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;

      try {
        final response = await _dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        if (e is DioException) {
          handler.next(e);
          return;
        }
      }
    }

    handler.next(err);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/trade.dart';
import '../models/delay_analysis.dart';
import '../models/returns.dart';
import '../models/chart_data.dart';

final tradesProvider =
    FutureProvider.family.autoDispose<TradesResponse, String>(
  (ref, version) async {
    final api = ref.read(apiServiceProvider);
    return api.getTrades(version);
  },
);

typedef DelayParams = ({
  String version,
  String dataMode,
});

final delayAnalysisProvider =
    FutureProvider.family.autoDispose<DelayAnalysisResponse, DelayParams>(
  (ref, params) async {
    return ref.read(apiServiceProvider).getDelayAnalysis(
          params.version,
          dataMode: params.dataMode,
        );
  },
);

typedef ReturnsParams = ({
  String version,
  String period,
  String dataMode,
  String? fromDate,
  String? toDate,
});

final returnsProvider =
    FutureProvider.family.autoDispose<ReturnsResponse, ReturnsParams>(
  (ref, params) async {
    return ref.read(apiServiceProvider).getReturns(
          params.version,
          period: params.period,
          dataMode: params.dataMode,
          fromDate: params.fromDate,
          toDate: params.toDate,
        );
  },
);

typedef EquityCurveParams = ({
  String version,
  String dataMode,
});

final equityCurveProvider =
    FutureProvider.family.autoDispose<List<EquityPoint>, EquityCurveParams>(
  (ref, params) async {
    return ref.read(apiServiceProvider).getEquityCurve(
          params.version,
          dataMode: params.dataMode,
        );
  },
);

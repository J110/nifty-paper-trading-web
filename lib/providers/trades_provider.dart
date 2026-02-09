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

final delayAnalysisProvider =
    FutureProvider.family.autoDispose<DelayAnalysisResponse, String>(
  (ref, version) async {
    return ref.read(apiServiceProvider).getDelayAnalysis(version);
  },
);

typedef ReturnsParams = ({String version, String period});

final returnsProvider =
    FutureProvider.family.autoDispose<ReturnsResponse, ReturnsParams>(
  (ref, params) async {
    return ref
        .read(apiServiceProvider)
        .getReturns(params.version, period: params.period);
  },
);

final equityCurveProvider =
    FutureProvider.family.autoDispose<List<EquityPoint>, String>(
  (ref, version) async {
    return ref.read(apiServiceProvider).getEquityCurve(version);
  },
);

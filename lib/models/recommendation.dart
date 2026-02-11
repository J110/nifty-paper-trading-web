/// Data classes for trade recommendations.

class Recommendation {
  final String date;
  final double predictedDrawdownPct;
  final String signal;
  final String? tradeType;
  final double sizeMult;
  final double niftySpot;
  final double vix;
  final double confidenceScore;

  Recommendation({
    required this.date,
    required this.predictedDrawdownPct,
    required this.signal,
    this.tradeType,
    required this.sizeMult,
    required this.niftySpot,
    required this.vix,
    required this.confidenceScore,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      date: json['date'] ?? '',
      predictedDrawdownPct:
          (json['predicted_drawdown_pct'] as num?)?.toDouble() ?? 0,
      signal: json['signal'] ?? 'no_trade',
      tradeType: json['trade_type'],
      sizeMult: (json['size_mult'] as num?)?.toDouble() ?? 0,
      niftySpot: (json['nifty_spot'] as num?)?.toDouble() ?? 0,
      vix: (json['vix'] as num?)?.toDouble() ?? 0,
      confidenceScore:
          (json['confidence_score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RecommendationsResponse {
  final String version;
  final String label;
  final int count;
  final List<Recommendation> recommendations;

  RecommendationsResponse({
    required this.version,
    required this.label,
    required this.count,
    required this.recommendations,
  });

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['recommendations'] as List? ?? [];
    return RecommendationsResponse(
      version: json['version'] ?? '',
      label: json['label'] ?? '',
      count: json['count'] ?? 0,
      recommendations:
          list.map((e) => Recommendation.fromJson(e)).toList(),
    );
  }
}

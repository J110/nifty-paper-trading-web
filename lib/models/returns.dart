/// Data classes for returns

class ReturnsResponse {
  final String version;
  final String period;
  final List<PeriodReturn> returns;
  final List<CumulativeReturn> cumulative;

  ReturnsResponse({
    required this.version,
    required this.period,
    required this.returns,
    required this.cumulative,
  });

  factory ReturnsResponse.fromJson(Map<String, dynamic> json) {
    final returnsJson = json['returns'] as List? ?? [];
    final cumJson = json['cumulative'] as List? ?? [];
    return ReturnsResponse(
      version: json['version'] ?? '',
      period: json['period'] ?? 'weekly',
      returns: returnsJson.map((e) => PeriodReturn.fromJson(e)).toList(),
      cumulative: cumJson.map((e) => CumulativeReturn.fromJson(e)).toList(),
    );
  }
}

class PeriodReturn {
  final String period;
  final double pnl;
  final double returnPct;
  final int trades;
  final double winRate;

  PeriodReturn({
    required this.period,
    required this.pnl,
    required this.returnPct,
    this.trades = 0,
    this.winRate = 0,
  });

  factory PeriodReturn.fromJson(Map<String, dynamic> json) {
    return PeriodReturn(
      period: json['period'] ?? '',
      pnl: (json['pnl'] as num?)?.toDouble() ?? 0,
      returnPct: (json['return_pct'] as num?)?.toDouble() ?? 0,
      trades: json['trades'] ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CumulativeReturn {
  final String period;
  final double cumulativePnl;
  final double cumulativeReturn;

  CumulativeReturn({
    required this.period,
    required this.cumulativePnl,
    required this.cumulativeReturn,
  });

  factory CumulativeReturn.fromJson(Map<String, dynamic> json) {
    return CumulativeReturn(
      period: json['period'] ?? '',
      cumulativePnl: (json['cumulative_pnl'] as num?)?.toDouble() ?? 0,
      cumulativeReturn:
          (json['cumulative_return'] as num?)?.toDouble() ?? 0,
    );
  }
}

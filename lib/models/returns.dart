/// Data classes for returns

class ReturnsResponse {
  final String version;
  final String period;
  final ReturnsSummary? summary;
  final List<PeriodReturn> returns;
  final List<CumulativeReturn> cumulative;

  ReturnsResponse({
    required this.version,
    required this.period,
    this.summary,
    required this.returns,
    required this.cumulative,
  });

  factory ReturnsResponse.fromJson(Map<String, dynamic> json) {
    final returnsJson = json['returns'] as List? ?? [];
    final cumJson = json['cumulative'] as List? ?? [];
    return ReturnsResponse(
      version: json['version'] ?? '',
      period: json['period'] ?? 'weekly',
      summary: json['summary'] != null
          ? ReturnsSummary.fromJson(json['summary'])
          : null,
      returns: returnsJson.map((e) => PeriodReturn.fromJson(e)).toList(),
      cumulative: cumJson.map((e) => CumulativeReturn.fromJson(e)).toList(),
    );
  }
}

class ReturnsSummary {
  final double totalPnl;
  final double totalReturnPct;
  final int totalTrades;
  final double winRate;
  final double profitFactor;
  final double avgPnl;
  final double startingCapital;

  ReturnsSummary({
    this.totalPnl = 0,
    this.totalReturnPct = 0,
    this.totalTrades = 0,
    this.winRate = 0,
    this.profitFactor = 0,
    this.avgPnl = 0,
    this.startingCapital = 2500000,
  });

  factory ReturnsSummary.fromJson(Map<String, dynamic> json) {
    return ReturnsSummary(
      totalPnl: (json['total_pnl'] as num?)?.toDouble() ?? 0,
      totalReturnPct: (json['total_return_pct'] as num?)?.toDouble() ?? 0,
      totalTrades: json['total_trades'] ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
      profitFactor: (json['profit_factor'] as num?)?.toDouble() ?? 0,
      avgPnl: (json['avg_pnl'] as num?)?.toDouble() ?? 0,
      startingCapital: (json['starting_capital'] as num?)?.toDouble() ?? 2500000,
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

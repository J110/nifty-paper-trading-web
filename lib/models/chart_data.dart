/// Data classes for chart data

class OhlcCandle {
  final String timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  OhlcCandle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  factory OhlcCandle.fromJson(Map<String, dynamic> json) {
    return OhlcCandle(
      timestamp: json['timestamp'] ?? '',
      open: (json['open'] as num?)?.toDouble() ?? 0,
      high: (json['high'] as num?)?.toDouble() ?? 0,
      low: (json['low'] as num?)?.toDouble() ?? 0,
      close: (json['close'] as num?)?.toDouble() ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DrawdownPoint {
  final String date;
  final double predictedDrawdownPct;
  final double? actualDrawdownPct;
  final double niftyClose;
  final bool isPartial;

  DrawdownPoint({
    required this.date,
    required this.predictedDrawdownPct,
    this.actualDrawdownPct,
    required this.niftyClose,
    this.isPartial = false,
  });

  factory DrawdownPoint.fromJson(Map<String, dynamic> json) {
    return DrawdownPoint(
      date: json['date'] ?? '',
      predictedDrawdownPct:
          (json['predicted_drawdown_pct'] as num?)?.toDouble() ?? 0,
      actualDrawdownPct:
          (json['actual_drawdown_pct'] as num?)?.toDouble(),
      niftyClose: (json['nifty_close'] as num?)?.toDouble() ?? 0,
      isPartial: json['is_partial'] ?? false,
    );
  }
}

class EquityPoint {
  final String date;
  final double capital;
  final double dailyPnl;
  final double cumulativePnl;
  final double cumulativeReturnPct;
  final int openPositions;

  EquityPoint({
    required this.date,
    required this.capital,
    this.dailyPnl = 0,
    this.cumulativePnl = 0,
    this.cumulativeReturnPct = 0,
    this.openPositions = 0,
  });

  factory EquityPoint.fromJson(Map<String, dynamic> json) {
    return EquityPoint(
      date: json['date'] ?? '',
      capital: (json['capital'] as num?)?.toDouble() ?? 0,
      dailyPnl: (json['daily_pnl'] as num?)?.toDouble() ?? 0,
      cumulativePnl: (json['cumulative_pnl'] as num?)?.toDouble() ?? 0,
      cumulativeReturnPct:
          (json['cumulative_return_pct'] as num?)?.toDouble() ?? 0,
      openPositions: json['open_positions'] ?? 0,
    );
  }
}

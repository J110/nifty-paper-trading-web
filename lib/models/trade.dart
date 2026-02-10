/// Data classes for trades and portfolio

class TradesResponse {
  final String version;
  final String label;
  final String color;
  final Portfolio portfolio;
  final List<TradeItem> openTrades;
  final List<TradeItem> closedTrades;
  final TradeSummary summary;

  TradesResponse({
    required this.version,
    required this.label,
    required this.color,
    required this.portfolio,
    required this.openTrades,
    required this.closedTrades,
    required this.summary,
  });

  factory TradesResponse.fromJson(Map<String, dynamic> json) {
    final openJson = json['open_trades'] as List? ?? [];
    final closedJson = json['closed_trades'] as List? ?? [];
    return TradesResponse(
      version: json['version'] ?? '',
      label: json['label'] ?? '',
      color: json['color'] ?? '#888',
      portfolio: Portfolio.fromJson(json['portfolio'] ?? {}),
      openTrades: openJson.map((e) => TradeItem.fromJson(e)).toList(),
      closedTrades: closedJson.map((e) => TradeItem.fromJson(e)).toList(),
      summary: TradeSummary.fromJson(json['summary'] ?? {}),
    );
  }
}

class Portfolio {
  final double startingCapital;
  final double currentCapital;
  final double totalPnl;
  final double totalReturnPct;
  final double realizedPnl;
  final double unrealizedPnl;
  final double deployedCapital;
  final double availableCapital;
  final int openPositions;
  final int closedPositions;
  final int totalTrades;
  final double winRate;
  final double avgPnl;
  final double profitFactor;

  Portfolio({
    required this.startingCapital,
    required this.currentCapital,
    required this.totalPnl,
    required this.totalReturnPct,
    this.realizedPnl = 0,
    this.unrealizedPnl = 0,
    this.deployedCapital = 0,
    this.availableCapital = 0,
    this.openPositions = 0,
    this.closedPositions = 0,
    this.totalTrades = 0,
    this.winRate = 0,
    this.avgPnl = 0,
    this.profitFactor = 0,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      startingCapital: (json['starting_capital'] as num?)?.toDouble() ?? 2500000,
      currentCapital: (json['current_capital'] as num?)?.toDouble() ?? 2500000,
      totalPnl: (json['total_pnl'] as num?)?.toDouble() ?? 0,
      totalReturnPct: (json['total_return_pct'] as num?)?.toDouble() ?? 0,
      realizedPnl: (json['realized_pnl'] as num?)?.toDouble() ?? 0,
      unrealizedPnl: (json['unrealized_pnl'] as num?)?.toDouble() ?? 0,
      deployedCapital: (json['deployed_capital'] as num?)?.toDouble() ?? 0,
      availableCapital: (json['available_capital'] as num?)?.toDouble() ?? 0,
      openPositions: json['open_positions'] ?? 0,
      closedPositions: json['closed_positions'] ?? 0,
      totalTrades: json['total_trades'] ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
      avgPnl: (json['avg_pnl'] as num?)?.toDouble() ?? 0,
      profitFactor: (json['profit_factor'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TradeItem {
  final String tradeId;
  final String version;
  final String? date;
  final String signalType;
  final String tradeType;
  final String entryMode;
  final String? entryDate;
  final String? entryTime;
  final double entrySpot;
  final String? expiry;
  final double? sellStrike;
  final double? buyStrike;
  final double? icCallSell;
  final double? icCallBuy;
  final int numLots;
  final double? creditReceived;
  final double? totalCredit;
  final String status;
  final double? currentSpreadValue;
  final double? currentPnl;
  final double? currentPnlPct;
  final double? unrealizedPnl;
  final String? exitDate;
  final String? exitTime;
  final double? exitSpot;
  final String? exitReason;
  final double? realizedPnl;
  final double? positionSizePct;
  final double? graduatedMult;
  final double? capitalDeployed;
  final int? holdingDays;
  // Bear debit fields (v6.2+)
  final bool isBearDebit;
  final int bearTier;
  final double? entryDebit;
  final double? predictedDrawdown;
  final double? maxProfit;
  final double? maxLossAmount;

  TradeItem({
    required this.tradeId,
    required this.version,
    this.date,
    required this.signalType,
    required this.tradeType,
    required this.entryMode,
    this.entryDate,
    this.entryTime,
    required this.entrySpot,
    this.expiry,
    this.sellStrike,
    this.buyStrike,
    this.icCallSell,
    this.icCallBuy,
    required this.numLots,
    this.creditReceived,
    this.totalCredit,
    required this.status,
    this.currentSpreadValue,
    this.currentPnl,
    this.currentPnlPct,
    this.unrealizedPnl,
    this.exitDate,
    this.exitTime,
    this.exitSpot,
    this.exitReason,
    this.realizedPnl,
    this.positionSizePct,
    this.graduatedMult,
    this.capitalDeployed,
    this.holdingDays,
    this.isBearDebit = false,
    this.bearTier = 0,
    this.entryDebit,
    this.predictedDrawdown,
    this.maxProfit,
    this.maxLossAmount,
  });

  factory TradeItem.fromJson(Map<String, dynamic> json) {
    return TradeItem(
      tradeId: json['trade_id'] ?? '',
      version: json['version'] ?? '',
      date: json['date'],
      signalType: json['signal_type'] ?? '',
      tradeType: json['trade_type'] ?? '',
      entryMode: json['entry_mode'] ?? 'normal',
      entryDate: json['entry_date'],
      entryTime: json['entry_time'],
      entrySpot: (json['entry_spot'] as num?)?.toDouble() ?? 0,
      expiry: json['expiry'],
      sellStrike: (json['sell_strike'] as num?)?.toDouble(),
      buyStrike: (json['buy_strike'] as num?)?.toDouble(),
      icCallSell: (json['ic_call_sell'] as num?)?.toDouble(),
      icCallBuy: (json['ic_call_buy'] as num?)?.toDouble(),
      numLots: json['num_lots'] ?? 0,
      creditReceived: (json['credit_received'] as num?)?.toDouble(),
      totalCredit: (json['total_credit'] as num?)?.toDouble(),
      status: json['status'] ?? 'unknown',
      currentSpreadValue: (json['current_spread_value'] as num?)?.toDouble(),
      currentPnl: (json['current_pnl'] as num?)?.toDouble(),
      currentPnlPct: (json['current_pnl_pct'] as num?)?.toDouble(),
      unrealizedPnl: (json['unrealized_pnl'] as num?)?.toDouble(),
      exitDate: json['exit_date'],
      exitTime: json['exit_time'],
      exitSpot: (json['exit_spot'] as num?)?.toDouble(),
      exitReason: json['exit_reason'],
      realizedPnl: (json['realized_pnl'] as num?)?.toDouble(),
      positionSizePct: (json['position_size_pct'] as num?)?.toDouble(),
      graduatedMult: (json['graduated_mult'] as num?)?.toDouble(),
      capitalDeployed: (json['capital_deployed'] as num?)?.toDouble(),
      holdingDays: json['holding_days'],
      isBearDebit: json['is_bear_debit'] ?? false,
      bearTier: json['bear_tier'] ?? 0,
      entryDebit: (json['entry_debit'] as num?)?.toDouble(),
      predictedDrawdown: (json['predicted_drawdown'] as num?)?.toDouble(),
      maxProfit: (json['max_profit'] as num?)?.toDouble(),
      maxLossAmount: (json['max_loss_amount'] as num?)?.toDouble(),
    );
  }

  /// PnL value (realized if closed, unrealized if open)
  double get pnl => status == 'closed' ? (realizedPnl ?? 0) : (currentPnl ?? 0);

  /// Formatted trade type display
  String get tradeTypeDisplay {
    switch (tradeType) {
      case 'bull_put':
        return 'Bull Put';
      case 'iron_condor':
        return 'Iron Condor';
      case 'bear_put_debit':
        return 'Bear Put Debit';
      default:
        return tradeType;
    }
  }
}

class TradeSummary {
  final int totalTrades;
  final double winRate;
  final double avgPnl;
  final double profitFactor;

  TradeSummary({
    this.totalTrades = 0,
    this.winRate = 0,
    this.avgPnl = 0,
    this.profitFactor = 0,
  });

  factory TradeSummary.fromJson(Map<String, dynamic> json) {
    return TradeSummary(
      totalTrades: json['total_trades'] ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0,
      avgPnl: (json['avg_pnl'] as num?)?.toDouble() ?? 0,
      profitFactor: (json['profit_factor'] as num?)?.toDouble() ?? 0,
    );
  }
}

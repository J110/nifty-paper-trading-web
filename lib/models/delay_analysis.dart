/// Data classes for delay analysis

class DelayAnalysisResponse {
  final String version;
  final DelayAnalysis analysis;

  DelayAnalysisResponse({
    required this.version,
    required this.analysis,
  });

  factory DelayAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return DelayAnalysisResponse(
      version: json['version'] ?? '',
      analysis: DelayAnalysis.fromJson(json['analysis'] ?? {}),
    );
  }
}

class DelayAnalysis {
  final DelayBucket immediate;
  final DelayBucket tenMin;
  final DelayBucket oneHr;
  final DelayBucket threeHr;
  final DelayBucket sixHr;
  final DelayBucket twelveHr;
  final String bestDelay;
  final List<Map<String, dynamic>> perTrade;

  DelayAnalysis({
    required this.immediate,
    required this.tenMin,
    required this.oneHr,
    required this.threeHr,
    required this.sixHr,
    required this.twelveHr,
    this.bestDelay = 'immediate',
    this.perTrade = const [],
  });

  factory DelayAnalysis.fromJson(Map<String, dynamic> json) {
    return DelayAnalysis(
      immediate: DelayBucket.fromJson(json['immediate'] ?? {}),
      tenMin: DelayBucket.fromJson(json['10min'] ?? {}),
      oneHr: DelayBucket.fromJson(json['1hr'] ?? {}),
      threeHr: DelayBucket.fromJson(json['3hr'] ?? {}),
      sixHr: DelayBucket.fromJson(json['6hr'] ?? {}),
      twelveHr: DelayBucket.fromJson(json['12hr'] ?? {}),
      bestDelay: json['best_delay'] ?? 'immediate',
      perTrade: (json['per_trade'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
    );
  }

  List<DelayBucketEntry> get buckets => [
        DelayBucketEntry('Immediate', immediate, 0),
        DelayBucketEntry('10 min', tenMin, 10),
        DelayBucketEntry('1 hour', oneHr, 60),
        DelayBucketEntry('3 hours', threeHr, 180),
        DelayBucketEntry('6 hours', sixHr, 360),
        DelayBucketEntry('12 hours', twelveHr, 720),
      ];
}

class DelayBucket {
  final double totalPnl;
  final double avgEntryCredit;
  final double pnlDelta;

  DelayBucket({
    this.totalPnl = 0,
    this.avgEntryCredit = 0,
    this.pnlDelta = 0,
  });

  factory DelayBucket.fromJson(Map<String, dynamic> json) {
    return DelayBucket(
      totalPnl: (json['total_pnl'] as num?)?.toDouble() ?? 0,
      avgEntryCredit: (json['avg_entry_credit'] as num?)?.toDouble() ?? 0,
      pnlDelta: (json['pnl_delta'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DelayBucketEntry {
  final String label;
  final DelayBucket bucket;
  final int minutesDelay;

  DelayBucketEntry(this.label, this.bucket, this.minutesDelay);
}

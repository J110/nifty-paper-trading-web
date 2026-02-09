/// Data classes for signals and predictions

class SignalResponse {
  final String? timestamp;
  final double? niftySpot;
  final double? vix;
  final double? predictedDrawdown;
  final double? predictedDrawdownPct;
  final Classification? classification;
  final Map<String, VersionSignal> versionSignals;
  final List<Indicator> indicators;
  final double? confidenceScore;
  final String status;

  SignalResponse({
    this.timestamp,
    this.niftySpot,
    this.vix,
    this.predictedDrawdown,
    this.predictedDrawdownPct,
    this.classification,
    this.versionSignals = const {},
    this.indicators = const [],
    this.confidenceScore,
    this.status = 'unknown',
  });

  factory SignalResponse.fromJson(Map<String, dynamic> json) {
    final versionSignalsJson =
        json['version_signals'] as Map<String, dynamic>? ?? {};
    final versSignals = versionSignalsJson.map(
      (k, v) => MapEntry(k, VersionSignal.fromJson(v)),
    );

    final indicatorsJson = json['indicators'] as List? ?? [];
    final indicators =
        indicatorsJson.map((e) => Indicator.fromJson(e)).toList();

    return SignalResponse(
      timestamp: json['timestamp'],
      niftySpot: (json['nifty_spot'] as num?)?.toDouble(),
      vix: (json['vix'] as num?)?.toDouble(),
      predictedDrawdown: (json['predicted_drawdown'] as num?)?.toDouble(),
      predictedDrawdownPct:
          (json['predicted_drawdown_pct'] as num?)?.toDouble(),
      classification: json['classification'] != null
          ? Classification.fromJson(json['classification'])
          : null,
      versionSignals: versSignals,
      indicators: indicators,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      status: json['status'] ?? 'unknown',
    );
  }
}

class Classification {
  final double predictedDrawdown;
  final List<Zone> zones;
  final String currentZone;

  Classification({
    required this.predictedDrawdown,
    required this.zones,
    required this.currentZone,
  });

  factory Classification.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'] as List? ?? [];
    return Classification(
      predictedDrawdown: (json['predicted_drawdown'] as num?)?.toDouble() ?? 0,
      zones: zonesJson.map((e) => Zone.fromJson(e)).toList(),
      currentZone: json['current_zone'] ?? 'Unknown',
    );
  }
}

class Zone {
  final String name;
  final String range;
  final String color;
  final bool active;
  final double distanceToBoundary;

  Zone({
    required this.name,
    required this.range,
    required this.color,
    required this.active,
    required this.distanceToBoundary,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      name: json['name'] ?? '',
      range: json['range'] ?? '',
      color: json['color'] ?? '#888888',
      active: json['active'] ?? false,
      distanceToBoundary:
          (json['distance_to_boundary'] as num?)?.toDouble() ?? 0,
    );
  }
}

class VersionSignal {
  final String signal;
  final String? tradeType;
  final double sizeMult;
  final String label;
  final String color;
  final double positionSizePct;

  VersionSignal({
    required this.signal,
    this.tradeType,
    required this.sizeMult,
    required this.label,
    required this.color,
    required this.positionSizePct,
  });

  factory VersionSignal.fromJson(Map<String, dynamic> json) {
    return VersionSignal(
      signal: json['signal'] ?? 'unknown',
      tradeType: json['trade_type'],
      sizeMult: (json['size_mult'] as num?)?.toDouble() ?? 0,
      label: json['label'] ?? '',
      color: json['color'] ?? '#888888',
      positionSizePct: (json['position_size_pct'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Indicator {
  final String key;
  final String label;
  final String description;
  final double value;
  final String formattedValue;
  final String classification; // bullish, bearish, neutral
  final String bullishWhen;
  final String bearishWhen;

  Indicator({
    required this.key,
    required this.label,
    required this.description,
    required this.value,
    required this.formattedValue,
    required this.classification,
    this.bullishWhen = '',
    this.bearishWhen = '',
  });

  factory Indicator.fromJson(Map<String, dynamic> json) {
    return Indicator(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      formattedValue: json['formatted_value'] ?? '',
      classification: json['classification'] ?? 'neutral',
      bullishWhen: json['bullish_when'] ?? '',
      bearishWhen: json['bearish_when'] ?? '',
    );
  }
}

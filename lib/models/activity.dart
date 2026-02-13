/// Data classes for today's trading activity log.

class TodayActivity {
  final String date;
  final PipelineStatus pipelineStatus;
  final List<ActivityEvent> events;

  TodayActivity({
    required this.date,
    required this.pipelineStatus,
    required this.events,
  });

  factory TodayActivity.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List? ?? [];
    return TodayActivity(
      date: json['date'] ?? '',
      pipelineStatus: PipelineStatus.fromJson(
        json['pipeline_status'] as Map<String, dynamic>? ?? {},
      ),
      events: eventsJson.map((e) => ActivityEvent.fromJson(e)).toList(),
    );
  }
}

class PipelineStatus {
  final bool predictionGenerated;
  final String? predictionTime;
  final int tradesEntered;
  final bool exitsChecked;
  final bool eodProcessed;
  final int priceSnapshots;

  PipelineStatus({
    required this.predictionGenerated,
    this.predictionTime,
    required this.tradesEntered,
    required this.exitsChecked,
    required this.eodProcessed,
    required this.priceSnapshots,
  });

  factory PipelineStatus.fromJson(Map<String, dynamic> json) {
    return PipelineStatus(
      predictionGenerated: json['prediction_generated'] ?? false,
      predictionTime: json['prediction_time'],
      tradesEntered: json['trades_entered'] ?? 0,
      exitsChecked: json['exits_checked'] ?? false,
      eodProcessed: json['eod_processed'] ?? false,
      priceSnapshots: json['price_snapshots'] ?? 0,
    );
  }
}

class ActivityEvent {
  final String time;
  final String type; // "prediction", "trade_opened", "trade_closed", "no_trade"
  final String? version;
  final String message;
  final String detail;

  ActivityEvent({
    required this.time,
    required this.type,
    this.version,
    required this.message,
    required this.detail,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      time: json['time'] ?? '',
      type: json['type'] ?? '',
      version: json['version'],
      message: json['message'] ?? '',
      detail: json['detail'] ?? '',
    );
  }
}

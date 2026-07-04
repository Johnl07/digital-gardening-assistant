import 'plant_input.dart';

class DailyAction {
  final int dayOffset;
  final String action;
  final DateTime timestamp;

  DailyAction({
    required this.dayOffset,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOffset': dayOffset,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DailyAction.fromJson(Map<String, dynamic> json) {
    return DailyAction(
      dayOffset: json['dayOffset'] as int,
      action: json['action'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class PredictionLog {
  final String id;
  final PlantInput input;
  final GrowthStage predictedStage;
  final String healthStatus;
  final List<String> recommendations;
  final DateTime timestamp;
  final List<DailyAction> careLogs;

  PredictionLog({
    required this.id,
    required this.input,
    required this.predictedStage,
    required this.healthStatus,
    required this.recommendations,
    required this.timestamp,
    this.careLogs = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'input': input.toJson(),
      'predictedStage': predictedStage.index,
      'healthStatus': healthStatus,
      'recommendations': recommendations,
      'timestamp': timestamp.toIso8601String(),
      'careLogs': careLogs.map((l) => l.toJson()).toList(),
    };
  }

  factory PredictionLog.fromJson(Map<String, dynamic> json) {
    var logsJson = json['careLogs'] as List?;
    List<DailyAction> logsList = logsJson != null
        ? logsJson.map((l) => DailyAction.fromJson(l as Map<String, dynamic>)).toList()
        : [];

    return PredictionLog(
      id: json['id'] as String,
      input: PlantInput.fromJson(json['input'] as Map<String, dynamic>),
      predictedStage: GrowthStage.values[json['predictedStage'] as int],
      healthStatus: json['healthStatus'] as String,
      recommendations: List<String>.from(json['recommendations'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
      careLogs: logsList,
    );
  }
}

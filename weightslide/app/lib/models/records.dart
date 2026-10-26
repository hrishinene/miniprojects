import 'local_date.dart';

enum CrossingDirection { up, down }

/// The last side of a reference line that was not numerically on the line.
enum LineSide { above, below }

class TrendSnapshot {
  const TrendSnapshot({
    required this.date,
    required this.officialKg,
    required this.movingAverageKg,
    required this.signedDistances,
    required this.activeLevel,
    required this.lastNonZeroSides,
  });

  final LocalDate date;
  final double officialKg;
  final double movingAverageKg;

  /// Signed distance of the moving average from lines 1 through 5.
  final List<double> signedDistances;
  final int activeLevel;
  final List<LineSide?> lastNonZeroSides;

  Map<String, dynamic> toJson() => {
    'date': date.toIso(),
    'officialKg': officialKg,
    'movingAverageKg': movingAverageKg,
    'signedDistances': signedDistances,
    'activeLevel': activeLevel,
    'lastNonZeroSides': [for (final side in lastNonZeroSides) side?.name],
  };

  factory TrendSnapshot.fromJson(Map<String, dynamic> json) {
    return TrendSnapshot(
      date: LocalDate.parse(json['date'] as String),
      officialKg: (json['officialKg'] as num).toDouble(),
      movingAverageKg: (json['movingAverageKg'] as num).toDouble(),
      signedDistances: [
        for (final value in json['signedDistances'] as List<dynamic>)
          (value as num).toDouble(),
      ],
      activeLevel: json['activeLevel'] as int,
      lastNonZeroSides: [
        for (final value in json['lastNonZeroSides'] as List<dynamic>)
          value == null ? null : LineSide.values.byName(value as String),
      ],
    );
  }
}

class Journey {
  const Journey({
    required this.id,
    required this.startDate,
    required this.startingWeightKg,
    required this.weeklyTargetKg,
    required this.activeLevel,
    required this.isActive,
    required this.createdAt,
    required this.baseline,
  });

  final String id;
  final LocalDate startDate;
  final double startingWeightKg;
  final double weeklyTargetKg;
  final int activeLevel;
  final bool isActive;
  final DateTime createdAt;
  final TrendSnapshot baseline;

  Journey copyWith({
    LocalDate? startDate,
    double? startingWeightKg,
    double? weeklyTargetKg,
    int? activeLevel,
    bool? isActive,
    DateTime? createdAt,
    TrendSnapshot? baseline,
  }) {
    return Journey(
      id: id,
      startDate: startDate ?? this.startDate,
      startingWeightKg: startingWeightKg ?? this.startingWeightKg,
      weeklyTargetKg: weeklyTargetKg ?? this.weeklyTargetKg,
      activeLevel: activeLevel ?? this.activeLevel,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      baseline: baseline ?? this.baseline,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDate': startDate.toIso(),
    'startingWeightKg': startingWeightKg,
    'weeklyTargetKg': weeklyTargetKg,
    'activeLevel': activeLevel,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'baseline': baseline.toJson(),
  };

  factory Journey.fromJson(Map<String, dynamic> json) {
    return Journey(
      id: json['id'] as String,
      startDate: LocalDate.parse(json['startDate'] as String),
      startingWeightKg: (json['startingWeightKg'] as num).toDouble(),
      weeklyTargetKg: (json['weeklyTargetKg'] as num).toDouble(),
      activeLevel: json['activeLevel'] as int,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      baseline: TrendSnapshot.fromJson(
        Map<String, dynamic>.from(json['baseline'] as Map),
      ),
    );
  }
}

class WeightReading {
  const WeightReading({
    required this.id,
    required this.journeyId,
    required this.date,
    required this.kg,
    required this.recordedAt,
  });

  final String id;
  final String journeyId;
  final LocalDate date;
  final double kg;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journeyId': journeyId,
    'date': date.toIso(),
    'kg': kg,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory WeightReading.fromJson(Map<String, dynamic> json) {
    return WeightReading(
      id: json['id'] as String,
      journeyId: json['journeyId'] as String,
      date: LocalDate.parse(json['date'] as String),
      kg: (json['kg'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}

class CrossingEvent {
  const CrossingEvent({
    required this.id,
    required this.journeyId,
    required this.lineNumber,
    required this.direction,
    required this.evaluatedAt,
    required this.evaluationDate,
    required this.movingAverageKg,
    required this.lineValueKg,
    required this.resultingLevel,
    required this.sequence,
  });

  final String id;
  final String journeyId;
  final int lineNumber;
  final CrossingDirection direction;
  final DateTime evaluatedAt;
  final LocalDate evaluationDate;
  final double movingAverageKg;
  final double lineValueKg;
  final int resultingLevel;
  final int sequence;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journeyId': journeyId,
    'lineNumber': lineNumber,
    'direction': direction.name,
    'evaluatedAt': evaluatedAt.toIso8601String(),
    'evaluationDate': evaluationDate.toIso(),
    'movingAverageKg': movingAverageKg,
    'lineValueKg': lineValueKg,
    'resultingLevel': resultingLevel,
    'sequence': sequence,
  };

  factory CrossingEvent.fromJson(Map<String, dynamic> json) {
    return CrossingEvent(
      id: json['id'] as String,
      journeyId: json['journeyId'] as String,
      lineNumber: json['lineNumber'] as int,
      direction: CrossingDirection.values.byName(json['direction'] as String),
      evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
      evaluationDate: LocalDate.parse(json['evaluationDate'] as String),
      movingAverageKg: (json['movingAverageKg'] as num).toDouble(),
      lineValueKg: (json['lineValueKg'] as num).toDouble(),
      resultingLevel: json['resultingLevel'] as int,
      sequence: json['sequence'] as int,
    );
  }
}

class IdSource {
  int _next = 0;

  String next(String prefix) {
    _next += 1;
    return '$prefix-$_next';
  }
}

class WeightSlideException implements Exception {
  WeightSlideException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:convert';

import '../logic/rules.dart';
import '../models/records.dart';
import 'journey_repository.dart';

class MemoryRepository implements JourneyRepository {
  MemoryRepository({
    List<Journey>? journeys,
    List<WeightReading>? readings,
    List<CrossingEvent>? crossings,
    List<String>? rules,
  }) : _journeys = List<Journey>.of(journeys ?? const []),
       _readings = List<WeightReading>.of(readings ?? const []),
       _crossings = List<CrossingEvent>.of(crossings ?? const []),
       _rules = List<String>.of(rules ?? defaultRuleTexts);

  factory MemoryRepository.decode(String encoded) {
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    return MemoryRepository(
      journeys: [
        for (final raw in json['journeys'] as List<dynamic>)
          Journey.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      readings: [
        for (final raw in json['readings'] as List<dynamic>)
          WeightReading.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      crossings: [
        for (final raw in json['crossings'] as List<dynamic>)
          CrossingEvent.fromJson(Map<String, dynamic>.from(raw as Map)),
      ],
      rules: [for (final raw in json['rules'] as List<dynamic>) raw as String],
    );
  }

  final List<Journey> _journeys;
  final List<WeightReading> _readings;
  final List<CrossingEvent> _crossings;
  List<String> _rules;

  String encode() {
    return jsonEncode({
      'journeys': [for (final journey in _journeys) journey.toJson()],
      'readings': [for (final reading in _readings) reading.toJson()],
      'crossings': [for (final crossing in _crossings) crossing.toJson()],
      'rules': _rules,
    });
  }

  @override
  Future<Journey?> activeJourney() async {
    final active = _journeys.where((journey) => journey.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (active.isEmpty) {
      return null;
    }
    return active.first;
  }

  @override
  Future<List<Journey>> allJourneys() async {
    final copy = List<Journey>.of(_journeys)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  @override
  Future<Journey> getJourney(String id) async {
    return _journeys.firstWhere((journey) => journey.id == id);
  }

  @override
  Future<void> insertJourney(Journey journey) async {
    _journeys.add(journey);
  }

  @override
  Future<void> saveJourney(
    Journey journey, {
    List<CrossingEvent> newCrossings = const [],
  }) async {
    final index = _journeys.indexWhere((item) => item.id == journey.id);
    if (index < 0) {
      throw StateError('Unknown journey ${journey.id}');
    }
    _journeys[index] = journey;
    _crossings.addAll(newCrossings);
  }

  @override
  Future<List<WeightReading>> readingsFor(String journeyId) async {
    final readings =
        _readings.where((reading) => reading.journeyId == journeyId).toList()
          ..sort((a, b) {
            final byTime = a.recordedAt.compareTo(b.recordedAt);
            if (byTime != 0) {
              return byTime;
            }
            return a.id.compareTo(b.id);
          });
    return readings;
  }

  @override
  Future<void> insertReading(WeightReading reading) async {
    _readings.add(reading);
  }

  @override
  Future<List<CrossingEvent>> crossingsFor(String journeyId) async {
    final crossings =
        _crossings.where((event) => event.journeyId == journeyId).toList()
          ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return crossings;
  }

  @override
  Future<List<String>> rules() async => List<String>.of(_rules);

  @override
  Future<void> saveRules(List<String> rules) async {
    _rules = List<String>.of(rules);
  }
}

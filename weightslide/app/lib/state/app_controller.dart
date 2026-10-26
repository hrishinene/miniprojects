import 'package:flutter/foundation.dart';

import '../logic/history.dart';
import '../logic/rules.dart';
import '../logic/weight_series.dart';
import '../models/local_date.dart';
import '../models/records.dart';
import '../logic/journey_engine.dart';
import '../logic/validation.dart';
import '../persistence/journey_repository.dart';

class JourneyDetails {
  const JourneyDetails({
    required this.journey,
    required this.readings,
    required this.crossings,
    required this.series,
    required this.history,
  });

  final Journey journey;
  final List<WeightReading> readings;
  final List<CrossingEvent> crossings;
  final List<DailyPoint> series;
  final List<HistoryRow> history;

  DailyPoint get latest => series.last;

  List<WeightReading> readingsOn(LocalDate date) {
    return readings.where((reading) => reading.date == date).toList();
  }
}

class AppController extends ChangeNotifier {
  AppController({required this.engine, required this.repository});

  final JourneyEngine engine;
  final JourneyRepository repository;

  bool ready = false;
  bool busy = false;
  Journey? activeJourney;
  List<Journey> journeys = const [];
  List<String> ruleTexts = defaultRuleTexts;
  JourneyDetails? activeDetails;

  LocalDate get today => engine.today;

  Future<void> load() async {
    await engine.catchUp();
    await _reload();
    ready = true;
    notifyListeners();
  }

  Future<String?> startJourney({
    required double startingWeightKg,
    required LocalDate startDate,
    required double weeklyTargetKg,
  }) async {
    return _run(() async {
      await engine.createJourney(
        startingWeightKg: startingWeightKg,
        startDate: startDate,
        weeklyTargetKg: weeklyTargetKg,
      );
    });
  }

  Future<String?> enterWeight(String raw) {
    final kilograms = parseKilograms(raw);
    final error = validateWeight(kilograms);
    if (error != null) {
      return Future.value(error);
    }
    return _run(() => engine.addReading(kilograms!));
  }

  Future<String?> changeWeeklyTarget(double weeklyTargetKg) {
    return _run(() => engine.updateWeeklyTarget(weeklyTargetKg));
  }

  Future<String?> saveRules(List<String> rules) {
    return _run(() => engine.updateRules(rules));
  }

  Future<JourneyDetails> detailsFor(String journeyId) async {
    final journey = await repository.getJourney(journeyId);
    final readings = await repository.readingsFor(journeyId);
    final crossings = await repository.crossingsFor(journeyId);
    final end = journey.isActive ? today : journey.baseline.date;
    final through = end < journey.startDate ? journey.startDate : end;
    final series = WeightSeries.build(
      start: journey.startDate,
      through: through,
      startingWeightKg: journey.startingWeightKg,
      readings: readings,
    );
    final history = HistoryBuilder.build(
      journey: journey,
      readings: readings,
      crossings: crossings,
      through: through,
    );
    return JourneyDetails(
      journey: journey,
      readings: readings,
      crossings: crossings,
      series: series,
      history: history,
    );
  }

  Future<String?> _run(Future<void> Function() action) async {
    busy = true;
    notifyListeners();
    try {
      await action();
      await _reload();
      return null;
    } on WeightSlideException catch (error) {
      return error.message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _reload() async {
    journeys = await repository.allJourneys();
    ruleTexts = await repository.rules();
    activeJourney = await repository.activeJourney();
    activeDetails = activeJourney == null
        ? null
        : await detailsFor(activeJourney!.id);
  }
}

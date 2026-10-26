import '../models/records.dart';

abstract class JourneyRepository {
  Future<Journey?> activeJourney();

  Future<List<Journey>> allJourneys();

  Future<Journey> getJourney(String id);

  Future<void> insertJourney(Journey journey);

  Future<void> saveJourney(
    Journey journey, {
    List<CrossingEvent> newCrossings = const [],
  });

  Future<List<WeightReading>> readingsFor(String journeyId);

  Future<void> insertReading(WeightReading reading);

  Future<List<CrossingEvent>> crossingsFor(String journeyId);

  Future<List<String>> rules();

  Future<void> saveRules(List<String> rules);
}

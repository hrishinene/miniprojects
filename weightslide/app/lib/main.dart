import 'package:flutter/material.dart';

import 'app.dart';
import 'logic/journey_engine.dart';
import 'persistence/sqlite_repository.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await SqliteJourneyRepository.open();
  final engine = JourneyEngine(repository: repository, clock: DateTime.now);
  final controller = AppController(engine: engine, repository: repository);
  await controller.load();
  runApp(WeightSlideApp(controller: controller));
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weight_slide/app.dart';
import 'package:weight_slide/logic/journey_engine.dart';
import 'package:weight_slide/models/records.dart';
import 'package:weight_slide/persistence/memory_repository.dart';
import 'package:weight_slide/state/app_controller.dart';

void main() {
  testWidgets('setup, weight entry, graph, and history use the saved journey', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MemoryRepository();
    final engine = JourneyEngine(
      repository: repository,
      clock: () => DateTime(2026, 6, 1, 9),
      ids: IdSource(),
    );
    final controller = AppController(engine: engine, repository: repository);
    await controller.load();
    await tester.pumpWidget(WeightSlideApp(controller: controller));

    expect(find.text('Start a journey'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '92');
    await tester.ensureVisible(find.text('Create journey'));
    await tester.tap(find.text('Create journey'));
    await tester.pumpAndSettle();

    expect(find.text('Weight Slide'), findsOneWidget);
    expect(find.text('92.0 kg'), findsWidgets);
    expect(find.text('Level 3 of 5'), findsOneWidget);
    expect(find.text('Foundation'), findsOneWidget);
    expect(find.text('Sweets'), findsNothing);

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save weight'));
    await tester.pumpAndSettle();
    expect(find.text('Weight must be greater than zero.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '100');
    await tester.tap(find.text('Save weight'));
    await tester.pumpAndSettle();
    expect(find.text('100.0 kg'), findsOneWidget);
    expect(find.text('Level 5 of 5'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Planned meals'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Planned meals'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(TextField),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '101');
    await tester.tap(find.text('Save weight'));
    await tester.pumpAndSettle();
    expect(controller.activeDetails!.latest.officialKg, 100);
    expect(
      controller.activeDetails!.readingsOn(controller.today).map((reading) => reading.kg),
      [100, 101],
    );
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 600),
      2000,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('lowest'), findsOneWidget);

    await tester.tap(find.byTooltip('Graph'));
    await tester.pumpAndSettle();
    expect(find.text('Active level 5'), findsOneWidget);
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Entered'), findsOneWidget);
    expect(find.text('Level 5'), findsOneWidget);
  });
}

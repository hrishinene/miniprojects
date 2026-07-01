import 'package:flutter_test/flutter_test.dart';
import 'package:hvn_framework1/main.dart';
import 'package:hvn_framework1/service_locator.dart';

void main() {
  setUpAll(() async {
    await setupServiceLocator();
  });

  testWidgets('Dashboard shows Testdroid entry point', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Testdroid Dashboard'), findsOneWidget);
  });
}

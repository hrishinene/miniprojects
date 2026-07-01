import 'package:hvn_framework1/service/z_service_center.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';

class ZTestSuitRegistry {
  static final ZTestSuitRegistry instance = ZTestSuitRegistry._();

  ZTestSuitRegistry._();

  static ZTestSuitRegistry getInstance() => instance;

  static ZTestSuit? getTestSuit(String name) => getInstance().testSuits[name];

  static void initialize({
    required List<ZServiceCenter> services,
    required List<ZTestSuit> compoundSuits,
  }) {
    final registry = getInstance();
    registry.testSuits.clear();

    for (final service in services) {
      final suit = service.getTestSuit();
      if (suit != null) {
        registry.addTestSuit(suit);
      }
    }

    for (final suit in compoundSuits) {
      registry.addTestSuit(suit);
    }
  }

  final Map<String, ZTestSuit> testSuits = {};

  List<ZTestSuit> get testSuitsList => testSuits.values.toList();

  void addTestSuit(ZTestSuit testSuit) {
    testSuits[testSuit.name] = testSuit;
  }
}

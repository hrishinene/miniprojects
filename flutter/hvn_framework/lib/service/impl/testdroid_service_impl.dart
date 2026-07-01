import 'package:hvn_framework1/service/testdroid_service.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';
import 'package:hvn_framework1/testdroid/z_testsuit_registry.dart';

class TestdroidServiceImpl extends TestdroidService {
  @override
  List<ZTestSuit> getTestSuits() {
    return ZTestSuitRegistry.getInstance().testSuitsList;
  }

  @override
  List<ZTest> getTests(String name) {
    final suit = ZTestSuitRegistry.getTestSuit(name);
    return suit == null ? <ZTest>[] : suit.getTests();
  }
}

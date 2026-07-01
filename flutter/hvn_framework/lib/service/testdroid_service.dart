import 'package:hvn_framework1/service/z_service_center.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';

abstract class TestdroidService extends ZServiceCenter {
  List<ZTestSuit> getTestSuits();

  List<ZTest> getTests(String selectedOption);
}

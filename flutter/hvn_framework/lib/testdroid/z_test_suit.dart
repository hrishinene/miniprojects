import 'package:hvn_framework1/testdroid/z_test.dart';

abstract class ZTestSuit {
  String name, description;
  List<ZTest> tests = List<ZTest>.empty(growable: true);

  ZTestSuit(this.name, this.description);

  int getTestCount() => tests.length;
  ZTest? getTest(int indx) {
    return tests[indx];
  }

  ZTestSuit addTest(ZTest test) {
    tests.add(test);
    return this;
  }

  List<ZTest> getTests() {
    return tests;
  }
}

import 'package:hvn_framework1/testdroid/z_test_suit.dart';

/// Base type for app services. Optional [getTestSuit] feeds Testdroid auto-discovery.
abstract class ZServiceCenter {
  Future<void> init() async {}

  void destroy() {}

  ZTestSuit? getTestSuit() => null;
}

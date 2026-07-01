import 'package:flutter/material.dart';
import 'package:hvn_framework1/model/poi.dart';
import 'package:hvn_framework1/service/db_service.dart';
import 'package:hvn_framework1/service_locator.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';

class MaintenanceTestSuit extends ZTestSuit {
  MaintenanceTestSuit()
      : super('MaintenanceTestSuit', 'Local test state maintenance') {
    addTest(ResetLocalTestState());
  }
}

class ResetLocalTestState extends ZTest {
  ResetLocalTestState()
      : super('Reset local state', 'Clear local DB and cached test data');

  @override
  void doExecute(BuildContext context) {
    getIt<DBService>().deleteAll(POI);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Local test state cleared (server data untouched).'),
        duration: Duration(seconds: 3),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hvn_framework1/model/poi.dart';
import 'package:hvn_framework1/service/db_service.dart';
import 'package:hvn_framework1/service_locator.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';

class DBTestSuit extends ZTestSuit {
  DBTestSuit() : super('DBTestSuit', 'Test suit to test DB Service') {
    addTest(SaveSamplePoiTest());
    addTest(QueryDbTest());
    addTest(ResetDbTest());
  }
}

class SaveSamplePoiTest extends ZTest {
  SaveSamplePoiTest() : super('Save sample POI', 'Insert a hardcoded POI');

  @override
  void doExecute(BuildContext context) {
    getIt<DBService>().insertOne(
      POI(18.52, 73.85, 'Sample POI from DB test suit'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample POI saved.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class QueryDbTest extends ZTest {
  QueryDbTest() : super('Query DB', 'List all POIs to debug console');

  @override
  void doExecute(BuildContext context) async {
    final pois = await getIt<DBService>().fetchSimple<POI>('1 = 1', POI);
    for (final poi in pois) {
      debugPrint('POI - $poi');
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Found ${pois.length} POI(s). See debug console.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class ResetDbTest extends ZTest {
  ResetDbTest() : super('Reset DB', 'Delete all POIs from local DB');

  @override
  void doExecute(BuildContext context) {
    getIt<DBService>().deleteAll(POI);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All POIs deleted from local DB.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

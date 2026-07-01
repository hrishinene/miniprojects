import 'package:get_it/get_it.dart';
import 'package:hvn_framework1/service/api_service.dart';
import 'package:hvn_framework1/service/db_service.dart';
import 'package:hvn_framework1/service/impl/api_service_impl.dart';
import 'package:hvn_framework1/service/impl/db_service_impl.dart';
import 'package:hvn_framework1/service/impl/location_service_impl.dart';
import 'package:hvn_framework1/service/impl/testdroid_service_impl.dart';
import 'package:hvn_framework1/service/impl/tts_service_impl.dart';
import 'package:hvn_framework1/service/location_service.dart';
import 'package:hvn_framework1/service/testdroid_service.dart';
import 'package:hvn_framework1/service/tts_service.dart';
import 'package:hvn_framework1/service/z_service_center.dart';
import 'package:hvn_framework1/testdroid/z_testsuit_registry.dart';
import 'package:hvn_framework1/testsuit/maintenance_suit.dart';
import 'package:hvn_framework1/testsuit/pincode_suite.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final services = <ZServiceCenter>[];

  final apiService = ApiServiceImpl();
  getIt.registerSingleton<ApiService>(apiService);
  services.add(apiService);

  final dbService = DBServiceImpl();
  getIt.registerSingleton<DBService>(dbService);
  services.add(dbService);
  await dbService.init();

  final ttsService = TTSServiceImpl();
  getIt.registerSingleton<TTSService>(ttsService);
  services.add(ttsService);
  await ttsService.init();

  final locationService = LocationServiceImpl();
  getIt.registerSingleton<LocationService>(locationService);
  services.add(locationService);
  await locationService.init();

  final testdroidService = TestdroidServiceImpl();
  getIt.registerSingleton<TestdroidService>(testdroidService);
  services.add(testdroidService);

  ZTestSuitRegistry.initialize(
    services: services,
    compoundSuits: [
      PincodeTestSuit(),
      MaintenanceTestSuit(),
    ],
  );
}

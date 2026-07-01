import 'package:geolocator/geolocator.dart';
import 'package:hvn_framework1/model/geo_position.dart';
import 'package:hvn_framework1/service/location_service.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';
import 'package:hvn_framework1/testsuit/location_suit.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationServiceImpl extends LocationService {
  @override
  ZTestSuit? getTestSuit() => LocationTestSuit();

  @override
  Future<GeoPosition?> getCurrentPosition() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return GeoPosition(position.latitude, position.longitude);
  }
}

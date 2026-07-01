import 'package:hvn_framework1/model/geo_position.dart';
import 'package:hvn_framework1/service/z_service_center.dart';

abstract class LocationService extends ZServiceCenter {
  Future<GeoPosition?> getCurrentPosition();
}

import 'package:hvn_framework1/util/geo/geo_tile.dart';

class GeoBoundingBox {
  late GeoTile lowerLeft, upperRight;
  GeoBoundingBox(this.lowerLeft, this.upperRight);
  GeoBoundingBox.fromCenter(GeoTile center, double boxSizeMeters) {
    // Go by rough estimation of 10 meters = 0.0001 lat or lng
    double offset = 0.0001 * boxSizeMeters / 10.0;
    lowerLeft = GeoTile(center.latitude - offset, center.longitude - offset);
    upperRight = GeoTile(center.latitude + offset, center.longitude + offset);
  }
}

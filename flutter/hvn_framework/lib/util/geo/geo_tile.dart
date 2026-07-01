import 'dart:math';

class GeoTile {
  double latitude, longitude;
  GeoTile(this.latitude, this.longitude);

  double getDistanceFrom(GeoTile other) {
    // Checkout google for Dart code for distance
    return calculateDistance(
        latitude, longitude, other.latitude, other.longitude);
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Earth radius in kilometers

    // Convert latitude and longitude from degrees to radians
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    // Haversine formula
    double a = pow(sin(dLat / 2), 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Distance in kilometers
    double distance = earthRadius * c;
    return distance * 1000;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
}

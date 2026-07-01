import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hvn_framework1/core/navigation.dart';
import 'package:hvn_framework1/service/location_service.dart';
import 'package:hvn_framework1/service_locator.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';

class LocationTestSuit extends ZTestSuit {
  LocationTestSuit()
      : super('LocationTestSuit', 'Test suit to test Location Service') {
    addTest(CurrentLocationTest());
    addTest(PlotOnMapTest());
  }
}

class CurrentLocationTest extends ZTest {
  CurrentLocationTest()
      : super('Current Location', 'Display Current location');

  @override
  void doExecute(BuildContext context) async {
    final position = await getIt<LocationService>().getCurrentPosition();

    final lat = position?.latitude.toString() ?? 'Unknown';
    final lng = position?.longitude.toString() ?? 'Unknown';

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Latitude: $lat, Longitude: $lng'),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class PlotOnMapTest extends ZTest {
  PlotOnMapTest() : super('Map Test', 'Location Plot on Map');

  @override
  void doExecute(BuildContext context) {
    pushPage(context, const MapPage());
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  LatLng _center = const LatLng(18.52, 73.85);
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.add(
      Marker(markerId: MarkerId(_center.toString()), position: _center),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
        markers: _markers,
        onLongPress: (argument) {
          debugPrint(
            'Long Press at: ${argument.latitude}, ${argument.longitude}',
          );
        },
        onTap: (argument) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(argument.toString()),
                position: argument,
              ),
            );
            _center = argument;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Clicked on: $argument'),
              duration: const Duration(seconds: 3),
            ),
          );
          _mapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _center, zoom: 11),
            ),
          );
        },
      ),
    );
  }
}

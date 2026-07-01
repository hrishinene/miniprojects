import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hvn_framework1/core/navigation.dart';
import 'package:hvn_framework1/model/poi.dart';
import 'package:hvn_framework1/service/db_service.dart';
import 'package:hvn_framework1/service/tts_service.dart';
import 'package:hvn_framework1/service_locator.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';
import 'package:hvn_framework1/util/geo/geo_bounding_box.dart';
import 'package:hvn_framework1/util/geo/geo_tile.dart';

GeoTile sinhagad = GeoTile(18.21, 73.45);
GeoTile shaniwarWada = GeoTile(18.52, 73.85);
GeoTile dhule = GeoTile(20.90, 74.77);

class PincodeTestSuit extends ZTestSuit {
  PincodeTestSuit()
      : super(
          'PincodeTestSuit',
          'Test Pincode functionality with hardcoded and random values',
        ) {
    addTest(AddPinTest1());
    addTest(AddPinTest2());
    addTest(ListPOIsTest());
    addTest(NearSinhagadTest());
    addTest(NearShaniwarWadaTest());
    addTest(NearDhule());
    addTest(RemoveAllPOIsTest());
    addTest(PincodeAppTest());
  }
}

abstract class AddPinTest extends ZTest {
  final double latitude;
  final double longitude;
  final String message;

  AddPinTest(
    super.name,
    super.description,
    this.latitude,
    this.longitude,
    this.message,
  );

  @override
  void doExecute(BuildContext context) {
    getIt<DBService>().insertOne(POI(latitude, longitude, message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved POI: $name')),
    );
  }
}

class AddPinTest1 extends AddPinTest {
  AddPinTest1()
      : super(
          'Shaniwarwada',
          'Shaniwar Wada',
          shaniwarWada.latitude,
          shaniwarWada.longitude,
          'Shaniwar Wada is a historical fortification in the city of Pune, India.',
        );
}

class AddPinTest2 extends AddPinTest {
  AddPinTest2()
      : super(
          'Sinhagad',
          'Sinhagad',
          sinhagad.latitude,
          sinhagad.longitude,
          'Sinhagad is an ancient hill fortress near Pune, India.',
        );
}

abstract class PinMessageTest extends ZTest {
  final double latitude;
  final double longitude;

  PinMessageTest(super.name, super.description, this.latitude, this.longitude);

  @override
  void doExecute(BuildContext context) async {
    final dbService = getIt<DBService>();
    final box = GeoBoundingBox.fromCenter(
      GeoTile(latitude, longitude),
      1000,
    );
    final pois = await dbService.fetchSimple<POI>(
      'latitude > ${box.lowerLeft.latitude} and latitude < ${box.upperRight.latitude} and longitude > ${box.lowerLeft.longitude} and longitude < ${box.upperRight.longitude}',
      POI,
    );

    POI? nearest;
    var distanceMeters = 1000;
    for (final poi in pois) {
      final d = poi.getDistanceFrom(GeoTile(latitude, longitude));
      if (d < distanceMeters) {
        nearest = poi;
        distanceMeters = d.toInt();
      }
    }

    final ttsService = getIt<TTSService>();
    if (nearest == null) {
      ttsService.playMessage(
        'Sorry! Could not find any point of interest near you',
      );
      return;
    }

    ttsService.playMessage(
      'Here is a point of interest nearby. It is only $distanceMeters meters from you. ${nearest.information}',
    );
  }
}

class NearSinhagadTest extends PinMessageTest {
  NearSinhagadTest()
      : super(
          'Near Sinhagad',
          'Message for location near Sinhagad',
          sinhagad.latitude + 0.001,
          sinhagad.longitude - 0.0002,
        );
}

class NearShaniwarWadaTest extends PinMessageTest {
  NearShaniwarWadaTest()
      : super(
          'Near Shaniwar Wada',
          'Message for location near Shaniwar Wada',
          shaniwarWada.latitude - 0.002,
          shaniwarWada.longitude + 0.0004,
        );
}

class NearDhule extends PinMessageTest {
  NearDhule()
      : super(
          'Near Dhule',
          'Message for location near Dhule',
          dhule.latitude,
          dhule.longitude,
        );
}

class ListPOIsTest extends ZTest {
  ListPOIsTest() : super('List POIs', 'List POIs');

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
      SnackBar(content: Text('Listed ${pois.length} POI(s) in debug console.')),
    );
  }
}

class RemoveAllPOIsTest extends ZTest {
  RemoveAllPOIsTest() : super('Remove POIs', 'Remove All POIs');

  @override
  void doExecute(BuildContext context) {
    getIt<DBService>().deleteAll(POI);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All POIs removed.')),
    );
  }
}

class PincodeAppTest extends ZTest {
  PincodeAppTest() : super('Pincode MVP', 'Pincode MVP with basic');

  @override
  void doExecute(BuildContext context) {
    pushPage(context, const PincodeMapPage());
  }
}

class PincodeMapPage extends StatefulWidget {
  const PincodeMapPage({super.key});

  @override
  State<PincodeMapPage> createState() => _PincodeMapPageState();
}

class _PincodeMapPageState extends State<PincodeMapPage> {
  late Completer<void> _loadingCompleter;
  final Set<Marker> _markers = {};
  final LatLng _center = const LatLng(18.52, 73.85);

  @override
  void initState() {
    super.initState();
    _loadingCompleter = Completer<void>();
    _loadData();
  }

  Future<void> _loadData() async {
    final pois = await getIt<DBService>().fetchSimple<POI>('1 = 1', POI);

    _markers.clear();
    for (final poi in pois) {
      final pos = LatLng(poi.latitude, poi.longitude);
      _markers.add(Marker(markerId: MarkerId(pos.toString()), position: pos));
    }

    if (!_loadingCompleter.isCompleted) {
      _loadingCompleter.complete();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pincode')),
      body: FutureBuilder<void>(
        future: _loadingCompleter.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GoogleMap(
              onMapCreated: (_) {},
              initialCameraPosition: CameraPosition(target: _center, zoom: 11),
              markers: _markers,
              onLongPress: (argument) async {
                await pushPage(
                  context,
                  PincodePage(
                    latitude: argument.latitude,
                    longitude: argument.longitude,
                  ),
                );
                await _loadData();
              },
              onTap: (argument) async {
                await _playInformation(
                  GeoTile(argument.latitude, argument.longitude),
                );
                setState(() {});
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<POI?> _getNearestPOI(
    GeoTile loc,
    double distanceThresholdMeters,
  ) async {
    final box = GeoBoundingBox.fromCenter(loc, distanceThresholdMeters);
    final pois = await getIt<DBService>().fetchSimple<POI>(
      'latitude > ${box.lowerLeft.latitude} and latitude < ${box.upperRight.latitude} and longitude > ${box.lowerLeft.longitude} and longitude < ${box.upperRight.longitude}',
      POI,
    );

    POI? nearest;
    var distanceMeters = distanceThresholdMeters.toInt();
    for (final poi in pois) {
      final d = poi.getDistanceFrom(loc);
      if (d < distanceMeters) {
        nearest = poi;
        distanceMeters = d.toInt();
      }
    }
    return nearest;
  }

  Future<void> _playInformation(GeoTile geoTile) async {
    final nearest = await _getNearestPOI(geoTile, 10000);
    final ttsService = getIt<TTSService>();
    if (nearest == null) {
      ttsService.playMessage(
        'Sorry! Could not find any point of interest near you',
      );
      return;
    }

    final distanceMeters = nearest.getDistanceFrom(geoTile).toInt();
    ttsService.playMessage(
      'Here is a point of interest nearby. It is only $distanceMeters meters from you. ${nearest.information}',
    );
  }
}

class PincodePage extends StatefulWidget {
  final double latitude;
  final double longitude;

  const PincodePage({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PincodePage> createState() => _PincodePageState();
}

class _PincodePageState extends State<PincodePage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pincode')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: 'Type your text here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                getIt<DBService>().insertOne(
                  POI(widget.latitude, widget.longitude, _textController.text),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

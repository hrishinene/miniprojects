import 'package:hvn_framework1/model/z_dbpojo.dart';
import 'package:hvn_framework1/util/geo/geo_tile.dart';
import 'package:sqflite/sqflite.dart';

class POI extends ZDBPojo {
  double latitude, longitude;
  String information;

  POI(this.latitude, this.longitude, this.information);
  POI.fromId(String id, this.latitude, this.longitude, this.information)
      : super.fromID(id);

  @override
  String toString() {
    return "POI { id = $id, latitude = $latitude, longitude = $longitude, information = $information}";
  }

  @override
  POI save() {
    // insert into DB
    return this;
  }

//  ----------------------------------------------
//  OR methods to perform DB operations
//  ----------------------------------------------
  static Future<void> createTable(Database db) {
    return db.execute('''
        CREATE TABLE POI (
          id TEXT PRIMARY KEY,
          latitude DOUBLE,
          longitude DOUBLE,
          information TEXT
        )
      ''');
  }

  static Future<void> insertObjects(Database db, List<ZDBPojo> objs) {
    // insert POIs into Table
    return db.transaction((txn) async {
      for (ZDBPojo obj in objs) {
        POI poi = obj as POI;

        int rowId = await txn.rawInsert(
            'INSERT INTO POI(id, latitude, longitude, information) VALUES("${poi.id}", "${poi.latitude}", "${poi.longitude}", "${poi.information}")');
        print('Inserted row id: $rowId');
      }
    });
  }

  // Future<void> _queryData() async {
  // Query the database
  // List<Map<String, dynamic>> results =
  // await _database.rawQuery('SELECT * FROM example');

  // Print the results
  // results.forEach((row) {
  // print('ID: ${row['id']}, Name: ${row['name']}, Age: ${row['age']}');
  // });
  // }

  static Future<List<ZDBPojo>> executeQuery(
      Database db, String whereClause) async {
    List<ZDBPojo> returnList = [];

    List<Map<String, dynamic>> results =
        await db.rawQuery('SELECT * FROM POI WHERE $whereClause');
    for (var poi in results) {
      returnList.add(POI.fromId(
          poi['id'], poi['latitude'], poi['longitude'], poi['information']));
    }

    return returnList;
  }

  static ZDBPojo executeIDQuery(String id) {
    throw UnimplementedError();
  }

  static void deleteOne(String id) {
    throw UnimplementedError();
  }

  static Future<void> deleteAll(Database db) async {
    await db.execute('DELETE FROM POI');
  }

  static ZDBPojoFactory getFactory() {
    return ZDBPojoFactory(createTable, insertObjects, executeQuery,
        executeIDQuery, deleteOne, deleteAll);
  }

  double getDistanceFrom(GeoTile geoTile) {
    return GeoTile(latitude, longitude).getDistanceFrom(geoTile);
  }
}

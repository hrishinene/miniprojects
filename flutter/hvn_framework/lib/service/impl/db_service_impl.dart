import 'package:hvn_framework1/model/z_dbpojo.dart';
import 'package:hvn_framework1/service/db_service.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';
import 'package:hvn_framework1/testsuit/db_suit.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBServiceImpl extends DBService {
  late Database _database;

  @override
  ZTestSuit? getTestSuit() => DBTestSuit();

  @override
  Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'example.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        for (final factory in ZDBRegistry.instance.dbRegistryMap.values) {
          await factory.creator(db);
        }
      },
    );
  }

  @override
  void deleteAll(Type objectType) {
    final factory = ZDBRegistry.instance.getFactory(objectType);
    if (factory == null) {
      return;
    }

    factory.deleterAll(_database);
  }

  @override
  void deleteMany(List<ZDBPojo> obj) {
    // TODO: implement deleteMany
  }

  @override
  void deleteOne(ZDBPojo obj) {
    // TODO: implement deleteOne
  }

  @override
  T? fetchById<T extends ZDBPojo>(String id, Type objectType) {
    return null;
  }

  @override
  List<T> fetchRaw<T extends ZDBPojo>(String rawQuery, Type objectType) {
    throw UnimplementedError();
  }

  @override
  Future<List<T>> fetchSimple<T extends ZDBPojo>(
    String whereCondition,
    Type objectType,
  ) async {
    final factory = ZDBRegistry.instance.getFactory(objectType);
    if (factory == null) {
      return [];
    }

    final results = await factory.queryExecutor(_database, whereCondition);
    return results.cast<T>();
  }

  @override
  void insertMany(List<ZDBPojo> objs) {
    if (objs.isEmpty) {
      return;
    }

    final factory =
        ZDBRegistry.instance.getFactory(objs.first.runtimeType);
    if (factory == null) {
      return;
    }

    factory.inserter(_database, objs);
  }

  @override
  void insertOne(ZDBPojo obj) {
    insertMany([obj]);
  }
}

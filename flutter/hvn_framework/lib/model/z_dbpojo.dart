import 'dart:core';

import 'package:hvn_framework1/model/poi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// DB Modelled Object class
abstract class ZDBPojo {
  String id; // UUID
  ZDBPojo.fromID(this.id);
  ZDBPojo() : this.fromID(const Uuid().v4());

  ZDBPojo save();
}

typedef TableCreator = Future<void> Function(Database db);
typedef Inserter = Future<void> Function(Database db, List<ZDBPojo> objs);
typedef QueryExecutor = Future<List<ZDBPojo>> Function(
    Database db, String whereClause);
typedef QueryExecutorWithId = ZDBPojo Function(String id);
typedef DeleterOne = Function(String id);
typedef DeleterAll = Future<void> Function(Database db);

/// Abstract factory to manage DB Pojos
class ZDBPojoFactory {
  TableCreator creator;
  Inserter inserter;
  QueryExecutor queryExecutor;
  QueryExecutorWithId queryExecutorWithId;
  DeleterOne deleterOne;
  DeleterAll deleterAll;

  ZDBPojoFactory(this.creator, this.inserter, this.queryExecutor,
      this.queryExecutorWithId, this.deleterOne, this.deleterAll);

  List<T> executeQuery<T extends ZDBPojo>(String whereCondition) {
    return executeQuery(whereCondition);
  }
}

class ZDBRegistry {
  Map<Type, ZDBPojoFactory> dbRegistryMap = {};

  static ZDBRegistry get instance => ZDBRegistry();

  ZDBRegistry() {
    // Add the items to map
    dbRegistryMap.putIfAbsent(POI, POI.getFactory);
  }

  ZDBPojoFactory? getFactory(Type type) {
    return dbRegistryMap[type];
  }
}

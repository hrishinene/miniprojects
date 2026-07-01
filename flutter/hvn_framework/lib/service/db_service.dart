import 'package:hvn_framework1/model/z_dbpojo.dart';
import 'package:hvn_framework1/service/z_service_center.dart';

abstract class DBService extends ZServiceCenter {
  void insertOne(ZDBPojo obj);
  void insertMany(List<ZDBPojo> obj);

  void deleteOne(ZDBPojo obj);
  void deleteMany(List<ZDBPojo> obj);
  void deleteAll(Type dbObjectType);

  T? fetchById<T extends ZDBPojo>(String id, Type dbPojoType);
  Future<List<T>> fetchSimple<T extends ZDBPojo>(
    String whereCondition,
    Type dbPojoType,
  );
  List<T> fetchRaw<T extends ZDBPojo>(String rawQuery, Type dbPojoType);
}

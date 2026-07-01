import 'package:hvn_framework1/service/z_service_center.dart';

/// Single HTTP entry point for domain services. Stub for template use.
abstract class ApiService extends ZServiceCenter {
  Future<Map<String, dynamic>> get(String path);

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body);
}

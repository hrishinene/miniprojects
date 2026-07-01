import 'package:hvn_framework1/service/api_service.dart';

class ApiServiceImpl extends ApiService {
  @override
  Future<Map<String, dynamic>> get(String path) async {
    throw UnimplementedError('ApiService.get not configured: $path');
  }

  @override
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    throw UnimplementedError('ApiService.post not configured: $path');
  }
}

import 'package:hvn_framework1/service/z_service_center.dart';

abstract class TTSService extends ZServiceCenter {
  void playMessage(String message);

  Future<void> speak(String message);
}

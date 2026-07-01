import 'package:flutter_tts/flutter_tts.dart';
import 'package:hvn_framework1/service/tts_service.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';
import 'package:hvn_framework1/testsuit/audio_tts_suit.dart';

class TTSServiceImpl extends TTSService {
  late FlutterTts _flutterTts;

  @override
  ZTestSuit? getTestSuit() => AudioTTSTestSuit();

  @override
  Future<void> init() async {
    _flutterTts = FlutterTts();
  }

  @override
  void destroy() {
    _flutterTts.stop();
  }

  @override
  void playMessage(String message) {
    speak(message);
  }

  @override
  Future<void> speak(String message) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.speak(message);
  }
}

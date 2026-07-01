import 'package:flutter/material.dart';
import 'package:hvn_framework1/core/navigation.dart';
import 'package:hvn_framework1/service/tts_service.dart';
import 'package:hvn_framework1/service_locator.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/testdroid/z_test_suit.dart';

class AudioTTSTestSuit extends ZTestSuit {
  AudioTTSTestSuit()
      : super('AudioTTSTestSuit', 'Test suit to test Text to Speech Service') {
    addTest(PlayHardcodedTtsTest());
    addTest(TTSTest());
  }
}

class PlayHardcodedTtsTest extends ZTest {
  PlayHardcodedTtsTest()
      : super('Play sample TTS', 'Speak a hardcoded sample message');

  @override
  void doExecute(BuildContext context) {
    getIt<TTSService>().playMessage('Testdroid TTS sample message.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing sample TTS message.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class TTSTest extends ZTest {
  TTSTest() : super('Play Text using TTS', 'Play audio from the textbox');

  @override
  void doExecute(BuildContext context) {
    pushPage(context, const TTSPage());
  }
}

class TTSPage extends StatefulWidget {
  const TTSPage({super.key});

  @override
  State<TTSPage> createState() => _TTSPageState();
}

class _TTSPageState extends State<TTSPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Text to Speech')),
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
                getIt<TTSService>().speak(_textController.text);
              },
              child: const Text('Play'),
            ),
          ],
        ),
      ),
    );
  }
}

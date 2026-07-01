import 'dart:ui';
import 'dart:math';

import 'package:hvn_framework1/util/pair.dart';

/// class with static utility functions
class Utils {
  static Pair<Color, Color> getRandomColor(String seed) {
    final Random random = Random(seed.hashCode);
    final int red = random.nextInt(256);
    final int redBack = 255 - red;
    final int green = random.nextInt(256);
    final int greenBack = 255 - green;
    final int blue = random.nextInt(256);
    final int blueBack = 255 - blue;

    return Pair(Color.fromARGB(255, red, green, blue),
        Color.fromARGB(255, redBack, greenBack, blueBack));
  }
}

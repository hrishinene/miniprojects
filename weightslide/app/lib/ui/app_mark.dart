import 'package:flutter/material.dart';

/// Five descending reference lines, the same mark used for the app icon.
class AppMark extends StatelessWidget {
  const AppMark({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppMarkPainter(size)),
    );
  }
}

class _AppMarkPainter extends CustomPainter {
  const _AppMarkPainter(this.size);

  final double size;

  static const Color ink = Color(0xFF2C4A3E);

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 5; index++) {
      final offset = (index - 2) * 0.08 * shortest;
      stroke.strokeWidth = (index == 2 ? 0.038 : 0.03) * shortest;
      canvas.drawLine(
        Offset(0.32 * shortest, 0.42 * shortest + offset),
        Offset(0.68 * shortest, 0.58 * shortest + offset),
        stroke,
      );
    }
    canvas.drawCircle(
      Offset(0.579 * shortest, 0.535 * shortest),
      0.055 * shortest,
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _AppMarkPainter oldDelegate) {
    return oldDelegate.size != size;
  }
}

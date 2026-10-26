import 'package:flutter/material.dart';

import 'state/app_controller.dart';
import 'ui/dashboard_screen.dart';
import 'ui/setup_screen.dart';
import 'ui/theme.dart';

class WeightSlideApp extends StatelessWidget {
  const WeightSlideApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight Slide',
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (!controller.ready) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.activeJourney == null) {
            return SetupScreen(controller: controller);
          }
          return DashboardScreen(controller: controller);
        },
      ),
    );
  }
}

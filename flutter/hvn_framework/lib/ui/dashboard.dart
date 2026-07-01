import 'package:flutter/material.dart';
import 'package:hvn_framework1/core/navigation.dart';
import 'package:hvn_framework1/ui/testdroid.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => pushPage(context, const TestdroidPage()),
          child: const Text('Testdroid Dashboard'),
        ),
      ),
    );
  }
}

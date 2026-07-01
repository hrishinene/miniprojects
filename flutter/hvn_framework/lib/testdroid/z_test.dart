import 'package:flutter/material.dart';

abstract class ZTest {
  String name, description;

  ZTest(this.name, this.description);

  void execute(BuildContext context) {
    doExecute(context);
  }

  void doExecute(BuildContext context);
}

class ZDefaultTest extends ZTest {
  ZDefaultTest(super.name, super.description);

  static ZTest TheTest(String identifier) =>
      ZDefaultTest(identifier, identifier);

  @override
  void doExecute(BuildContext context) {
    // Default implementation of execute is to show a snackbar
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name:$description"),
        duration: const Duration(seconds: 3), // Control how long it's displayed
      ),
    );
  }
}

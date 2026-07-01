import 'package:flutter/material.dart';

Future<T?> pushPage<T>(BuildContext context, Widget page) {
  return Navigator.push<T>(
    context,
    MaterialPageRoute(builder: (_) => page),
  );
}

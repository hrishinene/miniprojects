import 'package:flutter/material.dart';
import 'package:hvn_framework1/service/testdroid_service.dart';
import 'package:hvn_framework1/service_locator.dart';
import 'package:hvn_framework1/testdroid/z_test.dart';
import 'package:hvn_framework1/util/utils.dart';

class TestdroidPage extends StatefulWidget {
  const TestdroidPage({super.key});

  @override
  State<TestdroidPage> createState() => _TestdroidPageState();
}

class _TestdroidPageState extends State<TestdroidPage> {
  final List<String> _dropdownItems = [];
  String _selectedOption = '';
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    final svc = getIt<TestdroidService>();
    for (final testSuit in svc.getTestSuits()) {
      _dropdownItems.add(testSuit.name);
      _selectedOption = testSuit.name;
    }
  }

  List<ZTest> get _tests {
    return getIt<TestdroidService>().getTests(_selectedOption);
  }

  @override
  Widget build(BuildContext context) {
    if (_dropdownItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Testdroid')),
        body: const Center(child: Text('No test suites registered.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Testdroid')),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedOption,
            onChanged: (String? newValue) {
              setState(() {
                _selectedOption = newValue!;
              });
            },
            items: _dropdownItems.map((val) {
              return DropdownMenuItem<String>(
                value: val,
                child: Text(val),
              );
            }).toList(),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: _tests.length,
              itemBuilder: (BuildContext context, int index) {
                final colorPair = Utils.getRandomColor(_selectedOption);
                final foreground = colorPair.first;
                final background = colorPair.second;

                return GestureDetector(
                  onTap: () => _tests[index].execute(context),
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  child: Container(
                    color: _isPressed ? foreground : background,
                    margin: const EdgeInsets.all(10.0),
                    alignment: Alignment.center,
                    child: Text(
                      _tests[index].name,
                      style: TextStyle(
                        color: _isPressed ? background : foreground,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

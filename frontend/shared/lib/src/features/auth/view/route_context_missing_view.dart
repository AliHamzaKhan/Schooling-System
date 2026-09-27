import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Safe recovery for a legacy detail URL whose record existed only in memory.
class RouteContextMissingView extends StatelessWidget {
  const RouteContextMissingView({super.key, required this.returnRoute});
  final String returnRoute;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Open the record again')),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('This link is missing its record details. Return to the list and select the record again.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => Get.offAllNamed(returnRoute), child: const Text('Return to list')),
      ],
    ))),
  );
}

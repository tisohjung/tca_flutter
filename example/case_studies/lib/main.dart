import 'package:flutter/material.dart';

import '00_root_view.dart';

void main() {
  runApp(const CaseStudiesApp());
}

class CaseStudiesApp extends StatelessWidget {
  const CaseStudiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCA Case Studies',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RootView(),
    );
  }
}

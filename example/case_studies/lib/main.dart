import 'package:case_studies/basics.dart';
import 'package:case_studies/basics_view.dart';
import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeView(),
    );
  }
}

// List of buttons that connects to detail examples
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Studies'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BasicsView(
                  store: Store<BasicsState, BasicsAction>(
                initialState: BasicsState(),
                reducer: BasicsReducer(),
              )),
            ),
          ),
          child: const Text('Basics'),
        ),
      ),
    );
  }
}

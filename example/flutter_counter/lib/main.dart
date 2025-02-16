// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_counter/counter_action.dart';
import 'package:flutter_counter/counter_store.dart';
import 'package:flutter_counter/favorites_action.dart';
import 'package:tca_flutter/tca_flutter.dart';

void main() {
  final store = Store<CounterState, CounterAction>(
    initialState: CounterState(),
    reducer: CounterReducer().debug(
      prefix: '[Counter] ', // Optional prefix for the debug output
    ),
  );

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<CounterState, CounterAction> store;

  const MyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      darkTheme: ThemeData.dark(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CounterView(store: store),
    );
  }
}

class CounterView extends StatelessWidget {
  final Store<CounterState, CounterAction> store;

  const CounterView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Demo'),
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${store.state.count}'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          store.send(const CounterDecrementAction()),
                      child: const Text('-'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => store.send(const CounterResetAction()),
                      child: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () =>
                          store.send(const CounterIncrementAction()),
                      child: const Text('+'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => store.send(CounterFavoritesAction(
                        FavoritesAddAction(store.state.count),
                      )),
                      child: const Text('⭐'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FavoritesView extends StatelessWidget {
  final Store<CounterState, CounterAction> store;

  const FavoritesView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Demo'),
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${store.state.count}'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          store.send(const CounterDecrementAction()),
                      child: const Text('-'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => store.send(const CounterResetAction()),
                      child: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () =>
                          store.send(const CounterIncrementAction()),
                      child: const Text('+'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

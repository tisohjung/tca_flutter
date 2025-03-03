import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

import 'basics.dart';

class BasicsView extends StatelessWidget {
  final Store<BasicsState, BasicsAction> store;

  const BasicsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${store.state.count}'),
                if (store.state.isLoading)
                  const CircularProgressIndicator()
                else if (store.state.fact != null)
                  Text(store.state.fact!),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => store.send(BasicsAction.decrement),
                      child: const Text('-'),
                    ),
                    FilledButton(
                      onPressed: () => store.send(BasicsAction.increment),
                      child: const Text('+'),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: () => store.send(BasicsAction.factRequest),
                  child: const Text('Get Fact'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

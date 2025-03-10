import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class EffectsBasicsState {
  int count;
  String? fact;
  bool isLoading;

  EffectsBasicsState({
    this.count = 0,
    this.fact,
    this.isLoading = false,
  });

  @override
  String toString() =>
      'EffectsBasicsState(count: $count, fact: $fact, isLoading: $isLoading)';
}

// Actions
sealed class EffectsBasicsAction {
  const EffectsBasicsAction();
}

final class EffectsBasicsIncrement extends EffectsBasicsAction {
  const EffectsBasicsIncrement();
}

final class EffectsBasicsDecrement extends EffectsBasicsAction {
  const EffectsBasicsDecrement();
}

final class EffectsBasicsFactRequest extends EffectsBasicsAction {
  const EffectsBasicsFactRequest();
}

final class EffectsBasicsFactResponse extends EffectsBasicsAction {
  final String fact;
  const EffectsBasicsFactResponse(this.fact);
}

// Feature
class EffectsBasics {
  static final reducer =
      Reducer<EffectsBasicsState, EffectsBasicsAction>((state, action) {
    switch (action) {
      case EffectsBasicsIncrement():
        state.count++;
        return Effect.none();
      case EffectsBasicsDecrement():
        state.count--;
        return Effect.none();
      case EffectsBasicsFactRequest():
        state.isLoading = true;
        state.fact = null;
        final effectId = "factRequest";
        return Effect.publisher<EffectsBasicsAction>((send) async {
          final task = TaskManager.instance.getTask(effectId);
          await task.delay(const Duration(seconds: 1));
          if (!task.isCancelled) {
            send(EffectsBasicsFactResponse('Fact about ${state.count}'));
          }
        }).cancellable(id: effectId);
      case EffectsBasicsFactResponse(fact: final fact):
        state.fact = fact;
        state.isLoading = false;
        return Effect.none();
    }
  });

  // Action creators
  static const increment = EffectsBasicsIncrement();
  static const decrement = EffectsBasicsDecrement();
  static const factRequest = EffectsBasicsFactRequest();
}

// MARK: - Feature view

class EffectsBasicsView extends StatelessWidget {
  final Store<EffectsBasicsState, EffectsBasicsAction> store;

  const EffectsBasicsView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Effects Demo')),
      body: Center(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${store.state.count}',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                if (store.state.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                else if (store.state.fact != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(store.state.fact!),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () => store.send(EffectsBasics.decrement),
                      child: const Text('-'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => store.send(EffectsBasics.increment),
                      child: const Text('+'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => store.send(EffectsBasics.factRequest),
                  child: const Text('Get Fact'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

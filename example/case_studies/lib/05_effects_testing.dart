import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class EffectsTestingState {
  int count;
  String? fact;
  bool isLoading;

  EffectsTestingState({
    this.count = 0,
    this.fact,
    this.isLoading = false,
  });

  @override
  String toString() =>
      'EffectsTestingState(count: $count, fact: $fact, isLoading: $isLoading)';
}

// Actions
sealed class EffectsTestingAction {
  const EffectsTestingAction();
}

// Cancel IDs for effects
enum CancelID {
  factRequest,
}

final class FactButtonTapped extends EffectsTestingAction {
  const FactButtonTapped();
}

final class CancelButtonTapped extends EffectsTestingAction {
  const CancelButtonTapped();
}

final class FactResponse extends EffectsTestingAction {
  final String fact;
  const FactResponse(this.fact);
}

final class IncrementButtonTapped extends EffectsTestingAction {
  const IncrementButtonTapped();
}

final class DecrementButtonTapped extends EffectsTestingAction {
  const DecrementButtonTapped();
}

// Dependencies
class NumberFactClient {
  final Future<String> Function(int number) fetch;

  const NumberFactClient({required this.fetch});

  // Live implementation that would make real API calls
  static NumberFactClient live = NumberFactClient(
    fetch: (number) async {
      // In a real app, this would make an HTTP request
      await Future.delayed(const Duration(seconds: 1));
      return 'Fact about $number: This is a number!';
    },
  );

  // Mock implementation for testing
  static NumberFactClient mock = NumberFactClient(
    fetch: (number) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return 'Test fact about $number';
    },
  );
}

// Feature
class EffectsTesting {
  final NumberFactClient numberFactClient;

  EffectsTesting({required this.numberFactClient});

  Reducer<EffectsTestingState, EffectsTestingAction> get reducer =>
      Reducer<EffectsTestingState, EffectsTestingAction>((state, action) {
        switch (action) {
          case FactButtonTapped():
            state.isLoading = true;
            state.fact = null;
            return Effect.publisher<EffectsTestingAction>((send) async {
              try {
                final fact = await numberFactClient.fetch(state.count);
                send(FactResponse(fact));
              } catch (e) {
                // Handle error in a real app
              }
            }).cancellable(id: CancelID.factRequest);

          case CancelButtonTapped():
            state.isLoading = false;
            return Effect.cancel(CancelID.factRequest);

          case FactResponse(fact: final fact):
            state.fact = fact;
            state.isLoading = false;
            return Effect.none();

          case IncrementButtonTapped():
            state.count++;
            return Effect.none();

          case DecrementButtonTapped():
            state.count--;
            return Effect.none();
        }
      });

  // Action creators
  static const factButtonTapped = FactButtonTapped();
  static const cancelButtonTapped = CancelButtonTapped();
  static const incrementButtonTapped = IncrementButtonTapped();
  static const decrementButtonTapped = DecrementButtonTapped();
}

// MARK: - Feature view

class EffectsTestingView extends StatelessWidget {
  final Store<EffectsTestingState, EffectsTestingAction> store;

  const EffectsTestingView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Effects Testing Demo')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${store.state.count}',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          store.send(EffectsTesting.decrementButtonTapped),
                      child: const Text('-'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () =>
                          store.send(EffectsTesting.incrementButtonTapped),
                      child: const Text('+'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (store.state.isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        store.send(EffectsTesting.cancelButtonTapped),
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: () =>
                        store.send(EffectsTesting.factButtonTapped),
                    child: const Text('Get Fact'),
                  ),
                ],
                if (store.state.fact != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    store.state.fact!,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// MARK: - Tests

// This would typically be in a separate test file
void runTests() {
  // Test the happy path - getting a fact
  testFactRequest();

  // Test cancellation
  testCancellation();
}

void testFactRequest() {
  final testClient = NumberFactClient(
    fetch: (number) async => 'Test fact about $number',
  );

  final store = Store(
    initialState: EffectsTestingState(),
    reducer: EffectsTesting(numberFactClient: testClient).reducer,
  );

  // Initial state check
  assert(store.state.count == 0);
  assert(store.state.fact == null);
  assert(store.state.isLoading == false);

  // Send increment action
  store.send(EffectsTesting.incrementButtonTapped);
  assert(store.state.count == 1);

  // Request a fact
  store.send(EffectsTesting.factButtonTapped);
  assert(store.state.isLoading == true);
  assert(store.state.fact == null);

  // Wait for the effect to complete
  // In a real test, we would use a TestScheduler to control time
  Future.delayed(const Duration(milliseconds: 100), () {
    // Check that the fact was loaded
    assert(store.state.fact == 'Test fact about 1');
    assert(store.state.isLoading == false);

    print('✅ testFactRequest passed');
  });
}

void testCancellation() {
  // Create a client with a delay so we can cancel before it completes
  final testClient = NumberFactClient(
    fetch: (number) async {
      await Future.delayed(const Duration(seconds: 1));
      return 'Test fact about $number';
    },
  );

  final store = Store(
    initialState: EffectsTestingState(),
    reducer: EffectsTesting(numberFactClient: testClient).reducer,
  );

  // Request a fact
  store.send(EffectsTesting.factButtonTapped);
  assert(store.state.isLoading == true);

  // Cancel the request before it completes
  store.send(EffectsTesting.cancelButtonTapped);
  assert(store.state.isLoading == false);

  // Wait to ensure the effect doesn't complete
  Future.delayed(const Duration(seconds: 2), () {
    // The fact should still be null because we cancelled
    assert(store.state.fact == null);
    assert(store.state.isLoading == false);

    print('✅ testCancellation passed');
  });
}

// In a real app, we would use a proper testing framework like 'test' package
// and would have more comprehensive tests

import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class NavigationStateState {
  int count;
  bool isSheetPresented;
  bool isAlertPresented;

  NavigationStateState({
    this.count = 0,
    this.isSheetPresented = false,
    this.isAlertPresented = false,
  });

  @override
  String toString() =>
      'NavigationStateState(count: $count, isSheetPresented: $isSheetPresented, isAlertPresented: $isAlertPresented)';
}

// Actions
sealed class NavigationStateAction {
  const NavigationStateAction();
}

final class Increment extends NavigationStateAction {
  const Increment();
}

final class Decrement extends NavigationStateAction {
  const Decrement();
}

final class PresentSheet extends NavigationStateAction {
  const PresentSheet();
}

final class DismissSheet extends NavigationStateAction {
  const DismissSheet();
}

final class PresentAlert extends NavigationStateAction {
  const PresentAlert();
}

final class DismissAlert extends NavigationStateAction {
  const DismissAlert();
}

// Feature
class NavigationState {
  static final reducer =
      Reducer<NavigationStateState, NavigationStateAction>((state, action) {
    switch (action) {
      case Increment():
        state.count++;
        return Effect.none();
      case Decrement():
        state.count--;
        return Effect.none();
      case PresentSheet():
        state.isSheetPresented = true;
        return Effect.none();
      case DismissSheet():
        state.isSheetPresented = false;
        return Effect.none();
      case PresentAlert():
        state.isAlertPresented = true;
        return Effect.none();
      case DismissAlert():
        state.isAlertPresented = false;
        return Effect.none();
    }
  });

  // Action creators
  static const increment = Increment();
  static const decrement = Decrement();
  static const presentSheet = PresentSheet();
  static const dismissSheet = DismissSheet();
  static const presentAlert = PresentAlert();
  static const dismissAlert = DismissAlert();
}

// MARK: - Feature view

class NavigationStateView extends StatelessWidget {
  final Store<NavigationStateState, NavigationStateAction> store;

  const NavigationStateView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.state.isAlertPresented) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Alert'),
                content: Text('Count is ${store.state.count}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      store.send(NavigationState.dismissAlert);
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          });
        }

        if (store.state.isSheetPresented) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showModalBottomSheet<void>(
              context: context,
              builder: (context) => Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Count is ${store.state.count}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        store.send(NavigationState.dismissSheet);
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Navigation Demo')),
          body: Center(
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
                      onPressed: () => store.send(NavigationState.decrement),
                      child: const Text('-'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => store.send(NavigationState.increment),
                      child: const Text('+'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => store.send(NavigationState.presentSheet),
                  child: const Text('Present Sheet'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => store.send(NavigationState.presentAlert),
                  child: const Text('Present Alert'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

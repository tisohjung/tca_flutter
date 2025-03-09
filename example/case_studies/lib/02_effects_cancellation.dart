import 'package:flutter/material.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Feature domain

// State
class EffectsCancellationState {
  int count;
  String? response;
  bool isLoading;

  EffectsCancellationState({
    this.count = 0,
    this.response,
    this.isLoading = false,
  });

  @override
  String toString() =>
      'EffectsCancellationState(count: $count, response: $response, isLoading: $isLoading)';
}

// Actions
sealed class EffectsCancellationAction {
  const EffectsCancellationAction();
}

// Cancel IDs for effects
enum CancelID {
  factRequest,
}

final class StartLongRequest extends EffectsCancellationAction {
  const StartLongRequest();
}

final class CancelButtonTapped extends EffectsCancellationAction {
  const CancelButtonTapped();
}

final class StepperIncrement extends EffectsCancellationAction {
  const StepperIncrement();
}

final class StepperDecrement extends EffectsCancellationAction {
  const StepperDecrement();
}

final class RequestResponse extends EffectsCancellationAction {
  final String response;
  const RequestResponse(this.response);
}

// Feature
class EffectsCancellation {
  static final reducer =
      Reducer<EffectsCancellationState, EffectsCancellationAction>(
          (state, action) {
    switch (action) {
      case StartLongRequest():
        state.isLoading = true;
        state.response = null;
        print("Starting long request with ID: ${CancelID.factRequest}");
        return Effect.publisher<EffectsCancellationAction>((send) async {
          // Get the task from the TaskManager for this specific ID
          final task = TaskManager.instance.getTask(CancelID.factRequest);
          print("Task created, waiting for 2 seconds...");
          await task.delay(const Duration(seconds: 2));
          print("Delay completed, task cancelled: ${task.isCancelled}");
          if (!task.isCancelled) {
            print("Sending response action");
            send(RequestResponse('Response for count: ${state.count}'));
          } else {
            print("Task was cancelled, not sending response");
          }
        }).cancellable(id: CancelID.factRequest);

      case CancelButtonTapped():
        state.isLoading = false;
        print("Cancel button tapped");
        return Effect.cancel(CancelID.factRequest);

      case StepperIncrement():
        state.count++;
        state.isLoading = false;
        print("Stepper increment");
        return Effect.cancel(CancelID.factRequest);

      case StepperDecrement():
        state.count--;
        state.isLoading = false;
        print("Stepper decrement");
        return Effect.cancel(CancelID.factRequest);

      case RequestResponse(response: final response):
        state.response = response;
        state.isLoading = false;
        return Effect.none();
    }
  });

  // Action creators
  static const startLongRequest = StartLongRequest();
  static const cancelButtonTapped = CancelButtonTapped();
  static const stepperIncrement = StepperIncrement();
  static const stepperDecrement = StepperDecrement();
}

// MARK: - Feature view

class EffectsCancellationView extends StatelessWidget {
  final Store<EffectsCancellationState, EffectsCancellationAction> store;

  const EffectsCancellationView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Effects Cancellation Demo')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Column(
            children: [
              const SizedBox(height: 50),
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
                        store.send(EffectsCancellation.stepperDecrement),
                    child: const Text('-'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () =>
                        store.send(EffectsCancellation.stepperIncrement),
                    child: const Text('+'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (store.state.isLoading) ...[
                FilledButton(
                  onPressed: () =>
                      store.send(EffectsCancellation.cancelButtonTapped),
                  child: const Text('Cancel'),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ] else ...[
                FilledButton(
                  onPressed: store.state.isLoading
                      ? null
                      : () => store.send(EffectsCancellation.startLongRequest),
                  child: const Text('Start Request'),
                ),
                if (store.state.response != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(store.state.response!),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
